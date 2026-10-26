# ===========================================================================
# homelab account baseline + winbox secret access.
#
# Shared account for everything the home server (winbox) runs. It holds each
# app's secrets in SSM Parameter Store (namespaced /<app>/*) and one IAM user
# ("winbox") the box uses to read them. Like the other tenant stacks, it runs
# from the management account by assuming the homelab
# OrganizationAccountAccessRole.
#
# Apply order: live/org (creates the account) -> here.
# ===========================================================================

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
    role_arn = "arn:aws:iam::${data.terraform_remote_state.org.outputs.homelab_account_id}:role/OrganizationAccountAccessRole"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  tags = {
    Project   = "homelab"
    ManagedBy = "terraform"
  }
}

# --- account baseline: OIDC deploy role (future) + isolated state bucket -----
module "baseline" {
  source = "../../../modules/account-baseline"

  project_name = "homelab"
  github_owner = var.github_owner
  github_repo  = var.github_repo
  tags         = local.tags
}

# --- app4 app secrets (values set out-of-band, never in git/state) ---------
module "app4_secrets" {
  source   = "../../../modules/app-secrets"
  app_name = "app4"
  keys = [
    "RUT",
    "PASS_ITAU",
    "FINTOC_SECRET_KEY",
    "FINTOC_LINK_TOKEN",
    "FINTOC_ACCOUNT_ID",
  ]
  tags = local.tags
}

# --- winbox IAM user: read-only on every app secret in this account ----------
resource "aws_iam_user" "winbox" {
  name = "winbox"
  tags = local.tags
}

data "aws_iam_policy_document" "winbox_read_secrets" {
  statement {
    sid    = "ReadAppSecrets"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"]
  }

  # SecureString decryption. Scoped so the key can only be used via SSM.
  statement {
    sid       = "DecryptSsmSecureString"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

resource "aws_iam_user_policy" "winbox_read_secrets" {
  name   = "read-app-secrets"
  user   = aws_iam_user.winbox.name
  policy = data.aws_iam_policy_document.winbox_read_secrets.json
}

resource "aws_iam_access_key" "winbox" {
  user = aws_iam_user.winbox.name
}
