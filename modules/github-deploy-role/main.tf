# ---------------------------------------------------------------------------
# module "github-deploy-role" -- a keyless (OIDC) deploy role for one GitHub
# repo, in the CURRENT account. Use this to grant a repo scoped access to an
# EXISTING account (e.g. the root account) without vending a new one.
#
# Requires the GitHub OIDC provider to already exist in the account.
# ---------------------------------------------------------------------------

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  subjects = coalesce(
    var.subject_filters,
    ["repo:${var.github_owner}/${var.github_repo}:*"],
  )
}

data "aws_iam_policy_document" "trust" {
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
      values   = local.subjects
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count  = var.inlapp1_policy_json == null ? 0 : 1
  name   = "${var.name}-scoped"
  role   = aws_iam_role.this.id
  policy = var.inlapp1_policy_json
}
