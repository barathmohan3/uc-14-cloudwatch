# modules/console_login_alert/variables.tf
variable "prefix"           { type = string }
variable "log_group_name"   { type = string }
variable "metric_namespace" {        
      type = string
      default = "Security/CloudTrail" 
}
variable "alarm_period_sec" { 
  type = number
  default = 300 
}
variable "email_address"    { type = string }
