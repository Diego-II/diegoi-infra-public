# ---------------------------------------------------------------------------
# Import blocks (Terraform 1.5+). These adopt EXISTING resources into state
# without recreating them. Review `terraform plan` carefully: it must show the
# org being imported with NO destructive changes (only the intended SCP enable).
#
# After the first successful apply, these blocks are harmless to leave or
# remove.
# ---------------------------------------------------------------------------

import {
  to = aws_organizations_organization.this
  id = "o-exampleorg1"
}

# --- Legacy (222222222222) ------------------------------------------------
# Left UNMANAGED for now. It is a separate person's account and may have been
# invited (no OrganizationAccountAccessRole). To bring it under management:
#   1. confirm the access role exists in that account,
#   2. add a matching `aws_organizations_account` resource,
#   3. uncomment the import below and run plan.
#
# import {
#   to = aws_organizations_account.legacy
#   id = "222222222222"
# }
