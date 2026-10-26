# No assume_role and no credentials here -- they come from the `project-b` profile
# in ~/.aws/config, which assumes OrganizationAccountAccessRole from my-org.
#
#   AWS_PROFILE=project-b terraform plan
#
# Infra is applied from a laptop, deliberately: no GitHub Actions, no CI role,
# nothing on the internet holding standing credentials to this account.
provider "aws" {
  region = var.aws_region

  # Belt and braces: refuse to run against the wrong account. Without this a
  # stale local profile can happily apply project-b's config into project-a.
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = {
      Project   = "project-b"
      ManagedBy = "terraform"
    }
  }
}
