# Replace all REPLACE_ME values with resources and IDs from your production accounts.
aws_region        = "us-east-1"
account_a_profile = "account-a-prod"
account_b_profile = "account-b-prod"
account_a_id      = "000000000000"
account_b_id      = "111111111111"

ami_id = "ami-REPLACE_WITH_PROD_AMI_ID"

instances = {
  critical-api = {
    instance_type    = "m6i.large"
    root_volume_type = "gp3"
    root_volume_size = 40
    key_name         = "prod-critical-api"
  }
  batch-worker = {
    instance_type    = "m6i.xlarge"
    root_volume_type = "gp2"
    root_volume_size = 50
    key_name         = "prod-batch-worker"
  }
  web-frontend = {
    instance_type    = "c6i.large"
    root_volume_type = "io1"
    root_volume_size = 60
    root_iops        = 100
    key_name         = "prod-web-frontend"
  }
  reporting = {
    instance_type    = "r6i.large"
    root_volume_type = "io2"
    root_volume_size = 70
    root_iops        = 100
    key_name         = "prod-reporting"
  }
  integration = {
    instance_type    = "m6i.2xlarge"
    root_volume_type = "standard"
    root_volume_size = 80
    key_name         = "prod-integration"
  }
}

protected_instance_name = "critical-api"

# Provide the base64-encoded PGP public key used for initial console passwords.
console_user_pgp_key = "REPLACE_WITH_BASE64_ENCODED_PGP_PUBLIC_KEY"

ecr_repository_name         = "prod-application"
ecs_cluster_name            = "prod-cluster"
ecs_service_name            = "prod-application"
ecs_task_execution_role_arn = "arn:aws:iam::000000000000:role/prod-ecsTaskExecutionRole"
ecs_task_role_arn           = "arn:aws:iam::000000000000:role/prod-ecsTaskRole"
build_artifacts_bucket_name = "REPLACE_WITH_PROD_ARTIFACTS_BUCKET"
role_c_bucket_name          = "REPLACE_WITH_PROD_ROLEC_BUCKET"
