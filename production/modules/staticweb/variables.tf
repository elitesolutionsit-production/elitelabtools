variable "website-domain" {
  type        = string
  description = "The domain where to host the site. This must be the naked domain, e.g. `example.com`"
}

variable "acl" {
  type        = string
  description = "IF bucket is set to Public, PublicRead, Private etc."
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

variable "bucket_name" {
  type        = string
  description = "Main bucket name for website"
}
variable "tags" {
  description = "Tags added to resources"
  default     = {}
  type        = map(string)
}

variable "enable_health_check" {
  type        = string
  default     = false
  description = "If true, it creates a Route53 health check that monitors the www endpoint and an alarm that triggers whenever it's not reachable. Please note this comes at an extra monthly cost on your AWS account"
}

variable "aws_sns_topic" {
  type        = string
  default     = "elitesns"
  description = "SNS Topic to generate for website"
}

variable "health_check_alarm_sns_topics" {
  type        = list(string)
  default     = []
  description = "A list of SNS topics to notify whenever the health check fails or comes back to normal"
}

////Budget variables

variable "name" {
  type = string
}

variable "budget" {
  type = string
}

variable "limit_amount" {
  type = number
}

variable "limit_unit" {
  type = string
}

variable "time_period_end" {
  type = string
}

variable "time_period_start" {
  type = string
}

variable "time_unit" {
  type = string
}

variable "comparison_operator" {
  type = string
}

variable "threshold" {
  type = number
}

variable "threshold_type" {
  type = string
}

variable "notification_type" {
  type = string
}

variable "subscriber_email_addresses" {
  type    = list(string)
  default = []
}