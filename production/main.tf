module "aws_static_website" {
  source         = "./modules/staticweb"
  acl            = "public-read"
  force_destroy  = false
  private_zone   = false
  website-domain = "elitelabtools.com"
  bucket_name    = "elitestaticweb"
  tags           = merge(local.common_tags, { Name = "official website", Environment = "prod" })
}