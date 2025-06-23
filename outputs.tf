# outputs.tf
output "cloudtrail_log_group_name" {
  value = module.cloudtrail.cloud_watch_log_group_name
}
