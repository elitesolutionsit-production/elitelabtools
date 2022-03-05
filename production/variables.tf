variable "domain_name" {
  type        = string
  description = "The domain name for the website."
  default     = "elitelabtools.com"
}
variable "bucket_name" {
  type        = string
  description = "The name of the bucket without the www. prefix. Normally domain_name."
  default     = "elite-official-site"
}