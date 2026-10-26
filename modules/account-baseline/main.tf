# ---------------------------------------------------------------------------
# module "account-baseline" -- the standard setup INSIDE a vended account.
#
# Apply this with a provider that assumes OrganizationAccountAccessRole in the
# target account (see live/accounts/<project>). It gives the project's own
# GitHub repo keyless (OIDC) deploy access plus an isolated state bucket.
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  subjects = coalesce(
    var.github_subject_filters,
    ["repo:${var.github_owner}/${var.github_repo}:*"],
  )
}

# --- Keyless CI: GitHub Actions -> AWS via OIDC (no stored access keys) -----

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

data "aws_iam_policy_document" "deploy_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.subjects
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = "github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.deploy_trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "deploy" {
  for_each   = toset(var.deploy_policy_arns)
  role       = aws_iam_role.deploy.name
  policy_arn = each.value
}

# --- The project's own, isolated Terraform state bucket --------------------

resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
