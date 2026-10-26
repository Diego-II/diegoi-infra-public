# ---------------------------------------------------------------------------
# module "account" -- vends a new AWS account into the organization.
#
# Runs in the MANAGEMENT account (Organizations API). It only creates the
# account shell + OU placement. Everything *inside* the account is handled by
# module "account-baseline", applied with a provider that assumes into it.
# ---------------------------------------------------------------------------

resource "aws_organizations_account" "this" {
  name      = var.name
  email     = var.email
  parent_id = var.parent_id

  # Auto-created in the new account; the tenant stack assumes it.
  role_name                  = "OrganizationAccountAccessRole"
  iam_user_access_to_billing = "ALLOW"

  tags = var.tags

  lifecycle {
    # Changing these forces account replacement -- never do it by accident.
    ignore_changes = [role_name]
  }
}
