# modules/console_login_alert/main.tf
resource "aws_sns_topic" "this" {
  name = "${var.prefix}-console-login-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email_address
}

resource "aws_cloudwatch_log_metric_filter" "console_login_success" {
  name           = "${var.prefix}-console-login"
  log_group_name = var.log_group_name
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.responseElements.ConsoleLogin = \"Success\") }"
  metric_transformation {
    name      = "${var.prefix}_ConsoleLoginSuccess_Count"
    namespace = var.metric_namespace
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_login_alarm" {
  alarm_name          = "${var.prefix}-console-login-alarm"
  alarm_description   = "Triggered on console login"
  metric_name         = aws_cloudwatch_log_metric_filter.console_login_success.metric_transformation[0].name
  namespace           = var.metric_namespace
  statistic           = "Sum"
  period              = var.alarm_period_sec
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.this.arn]
}
