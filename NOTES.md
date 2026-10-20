# Notes

## Task 1 & 2: Multi-Instance EC2 Provisioning & Remote State & Locking and scope

The root configuration uses the Account A and Account B AWS CLI profiles and checks each profile against the configured account ID. Update the sample region, profiles, AMI, key-pair names, role ARNs, bucket names, and ECS/ECR names for your environment in the environment `.tfvars` file. The sample EC2 map has five unique instance types, root volume types, root volume sizes, and key pairs; both `io1` and `io2` include IOPS. The selected AMI, key pairs, ECS roles, and named buckets must already exist.

The S3 backend bucket and DynamoDB lock table must exist before initializing the root configuration. If they are not already provisioned, first apply the separate `bootstrap/` configuration using Account A credentials and its local state. The bootstrap configuration creates a versioned, encrypted, public-access-blocked S3 bucket and the DynamoDB lock table. Keep the bootstrap state safe; the backend cannot create itself from the backend it depends on.

```powershell
# Initialize the S3 backend for development (replace the bucket name).
terraform init -reconfigure `
  -backend-config="bucket=YOUR_UNIQUE_STATE_BUCKET" `
  -backend-config="key=office-codes/dev.tfstate" `
  -backend-config="region=us-east-1" `
  -backend-config="dynamodb_table=terraform-state-locks" `
  -backend-config="encrypt=true"

# The backend uses the active AWS credentials/AWS profile and needs access
# to the state bucket and lock table. Select the dev variable file:
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"


Terraform does not automatically load files named `dev.tfvars` or `prod.tfvars`; always pass the matching `-var-file`. If changing from a local backend with existing state, use `terraform init -migrate-state` instead of `-reconfigure` to copy that state to S3. Use `-reconfigure` only when you intend to configure the backend without migrating the existing local state.

The shared S3 backend stores state centrally, and the DynamoDB lock table prevents simultaneous Terraform operations from writing the same state. The AWS identity used by Terraform needs access to the state bucket and lock table. Without shared state and locking, operators can plan from stale state and make conflicting changes. Do not bypass the lock.

As an alternative to DynamoDB, Terraform 1.10 and later can use an S3 lock file: remove `dynamodb_table` from the backend configuration and set `use_lockfile = true` in `backend.tf`. This task uses DynamoDB locking as requested.

## EC2 lifecycle protection

`critical-api` is the protected instance. It is the sample's critical service endpoint, so an accidental destroy or replacement should stop for an explicit operator decision. Terraform lifecycle meta-arguments cannot be conditional within one `for_each` resource; the configuration therefore splits only that selected map entry into a protected resource and provisions all remaining entries through one shared resource. All five instances still come from the same `instances` input variable.

## TASK 3:  Multi-Account IAM & Cross-Account Access

- `group1` contains `engine` and `ci` and has no console login profiles. Only `engine` receives permission to assume `roleB`; `ci` receives only the task-specific deployment policy. Do not generate long-lived access keys in Terraform; provision short-lived programmatic credentials through the organization's approved identity system.
- `group2` contains the chosen users `console-ops-1` and `console-ops-2`, has PGP-encrypted initial console passwords, and can assume `roleA`. The two roles define the permissions boundary for these sample access paths.
- `roleA` has AdministratorAccess plus an explicit deny for every IAM action. Explicit deny takes precedence over the managed allow.
- `roleB` has only `sts:AssumeRole` permission for the exact `roleC` ARN. Its trust policy permits Account A principals to assume it; their own identity policies must also allow the operation.
- `roleC` trusts only roleB's exact ARN in Account A and grants S3 actions only on the configured bucket and its objects in Account B.


### 1. IAM users and production access keys

No. In production I would prefer IAM Identity Center or workload federation (such as OIDC for CI) and short-lived role credentials. Long-lived IAM-user access keys are harder to rotate and revoke reliably and can be leaked from developer machines, build logs, or secret stores. This exercise defines IAM users and groups as requested, but deliberately does not create access keys.

### 2. Trusting Account A root versus roleB

| Trusted principal | Effect |
|---|---|
| Account A root ARN | Delegates trust to the account. Principals in Account A may be able to assume the role if their own identity policies allow it. |
| roleB's specific ARN | Narrows trust to roleB. Other Account A users and roles cannot directly assume `roleC`; the policy uses roleB's ARN to enforce that boundary. |

## TASK 4: CI policy and least privilege

`policies/ci-deploy-policy.json.tftpl` is the custom JSON policy attached only to `ci`. It allows ECR authentication and image-push operations for one repository, registering/describing task definitions, updating/describing one ECS service, passing only the two named ECS task roles to ECS tasks, and reading/listing one build-artifact bucket. ECR's authorization-token action and ECS task-definition registration use `Resource: "*"`, where these APIs require or do not support useful resource-level scoping; all other applicable resources are scoped.

The policy deliberately excludes ECR repository administration/deletion, ECS cluster/service creation or deletion, broad ECS management, task-role modification, arbitrary `iam:PassRole`, S3 writes/deletes, and access to other repositories, services, buckets, or objects. Add permissions only if the pipeline's actual deployment flow demonstrates a specific need.


## TASK 5: Find and Fix the Bug

The trust policy names arn:aws:iam::000000000000:user/roleB, but roleB is an IAM role, not a user. prinsipal must be arn:aws:iam::000000000000:role/roleB.
s3 bucket is granted for every bucket(s3:*) in account, the fixed policy keeps the requested full S3 actions but limits resources to the one configured bucket ARN and its `/*` object ARN.
