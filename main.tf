locals {
  unprotected_instances = {
    for name, instance in var.instances : name => instance
    if name != var.protected_instance_name
  }
  protected_instances = {
    for name, instance in var.instances : name => instance
    if name == var.protected_instance_name
  }

  group1_users = toset(["engine", "ci"])
  group2_users = toset(["console-ops-1", "console-ops-2"])
  all_users    = setunion(local.group1_users, local.group2_users)

  role_a_arn = "arn:${data.aws_partition.account_a.partition}:iam::${var.account_a_id}:role/roleA"
  role_b_arn = "arn:${data.aws_partition.account_a.partition}:iam::${var.account_a_id}:role/roleB"
  role_c_arn = "arn:${data.aws_partition.account_a.partition}:iam::${var.account_b_id}:role/roleC"

  ci_policy = templatefile("${path.module}/policies/ci-deploy-policy.json.tftpl", {
    account_id                  = var.account_a_id
    region                      = var.aws_region
    ecr_repository_name         = var.ecr_repository_name
    ecs_cluster_name            = var.ecs_cluster_name
    ecs_service_name            = var.ecs_service_name
    ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
    ecs_task_role_arn           = var.ecs_task_role_arn
    build_artifacts_bucket_name = var.build_artifacts_bucket_name
  })
}

resource "aws_instance" "instances" {
  provider = aws.account_a
  for_each = local.unprotected_instances

  ami           = var.ami_id
  instance_type = each.value.instance_type
  key_name      = each.value.key_name

  root_block_device {
    volume_type = each.value.root_volume_type
    volume_size = each.value.root_volume_size
    iops        = each.value.root_iops
  }

  tags = {
    Name        = each.key
    Environment = "dev"
    Owner       = "platform-team"
  }
}

resource "aws_instance" "protected" {
  provider = aws.account_a
  for_each = local.protected_instances

  ami           = var.ami_id
  instance_type = each.value.instance_type
  key_name      = each.value.key_name

  root_block_device {
    volume_type = each.value.root_volume_type
    volume_size = each.value.root_volume_size
    iops        = each.value.root_iops
  }

  tags = {
    Name        = each.key
    Environment = "dev"
    Owner       = "platform-team"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_group" "group1" {
  provider = aws.account_a
  name     = "group1"
}

resource "aws_iam_group" "group2" {
  provider = aws.account_a
  name     = "group2"
}

resource "aws_iam_user" "users" {
  provider = aws.account_a
  for_each = local.all_users
  name     = each.value
}

resource "aws_iam_user_group_membership" "group1" {
  provider = aws.account_a
  for_each = local.group1_users

  user   = aws_iam_user.users[each.value].name
  groups = [aws_iam_group.group1.name]
}

resource "aws_iam_user_group_membership" "group2" {
  provider = aws.account_a
  for_each = local.group2_users

  user   = aws_iam_user.users[each.value].name
  groups = [aws_iam_group.group2.name]
}

resource "aws_iam_user_login_profile" "group2" {
  provider = aws.account_a
  for_each = local.group2_users

  user                    = aws_iam_user.users[each.value].name
  pgp_key                 = var.console_user_pgp_key
  password_reset_required = true
}

output "console_user_encrypted_passwords" {
  description = "PGP-encrypted initial console passwords for group2 users."
  value       = { for name, profile in aws_iam_user_login_profile.group2 : name => profile.encrypted_password }
  sensitive   = true
}

resource "aws_iam_role" "role_a" {
  provider = aws.account_a
  name     = "roleA"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = "arn:${data.aws_partition.account_a.partition}:iam::${var.account_a_id}:root" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "role_a_admin" {
  provider   = aws.account_a
  role       = aws_iam_role.role_a.name
  policy_arn = "arn:${data.aws_partition.account_a.partition}:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "role_a_deny_iam" {
  provider = aws.account_a
  name     = "deny-iam-actions"
  role     = aws_iam_role.role_a.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = "iam:*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "role_b" {
  provider = aws.account_a
  name     = "roleB"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = "arn:${data.aws_partition.account_a.partition}:iam::${var.account_a_id}:root" }
    }]
  })
}

resource "aws_iam_role_policy" "role_b_assume_role_c" {
  provider = aws.account_a
  name     = "assume-roleC-only"
  role     = aws_iam_role.role_b.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = local.role_c_arn
    }]
  })
}

resource "aws_iam_role" "role_c" {
  provider = aws.account_b
  name     = "roleC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = local.role_b_arn }
    }]
  })
}

resource "aws_iam_role_policy" "role_c_s3" {
  provider = aws.account_b
  name     = "roleC-s3-access"
  role     = aws_iam_role.role_c.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "arn:${data.aws_partition.account_a.partition}:s3:::${var.role_c_bucket_name}"
      },
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "arn:${data.aws_partition.account_a.partition}:s3:::${var.role_c_bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_user_policy" "engine_assume_role_b" {
  provider = aws.account_a
  name     = "assume-roleB"
  user     = aws_iam_user.users["engine"].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.role_b.arn
    }]
  })
}

resource "aws_iam_group_policy" "group2_assume_role_a" {
  provider = aws.account_a
  name     = "assume-roleA"
  group    = aws_iam_group.group2.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.role_a.arn
    }]
  })
}

resource "aws_iam_policy" "ci_deploy" {
  provider    = aws.account_a
  name        = "ci-deploy-least-privilege"
  description = "Push to one ECR repository, deploy to one ECS service, and read one artifact bucket."
  policy      = local.ci_policy
}

resource "aws_iam_user_policy_attachment" "ci_deploy" {
  provider   = aws.account_a
  user       = aws_iam_user.users["ci"].name
  policy_arn = aws_iam_policy.ci_deploy.arn
}
