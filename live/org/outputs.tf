output "org_id" {
  value = aws_organizations_organization.this.id
}

output "root_id" {
  value = local.root_id
}

output "ou_ids" {
  value = {
    workloads = aws_organizations_organizational_unit.workloads.id
    prod      = aws_organizations_organizational_unit.prod.id
    nonprod   = aws_organizations_organizational_unit.nonprod.id
    sandbox   = aws_organizations_organizational_unit.sandbox.id
    security  = aws_organizations_organizational_unit.security.id
  }
}

# Consumed by live/identity-center and live/accounts/project-a via remote state.
output "project_a_account_id" {
  value = module.project_a.account_id
}

# Consumed by live/accounts/homelab via remote state.
output "homelab_account_id" {
  value = module.homelab.account_id
}

# Consumed by live/accounts/project-b and live/identity-center via remote state.
output "project_b_account_id" {
  value = module.project-b.account_id
}
