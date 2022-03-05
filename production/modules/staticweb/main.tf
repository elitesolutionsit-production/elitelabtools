resource "aws_cloudfront_distribution" "website_cdn_root" {
  origin {
    domain_name = aws_s3_bucket.bucket.website_endpoint
    origin_id   = "origin-bucket-${aws_s3_bucket.bucket.id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["${var.website-domain-main}"]

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/404.html"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "origin-bucket-${aws_s3_bucket.bucket.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 31536000
    default_ttl            = 31536000
    max_ttl                = 31536000
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  tags = merge(var.tags, { Name = "offical cloudfront", Environment = "prod", Changed = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp()) })
}

resource "aws_acm_certificate" "ssl_certificate" {
  provider                  = aws.acm_provider
  domain_name               = var.website-domain-main
  subject_alternative_names = ["*.${var.website-domain-main}"]
  validation_method         = "DNS"

  tags = merge(var.tags, { Name = "ssl certificate", Environment = "prod" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.acm_provider
  for_each = {
    for dvo in aws_acm_certificate.ssl_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Uncomment the validation_record_fqdns line if you do DNS validation instead of Email.
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.acm_provider
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

data "aws_route53_zone" "main" {
  name         = var.website-domain-main
  private_zone = false
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.website-domain-main
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_cdn_root.domain_name
    zone_id                = aws_cloudfront_distribution.website_cdn_root.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.website-domain-main
  acl    = "public-read"
  policy = templatefile("templates/s3-policy.json", { bucket = "${var.website-domain-main}" })

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["https://${var.website-domain-main}"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = merge(var.tags, { Name = "official website", Environment = "prod" })
}
