# main.tf
module "cloudtrail" {
  source = "./modules/cloudtrail"
  name_prefix       = "sec"
  s3_bucket_name    = "my-secure-trail-bucket"
  log_retention_days = 365
}

module "console_login_alert" {
  source         = "./modules/console_login_alert"
  prefix         = "sec"
  log_group_name = module.cloudtrail.cloud_watch_log_group_name
  email_address  = "barathmohan.sivas@hcltech.com"
}
