# modules/cloudtrail/variables.tf
variable "name_prefix"   { type = string }
variable "s3_bucket_name" { type = string }
variable "log_retention_days" { type = number; default = 90 }
