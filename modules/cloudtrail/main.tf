data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "trail_bucket" {
  bucket = "${var.name_prefix}-cloudtrail-${random_id.bucket_suffix.hex}"
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "trail_bucket_versioning" {
  bucket = aws_s3_bucket.trail_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "trail_bucket_lifecycle" {
  bucket = aws_s3_bucket.trail_bucket.id

  rule {
    id     = "expire-objects"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}

resource "aws_cloudwatch_log_group" "ct_logs" {
  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.log_retention_days
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudtrail" {
  name               = "${var.name_prefix}-cloudtrail-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.trail_bucket.arn}/*",
      aws_s3_bucket.trail_bucket.arn
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [

       "${aws_cloudwatch_log_group.ct_logs.arn}:*",
       "${.cloudwatch_log_group_arn}"
    ]
  }
}

resource "aws_iam_role_policy" "cloudtrail" {
  role   = aws_iam_role.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail.json
}

resource "time_sleep" "wait_for_iam" {
  depends_on      = [aws_iam_role_policy.cloudtrail]
  create_duration = "60s"
}

resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.trail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.trail_bucket.arn
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.trail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.ct_logs.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_cloudwatch_log_group.ct_logs,
    aws_iam_role_policy.cloudtrail,
    time_sleep.wait_for_iam,
    aws_s3_bucket_policy.trail_bucket_policy
  ]
}
