terraform {
  backend "s3" {
    bucket  = "elite-bootcampsite2022"
    key     = "elitebucketstate"
    region  = "us-east-1"
    profile = "default"
  }
}

resource "aws_s3_bucket" "remote" {
  bucket = "elite-bootcampsite2022"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = merge(local.common_tags, { Name = "state", Environment = "prod" })
}

# Creates resource to block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "remote" {
  bucket = aws_s3_bucket.remote.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}