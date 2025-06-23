test "ec2_instance_exists" {
  command = plan

  assertions {
    resource_changes {
      type   = "aws_instance"
      action = "create"
    }
  }
}
