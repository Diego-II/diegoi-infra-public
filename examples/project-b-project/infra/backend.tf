# State lives in the project-b account's OWN bucket, created by the factory
# (modules/account-baseline). This repo never touches the management account.
#
# The bucket already exists -- do not declare it here. Creating your own state
# bucket from the repo whose state it holds is the classic chicken-and-egg.
terraform {
  backend "s3" {
    bucket       = "project-b-tfstate-333333333333"
    key          = "infra/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # native S3 locking, no DynamoDB table
  }
}
