# Replace all REPLACE_ME values with resources and IDs from your development accounts.
aws_region        = "us-east-1"
account_a_profile = "account-a-dev"
account_b_profile = "account-b-DEV"
account_a_id      = "000000000000"
account_b_id      = "111111111111"

ami_id = "ami-REPLACE_WITH_DEV_AMI_ID"

instances = {
  critical-api = {
    instance_type    = "t3.micro"
    root_volume_type = "gp3"
    root_volume_size = 12
    key_name         = "dev-critical-api"
  }
  batch-worker = {
    instance_type    = "t3.small"
    root_volume_type = "gp2"
    root_volume_size = 16
    key_name         = "dev-batch-worker"
  }
  web-frontend = {
    instance_type    = "t3.medium"
    root_volume_type = "io1"
    root_volume_size = 20
    root_iops        = 100
    key_name         = "dev-web-frontend"
  }
  reporting = {
    instance_type    = "t3.large"
    root_volume_type = "io2"
    root_volume_size = 24
    root_iops        = 100
    key_name         = "dev-reporting"
  }
  integration = {
    instance_type    = "t3.xlarge"
    root_volume_type = "standard"
    root_volume_size = 30
    key_name         = "dev-integration"
  }
}

protected_instance_name = "critical-api"

# Provide the base64-encoded PGP public key used for initial console passwords.
console_user_pgp_key = "REPLACE_WITH_BASE64_ENCODED_PGP_PUBLIC_KEY"

ecr_repository_name         = "dev-application"
ecs_cluster_name            = "dev-cluster"
ecs_service_name            = "dev-application"
ecs_task_execution_role_arn = "arn:aws:iam::000000000000:role/dev-ecsTaskExecutionRole"
ecs_task_role_arn           = "arn:aws:iam::000000000000:role/dev-ecsTaskRole"
build_artifacts_bucket_name = "REPLACE_WITH_DEV_ARTIFACTS_BUCKET"
role_c_bucket_name          = "REPLACE_WITH_DEV_ROLEC_BUCKET"
