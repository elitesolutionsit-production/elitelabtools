provider "aws" {
  region  = "us-east-1"
  profile = "customprofile"
}

module "aws_static_website" {
  source                  = "./modules/staticweb"
  website-domain-main     = "elitelabtools.com"
  website-domain-redirect = "www.elitelabtools.com"
  tags                    = merge(local.common_tags, { Name = "official website", Environment = "prod" })
}