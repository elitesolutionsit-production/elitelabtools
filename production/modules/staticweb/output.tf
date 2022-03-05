output "website_cdn_root_id" {
  description = "Main CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.website_cdn_root.id
}

output "website_root_s3_bucket" {
  description = "The website root bucket where resources are uploaded"
  value       = aws_s3_bucket.bucket.bucket
}