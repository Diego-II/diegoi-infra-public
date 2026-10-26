# ===========================================================================
# project-a account baseline.
#
# This stack runs from the management account but acts INSIDE the project-a
# account by assuming its OrganizationAccountAccessRole. It sets up keyless
# deploys for the Diego-II/project-a project repo + that account's own state
# bucket. The project repo then owns everything else.
#
# Apply order: live/org (creates the account) -> here.
# ===========================================================================

# Account id produced by the org layer.
data "terraform_remote_state" "org" {
  backend = "s3"
  config = {
    bucket = "diegoi-tfstate-111111111111"
    key    = "org/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.org.outputs.project_a_account_id}:role/OrganizationAccountAccessRole"
  }
}

module "baseline" {
  source = "../../../modules/account-baseline"

  project_name = "project-a"
  github_owner = var.github_owner
  github_repo  = var.github_repo

  tags = {
    Project   = "project-a"
    ManagedBy = "terraform"
  }
}
