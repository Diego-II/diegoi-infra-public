# ---------------------------------------------------------------------------
# module "app-secrets" -- SSM SecureString parameters for one app, namespaced
# /<app_name>/<KEY>.
#
# Terraform creates the parameter *structure* with a placeholder value; the
# REAL value is written out-of-band:
#
#   aws ssm put-parameter --name /<app>/<KEY> --type SecureString \
#       --value '...' --overwrite
#
# `ignore_changes = [value]` then keeps Terraform from reverting it. So secret
# values never live in git or in Terraform state.
# ---------------------------------------------------------------------------

resource "aws_ssm_parameter" "secret" {
  for_each = toset(var.keys)

  name  = "/${var.app_name}/${each.value}"
  type  = "SecureString"
  value = "PLACEHOLDER - set with: aws ssm put-parameter --overwrite"
  tags  = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}
