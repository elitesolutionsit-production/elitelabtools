module "aws_static_website" {
  source         = "./modules/staticweb"
  acl            = "public-read"
  index_document = "index.html"
  force_destroy  = true
  private_zone   = false
  error_document = "404.html"
  website-domain = "elitelabtools.com"
  bucket_name    = "elitestaticweb"
  tags           = merge(local.common_tags, { Name = "official website", Environment = "prod" })
}