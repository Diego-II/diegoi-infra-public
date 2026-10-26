# ===========================================================================
# project-b account baseline.
#
# Sandbox account for the government-data / "presidential projects" work. Like
# the other tenant stacks, it runs from the management account but acts INSIDE
# the project-b account by assuming its OrganizationAccountAccessRole. It sets up
# keyless deploys for the project repo + that account's own state bucket; the
# project repo owns everything else.
#
# Apply order: live/org (creates the account) -> here.
# ===========================================================================

# Account id produced by the org layer.
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
    role_arn = "arn:aws:iam::${data.terraform_remote_state.org.outputs.project_b_account_id}:role/OrganizationAccountAccessRole"
  }
}

# Second provider WITHOUT assume_role: this stack already runs with management
# credentials, so the un-assumed provider is the management account. Needed for
# the parent-zone NS record, which only management can write.
provider "aws" {
  alias  = "management"
  region = "us-east-1"
}

locals {
  tags = {
    Project   = "project-b"
    ManagedBy = "terraform"
  }
}

module "baseline" {
  source = "../../../modules/account-baseline"

  project_name = "project-b"
  github_owner = var.github_owner
  github_repo  = var.github_repo

  tags = local.tags
}

# --- DNS: project-b.example.net delegated into this account -----------------------
# The child zone lives in project-b, so the project can manage its own records with
# no management-account access. The delegation (NS record in the parent zone)
# necessarily lives in management -- hence the aliased provider above.
#
# Both halves are in ONE stack on purpose: split across two stacks, the zone
# can be replaced without its NS record following, and the subdomain silently
# stops resolving. Here Terraform always writes the current name servers.

resource "aws_route53_zone" "this" {
  name    = var.subdomain
  comment = "Delegated subdomain for the project-b project."
  tags    = local.tags
}

resource "aws_route53_record" "delegation" {
  provider = aws.management

  zone_id = var.parent_zone_id
  name    = var.subdomain
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.this.name_servers
}
