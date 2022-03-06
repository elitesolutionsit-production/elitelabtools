output "website_logs_s3_bucket" {
  description = "The s3 bucket of the website logs"
  value       = aws_s3_bucket.website_logs.bucket
}

output "website_redirect_s3_bucket" {
  description = "The s3 bucket of the website redirect bucket"
  value       = aws_s3_bucket.website_redirect.bucket
}