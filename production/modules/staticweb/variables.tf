variable "website-domain" {
  type        = string
  description = "The domain where to host the site. This must be the naked domain, e.g. `example.com`"
}

variable "acl" {
  type        = string
  description = "IF bucket is set to Public, PublicRead, Private etc."
}

variable "index_document" {
  type        = string
  description = "Source code for Official website in html"
  default     = "index.html"
}

variable "force_destroy" {
  type        = bool
  default     = true
  description = "Whether to force destroy content of the bucket"
}

variable "private_zone" {
  type        = bool
  default     = false
  description = "Whether domain should be private or public. Default is False"
}


variable "error_document" {
  type        = string
  description = "Default error message page for website"
}


variable "bucket_name" {
  type        = string
  description = "Main bucket name for website"
}
variable "tags" {
  description = "Tags added to resources"
  default     = {}
  type        = map(string)
}