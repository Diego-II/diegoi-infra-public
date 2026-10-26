# ===========================================================================
# Organization layer -- runs in the MANAGEMENT account (111111111111).
# Keep this account thin: org structure, guardrails, account vending. No apps.
# ===========================================================================

# The org already exists; it is imported (see imports.tf). Declaring it here
# lets Terraform manage feature set, enabled SCP policy type, and trusted
# service access. The two service principals below match what is already on
# (Identity Center + Cost Optimization Hub) so the import shows no churn.
# NOTE: enabling SERVICE_CONTROL_POLICY is an intentional change -- SCPs are
# not yet enabled on your root, and they are required to attach guardrails.
resource "aws_organizations_organization" "this" {
  feature_set          = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]

  aws_service_access_principals = [
    "sso.amazonaws.com",
    "cost-optimization-hub.bcm.amazonaws.com",
  ]
}

locals {
  root_id = aws_organizations_organization.this.roots[0].id
}

# --- Organizational Units ---------------------------------------------------

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "nonprod" {
  name      = "NonProd"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = local.root_id
}

# --- Account vending --------------------------------------------------------

module "project_a" {
  source = "../../modules/account"

  name      = "project-a"
  email     = "owner+project-a@example.com"
  parent_id = aws_organizations_organizational_unit.prod.id

  tags = {
    Project   = "project-a"
    ManagedBy = "terraform"
  }
}

# Shared account for everything the home server (winbox) runs: per-app secrets
# in SSM + the winbox IAM user. See live/accounts/homelab.
module "homelab" {
  source = "../../modules/account"

  name      = "homelab"
  email     = "owner+homelab@example.com"
  parent_id = aws_organizations_organizational_unit.nonprod.id

  tags = {
    Project   = "homelab"
    ManagedBy = "terraform"
  }
}

# Experimental account for the government-data / "presidential projects" work.
# Placed in Sandbox rather than Workloads: it is exploratory, and nothing
# production depends on it. NOTE: the baseline-guardrails SCP below is attached
# to Workloads only, so this account is NOT covered by it.
module "project-b" {
  source = "../../modules/account"

  name      = "project-b"
  email     = "owner+project-b@example.com"
  parent_id = aws_organizations_organizational_unit.sandbox.id

  tags = {
    Project   = "project-b"
    ManagedBy = "terraform"
  }
}

# --- Minimal guardrails (SCP) ----------------------------------------------
# Deliberately small: prevent member accounts from leaving the org or
# tampering with CloudTrail. Attached to Workloads only -- never to the
# management account (SCPs do not apply there anyway).

data "aws_iam_policy_document" "guardrails" {
  statement {
    sid       = "DenyLeaveOrganization"
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }

  statement {
    sid    = "ProtectCloudTrail"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "guardrails" {
  name    = "baseline-guardrails"
  type    = "SERVICE_CONTROL_POLICY"
  content = data.aws_iam_policy_document.guardrails.json

  # SCP policy type must be enabled on the org first.
  depends_on = [aws_organizations_organization.this]
}

resource "aws_organizations_policy_attachment" "guardrails_workloads" {
  policy_id = aws_organizations_policy.guardrails.id
  target_id = aws_organizations_organizational_unit.workloads.id
}
