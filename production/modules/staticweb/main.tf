## Route 53
# Provides details about the zone
data "aws_route53_zone" "main" {
  name         = var.website-domain
  private_zone = var.private_zone
}


# S3 bucket for website.
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "public-read"

  logging {
    target_bucket = aws_s3_bucket.website_logs.bucket
    target_prefix = "${var.bucket_name}/"
  }
  website {
    index_document = "index.html"
    error_document = "404.html"

  }

  tags = merge(var.tags, { Name = "elite-mainbucket" })
}

resource "aws_s3_bucket" "bucket_redirect" {
  bucket = "www.${var.bucket_name}-redirect"
  acl    = "public-read"

  website {
    redirect_all_requests_to = "https://${var.website-domain}"

  }

  tags = merge(var.tags, { Name = "elite-mainbucket" })
}

# Creates bucket to store logs
resource "aws_s3_bucket" "website_logs" {
  bucket = "${var.bucket_name}-logs"
  acl    = "log-delivery-write"

  # Comment the following line if you are uncomfortable with Terraform destroying the bucket even if this one is not empty
  force_destroy = true

  tags = merge(var.tags, { Name = "elite-bucketLogs" })
}


# Creates policy to allow public access to the S3 bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForWebsiteEndpointsPublicContent",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_policy" "bucket_policy_redirect" {
  bucket = aws_s3_bucket.bucket_redirect.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForWebsiteEndpointsPublicContent",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket_redirect.arn}/*"
      ]
    }
  ]
}
POLICY
}

## ACM (AWS Certificate Manager)
# Creates the wildcard certificate *.<yourdomain.com>
resource "aws_acm_certificate" "cert" {
  provider                  = aws.us-east-1
  domain_name               = var.website-domain
  subject_alternative_names = ["*.${var.website-domain}"]
  validation_method         = "DNS"

  tags = merge(var.tags, { Name = "cert" })
  lifecycle {
    ignore_changes = [tags["Changed"]]
  }
}

# Validates the ACM wildcard by creating a Route53 record (as `validation_method` is set to `DNS` in the aws_acm_certificate resource)
resource "aws_route53_record" "wildcard_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "cert_validate" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.wildcard_validation : record.fqdn]
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "distribution" {
  origin {
    origin_id   = "origin-bucket-${var.website-domain}"
    domain_name = aws_s3_bucket.bucket.website_endpoint

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  logging_config {
    bucket = aws_s3_bucket.website_logs.bucket_domain_name
    prefix = "${var.website-domain}/"
  }


  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  aliases = [var.website-domain]

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 200
    response_page_path    = "/404.html"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-bucket-${var.website-domain}"

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
  price_class = "PriceClass_200"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(var.tags, { Name = "elite-prod-cf" })

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validate.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Creates the DNS record to point on the main CloudFront distribution ID
resource "aws_route53_record" "distribution_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.website-domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_health_check" "health_check" {
  depends_on        = [aws_route53_record.wildcard_validation]
  fqdn              = var.website-domain
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"

  tags = merge(var.tags, { Name = "elite-R53Health" })
}

resource "aws_cloudwatch_metric_alarm" "health_check_alarm" {
  provider            = aws.us-east-1
  alarm_name          = "${var.website-domain}-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1.0"
  ok_actions          = var.health_check_alarm_sns_topics
  alarm_actions       = var.health_check_alarm_sns_topics
  alarm_description   = "This metric monitors the health of the endpoint"
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.health_check.id
  }
}

resource "aws_sns_topic" "user_updates" {
  name            = var.aws_sns_topic
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}