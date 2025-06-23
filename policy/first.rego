package main

deny[msg] {
  some i
  input.resource_changes[i].type == "aws_instance"
  public_ip := input.resource_changes[i].change.after.associate_public_ip_address
  public_ip == true
  msg = sprintf("EC2 instance '%s' is configured with public IP, which is not allowed.", [input.resource_changes[i].address])
}