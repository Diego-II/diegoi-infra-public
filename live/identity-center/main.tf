# ===========================================================================
# IAM Identity Center (SSO) -- permission sets + who can reach which account.
# Replaces day-to-day use of the long-lived IAM user with short-lived SSO
# credentials. Run in the management account, after live/org.
#
# NOTE: this manages users in the *default* AWS identity store. If you later
# connect an external IdP (Google Workspace, Okta...), users come from there
# instead -- delete the aws_identitystore_user resource and look up the user
# with a data source.
# ===========================================================================

data "aws_caller_identity" "current" {}

data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

# Account ids vended in the org layer.
data "terraform_remote_state" "org" {
  backend = "s3"
  config = {
    bucket = "diegoi-tfstate-111111111111"
    key    = "org/terraform.tfstate"
    region = "us-east-1"
  }
}

# --- Permission set ---------------------------------------------------------

resource "aws_ssoadmin_permission_set" "admin" {
  name             = "AdministratorAccess"
  description      = "Full admin via SSO."
  instance_arn     = local.instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- Your user --------------------------------------------------------------

resource "aws_identitystore_user" "diego" {
  identity_store_id = local.identity_store_id

  user_name    = "diego"
  display_name = "${var.admin_given_name} ${var.admin_family_name}"

  name {
    given_name  = var.admin_given_name
    family_name = var.admin_family_name
  }

  emails {
    value   = var.admin_email
    primary = true
  }
}

# --- Assignments: admin into the management account + project-a --------------

resource "aws_ssoadmin_account_assignment" "admin_management" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = aws_identitystore_user.diego.user_id
  principal_type = "USER"

  target_id   = data.aws_caller_identity.current.account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "admin_project_a" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = aws_identitystore_user.diego.user_id
  principal_type = "USER"

  target_id   = data.terraform_remote_state.org.outputs.project_a_account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "admin_project_b" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = aws_identitystore_user.diego.user_id
  principal_type = "USER"

  target_id   = data.terraform_remote_state.org.outputs.project_b_account_id
  target_type = "AWS_ACCOUNT"
}
