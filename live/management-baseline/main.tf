# ===========================================================================
# Management-account baseline: cost protection + keyless CI for THIS repo.
# Run in the management account.
# ===========================================================================

data "aws_caller_identity" "current" {}

# --- Cost guardrail: surprise-bill protection for personal AWS --------------

resource "aws_budgets_budget" "monthly" {
  name         = "monthly-cost"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Alert at absolute spend levels ($15, $20) against the $50 ceiling.
  dynamic "notification" {
    for_each = toset(var.alert_thresholds_usd)
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "ABSOLUTE_VALUE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [var.alert_email]
    }
  }
}

# --- Keyless CI for this repo: GitHub Actions -> management account ----------
# Lets `live/*` stacks plan/apply from CI without stored AWS keys. The trust
# is locked to this repo. AdministratorAccess is broad on purpose for now
# (it manages the org); scope it down once the surface is known.

# The GitHub OIDC provider already exists in this account (shared with other
# projects). Reference it rather than own it, so this stack can't clobber it.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "infra_ci_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.infra_github_owner}/${var.infra_github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "infra_ci" {
  name               = "github-actions-infra"
  assume_role_policy = data.aws_iam_policy_document.infra_ci_trust.json
}

resource "aws_iam_role_policy_attachment" "infra_ci_admin" {
  role       = aws_iam_role.infra_ci.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- Project deploy role kept in the ROOT account (deliberate exception) ----
# app-d keeps its small DynamoDB table in the management account
# (no migration). Grant its repo keyless, TABLE-SCOPED access only -- it can
# create/manage tables named "<prefix>*" but cannot touch other tables here.

data "aws_iam_policy_document" "app_d_dynamo" {
  statement {
    sid     = "ManageOwnTables"
    effect  = "Allow"
    actions = ["dynamodb:*"]
    resources = [
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.app_d_table_prefix}*",
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.app_d_table_prefix}*/index/*",
    ]
  }

  statement {
    sid       = "ListAndLimits"
    effect    = "Allow"
    actions   = ["dynamodb:ListTables", "dynamodb:DescribeLimits"]
    resources = ["*"]
  }
}

module "app_d_deploy_role" {
  source = "../../modules/github-deploy-role"

  name         = "github-actions-app-d"
  github_owner = "Diego-II"
  github_repo  = "app-d"

  inlapp1_policy_json = data.aws_iam_policy_document.app_d_dynamo.json

  tags = {
    Project   = "app-d"
    ManagedBy = "terraform"
  }
}

# --- Optional: organization-wide CloudTrail ---------------------------------
# Off by default. Requires enabling cloudtrail.amazonaws.com trusted access in
# live/org's aws_service_access_principals before turning this on.

resource "aws_s3_bucket" "cloudtrail" {
  count  = var.enable_org_cloudtrail ? 1 : 0
  bucket = "diegoi-org-cloudtrail-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count                   = var.enable_org_cloudtrail ? 1 : 0
  bucket                  = aws_s3_bucket.cloudtrail[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "cloudtrail" {
  count = var.enable_org_cloudtrail ? 1 : 0

  statement {
    sid       = "AWSCloudTrailAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail[0].arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_org_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = data.aws_iam_policy_document.cloudtrail[0].json
}

resource "aws_cloudtrail" "org" {
  count                         = var.enable_org_cloudtrail ? 1 : 0
  name                          = "org-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  is_organization_trail         = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}
