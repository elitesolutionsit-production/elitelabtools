module "aws_static_website" {
  source = "./modules/staticweb"

  threshold                  = 100
  force_destroy              = false
  private_zone               = false
  enable_health_check        = true
  limit_amount               = 20
  limit_unit                 = "USD"
  budget                     = "COST"
  time_unit                  = "MONTHLY"
  comparison_operator        = "GREATER_THAN"
  threshold_type             = "PERCENTAGE"
  notification_type          = "FORECASTED"
  acl                        = "public-read"
  time_period_end            = "2087-06-15_00:00"
  time_period_start          = "2022-03-09_00:00"
  bucket_name                = "elitestaticweb"
  website-domain             = "elitelabtools.com"
  subscriber_email_addresses = ["elitecloudbootcamp@outlook.com", "elitesolutionsit@outlook.com"]
  name                       = "budget-cloudfront-monthly"

  health_check_alarm_sns_topics = [
    "arn:aws:sns:us-east-1:375866976303:elitesns"
  ]

  tags = merge(local.common_tags, { Name = "official website", Environment = "prod" })
}
