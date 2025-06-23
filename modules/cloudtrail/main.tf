# modules/cloudtrail/main.tf

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "trail_bucket" {
  bucket = "${var.name_prefix}-cloudtrail-${random_id.bucket_suffix.hex}"
  acl    = "private"
  versioning { enabled = true }
  lifecycle_rule { 
     enabled = true
     expiration { days = 365 } 
       }
}

resource "aws_iam_role" "cloudtrail" {
  name = "${var.name_prefix}-cloudtrail-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals { 
        type = "Service"
        identifiers = ["cloudtrail.amazonaws.com"] 
              }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role_policy" "cloudtrail" {
  role = aws_iam_role.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail.json
}
data "aws_iam_policy_document" "cloudtrail" {
  statement {
    actions = ["s3:PutObject","s3:GetBucketAcl","s3:PutObjectAcl"]
    resources = ["${aws_s3_bucket.trail_bucket.arn}/*", aws_s3_bucket.trail_bucket.arn]
  }
  statement {
    actions = ["logs:CreateLogStream","logs:PutLogEvents","logs:CreateLogGroup"]
    resources = ["*"]
  }
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.ct_logs.arn
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}


resource "aws_cloudwatch_log_group" "ct_logs" {
  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.log_retention_days
}
