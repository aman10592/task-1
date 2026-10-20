output "instance_ids_by_name" {
  description = "EC2 instance IDs indexed by configured instance name."
  value = merge(
    { for name, instance in aws_instance.instances : name => instance.id },
    { for name, instance in aws_instance.protected : name => instance.id }
  )
}

output "private_ips_by_name" {
  description = "EC2 private IP addresses indexed by configured instance name."
  value = merge(
    { for name, instance in aws_instance.instances : name => instance.private_ip },
    { for name, instance in aws_instance.protected : name => instance.private_ip }
  )
}

output "role_arns" {
  description = "ARNs for the three task roles."
  value = {
    roleA = aws_iam_role.role_a.arn
    roleB = aws_iam_role.role_b.arn
    roleC = aws_iam_role.role_c.arn
  }
}
