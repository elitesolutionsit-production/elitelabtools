## Route 53
# Provides details about the zone
data "aws_route53_zone" "main" {
  name         = var.website-domain-main
  private_zone = false
}

## ACM (AWS Certificate Manager)
# Creates the wildcard certificate *.<yourdomain.com>
resource "aws_acm_certificate" "wildcard_website" {
  provider                  = aws.us-east-1
  domain_name               = var.website-domain-main
  subject_alternative_names = ["*.${var.website-domain-main}"]
  validation_method         = "DNS"

  tags = merge(var.tags, {
    
    Changed   = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  })

  lifecycle {
    ignore_changes = [tags["Changed"]]
  }

}

# Validates the ACM wildcard by creating a Route53 record (as `validation_method` is set to `DNS` in the aws_acm_certificate resource)
resource "aws_route53_record" "wildcard_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard_website.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name            = each.value.name
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
  records         = [each.value.record]
  allow_overwrite = true
  ttl             = "60"
}

# Triggers the ACM wildcard certificate validation event
resource "aws_acm_certificate_validation" "wildcard_cert" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.wildcard_website.arn
  validation_record_fqdns = [for k, v in aws_route53_record.wildcard_validation : v.fqdn]
}


# Get the ARN of the issued certificate
data "aws_acm_certificate" "wildcard_website" {
  provider = aws.us-east-1

  depends_on = [
    aws_acm_certificate.wildcard_website,
    aws_route53_record.wildcard_validation,
    aws_acm_certificate_validation.wildcard_cert,
  ]

  domain      = var.website-domain-main
  statuses    = ["ISSUED"]
  most_recent = true
}

## S3
# Creates bucket to store logs
resource "aws_s3_bucket" "website_logs" {
  bucket = "${var.website-domain-main}-logs"
  acl    = "log-delivery-write"

  # Comment the following line if you are uncomfortable with Terraform destroying the bucket even if this one is not empty
  force_destroy = true


  tags = merge(var.tags, {
    
    Changed   = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  })

  lifecycle {
    ignore_changes = [tags["Changed"]]
  }
}

# Creates bucket for the website handling the redirection (if required), e.g. from https://www.example.com to https://example.com
resource "aws_s3_bucket" "website_redirect" {
  bucket        = "${var.website-domain-main}-redirect"
  acl           = "public-read"
  force_destroy = true

  logging {
    target_bucket = aws_s3_bucket.website_logs.bucket
    target_prefix = "${var.website-domain-main}-redirect/"
  }

  website {
    redirect_all_requests_to = "https://www.${var.website-domain-main}"
  }

  tags = merge(var.tags, {
    
    Changed   = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  })

  lifecycle {
    ignore_changes = [tags["Changed"]]
  }
}

# Creates the CloudFront distribution to serve the redirection website (if redirection is required)
resource "aws_cloudfront_distribution" "website_cdn_redirect" {
  enabled     = true
  price_class = "PriceClass_All"
  # Select the correct PriceClass depending on who the CDN is supposed to serve (https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html)
  aliases = [var.website-domain-redirect]

  origin {
    origin_id   = "origin-bucket-${aws_s3_bucket.website_redirect.id}"
    domain_name = aws_s3_bucket.website_redirect.website_endpoint

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  logging_config {
    bucket = aws_s3_bucket.website_logs.bucket_domain_name
    prefix = "${var.website-domain-redirect}/"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-bucket-${aws_s3_bucket.website_redirect.id}"
    min_ttl          = 31536000
    default_ttl      = 31536000
    max_ttl          = 31536000

    viewer_protocol_policy = "redirect-to-https" # Redirects any HTTP request to HTTPS
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.wildcard_website.arn
    ssl_support_method  = "sni-only"
  }

  tags = merge(var.tags, {
    
    Changed   = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  })

  lifecycle {
    ignore_changes = [
      tags["Changed"],
      viewer_certificate,
    ]
  }
}

# Creates the DNS record to point on the CloudFront distribution ID that handles the redirection website
resource "aws_route53_record" "website_cdn_redirect_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.website-domain-redirect
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_cdn_redirect.domain_name
    zone_id                = aws_cloudfront_distribution.website_cdn_redirect.hosted_zone_id
    evaluate_target_health = false
  }
}
