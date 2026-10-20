variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "account_a_profile" {
  type    = string
  default = "account-a"
}

variable "account_a_id" {
  type    = string
  default = "000000000000"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
}

variable "state_lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking."
  type        = string
  default     = "terraform-state-locks"
}
