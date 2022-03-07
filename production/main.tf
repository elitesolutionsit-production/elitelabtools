module "aws_static_website" {
  source              = "./modules/staticweb"
  acl                 = "public-read"
  force_destroy       = false
  private_zone        = false
  website-domain      = "elitelabtools.com"
  bucket_name         = "elitestaticweb"
  enable_health_check = true
  health_check_alarm_sns_topics = [
    "arn:aws:sns:us-east-1:375866976303:elitesns"
  ]
  tags = merge(local.common_tags, { Name = "official website", Environment = "prod" })
}
