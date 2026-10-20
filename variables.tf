variable "aws_region" {
  description = "AWS region used by both accounts."
  type        = string
  default     = "us-east-1"
}

variable "account_a_profile" {
  description = "AWS CLI profile authenticated to Account A."
  type        = string
  default     = "account-a"
}

variable "account_b_profile" {
  description = "AWS CLI profile authenticated to Account B."
  type        = string
  default     = "account-b"
}

variable "account_a_id" {
  description = "AWS account ID for Account A."
  type        = string
  default     = "000000000000"
}

variable "account_b_id" {
  description = "AWS account ID for Account B."
  type        = string
  default     = "111111111111"
}

variable "ami_id" {
  description = "Region-specific AMI ID used by all five EC2 instances."
  type        = string
}

variable "instances" {
  description = "Exactly five EC2 instances; each sample uses distinct instance, root-volume, size, and key-pair values."
  type = map(object({
    instance_type    = string
    root_volume_type = string
    root_volume_size = number
    root_iops        = optional(number)
    key_name         = string
  }))

  default = {
    critical-api = {
      instance_type    = "t3.micro"
      root_volume_type = "gp3"
      root_volume_size = 12
      key_name         = "critical-api-key"
    }
    batch-worker = {
      instance_type    = "t3.small"
      root_volume_type = "gp2"
      root_volume_size = 16
      key_name         = "batch-worker-key"
    }
    web-frontend = {
      instance_type    = "t3.medium"
      root_volume_type = "io1"
      root_volume_size = 20
      root_iops        = 100
      key_name         = "web-frontend-key"
    }
    reporting = {
      instance_type    = "t3.large"
      root_volume_type = "io2"
      root_volume_size = 24
      root_iops        = 100
      key_name         = "reporting-key"
    }
    integration = {
      instance_type    = "t3.xlarge"
      root_volume_type = "standard"
      root_volume_size = 30
      key_name         = "integration-key"
    }
  }

  validation {
    condition     = length(var.instances) == 5
    error_message = "Provide exactly five instances."
  }

  validation {
    condition = (
      length(toset([for instance in values(var.instances) : instance.instance_type])) == 5 &&
      length(toset([for instance in values(var.instances) : instance.root_volume_type])) == 5 &&
      length(toset([for instance in values(var.instances) : instance.root_volume_size])) == 5 &&
      length(toset([for instance in values(var.instances) : instance.key_name])) == 5
    )
    error_message = "All five instances must have distinct instance types, root volume types, root volume sizes, and key pairs."
  }

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      contains(["io1", "io2"], instance.root_volume_type) == (instance.root_iops != null)
    ])
    error_message = "Set root_iops only for io1/io2 volumes, and provide it for every io1/io2 volume."
  }
}

variable "protected_instance_name" {
  description = "Instance-map key protected from Terraform destruction."
  type        = string
  default     = "critical-api"

  validation {
    condition     = contains(keys(var.instances), var.protected_instance_name)
    error_message = "protected_instance_name must match a key in instances."
  }
}

variable "console_user_pgp_key" {
  description = "Base64-encoded PGP public key used to encrypt generated console passwords."
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR repository the CI user may push images to."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster containing the deployable service."
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service the CI user may update."
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "Exact ECS task execution-role ARN that CI may pass to ECS."
  type        = string
}

variable "ecs_task_role_arn" {
  description = "Exact ECS task-role ARN that CI may pass to ECS."
  type        = string
}

variable "build_artifacts_bucket_name" {
  description = "S3 bucket from which CI may read build artifacts."
  type        = string
}

variable "role_c_bucket_name" {
  description = "Single S3 bucket to which roleC receives full access."
  type        = string
}
