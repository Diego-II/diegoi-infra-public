# ===========================================================================
# example.com on Cloudflare: a Tunnel into winbox (WSL), every app behind
# Google SSO via Cloudflare Access.
#
# Whole-domain move, not a delegated home-agent.example.com: child zones are
# Enterprise-only, and Universal SSL doesn't cover a.b.zone names. So apps are
# flat: <app>.example.com.
#
# No secrets in state:
#   - tunnel_secret is left unset, Cloudflare generates it. The connector
#     token is fetched out-of-band (see README) and lives only on the box.
#   - The Google login method is set up by hand in the Zero Trust dashboard,
#     so its OAuth client secret never touches Terraform.
#
# Credentials: CLOUDFLARE_API_TOKEN (env) + management-account AWS creds
# (Route 53 Domains, to point the registrar at Cloudflare).
# ===========================================================================

provider "cloudflare" {}

# Route 53 Domains only exists in us-east-1; domains are in the management account.
provider "aws" {
  region = "us-east-1"
}

locals {
  domain = "example.com"

  # <name> -> { port, allowed_emails }. See apps.yaml.
  apps = yamldecode(file("${path.module}/apps.yaml"))
}

resource "cloudflare_zone" "this" {
  account = { id = var.account_id }
  name    = local.domain
  type    = "full"
}

# Adopts the existing registration; only the nameservers change. Destroying
# this resource just drops it from state, the domain stays registered.
resource "aws_route53domains_registered_domain" "this" {
  domain_name = local.domain

  dynamic "name_server" {
    for_each = cloudflare_zone.this.name_servers
    content {
      name = name_server.value
    }
  }
}

# --- Tunnel: cloudflared on winbox dials out, no inbound ports --------------
resource "cloudflare_zero_trust_tunnel_cloudflared" "winbox" {
  account_id = var.account_id
  name       = "winbox"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "winbox" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.winbox.id

  config = {
    ingress = concat(
      [for name, app in local.apps : {
        hostname = "${name}.${local.domain}"
        service  = "http://localhost:${app.port}"
      }],
      [{ service = "http_status:404" }],
    )
  }
}

# --- Access: Google login in front of everything ---------------------------
# Safety net: any *.example.com host without its own app below is owner-only.
resource "cloudflare_zero_trust_access_policy" "owner" {
  account_id = var.account_id
  name       = "owner"
  decision   = "allow"
  include    = [for e in var.owner_emails : { email = { email = e } }]
}

resource "cloudflare_zero_trust_access_application" "catch_all" {
  account_id       = var.account_id
  name             = "${local.domain} catch-all"
  type             = "self_hosted"
  domain           = "*.${local.domain}"
  session_duration = "24h"

  policies = [{
    id         = cloudflare_zero_trust_access_policy.owner.id
    precedence = 1
  }]
}

# Per app: its own allow-list from apps.yaml. The exact hostname wins over the wildcard.
resource "cloudflare_zero_trust_access_policy" "app" {
  for_each = local.apps

  account_id = var.account_id
  name       = "${each.key} users"
  decision   = "allow"
  include    = [for e in each.value.allowed_emails : { email = { email = e } }]
}

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = local.apps

  account_id       = var.account_id
  name             = each.key
  type             = "self_hosted"
  domain           = "${each.key}.${local.domain}"
  session_duration = "24h"

  policies = [{
    id         = cloudflare_zero_trust_access_policy.app[each.key].id
    precedence = 1
  }]

  # Apps with `mcp: true`: Access acts as the OAuth server for MCP clients (discovery, dynamic client
  # registration, PKCE, tokens), behind the same Google allow-list. The origin must validate Cf-Access-Jwt-Assertion.
  oauth_configuration = try(each.value.mcp, false) ? {
    enabled = true
    dynamic_client_registration = {
      enabled                = true
      allow_any_on_localhost = true # Claude Code and other CLI clients
      allow_any_on_loopback  = true
      allowed_uris           = ["https://claude.ai/api/mcp/auth_callback", "https://claude.com/api/mcp/auth_callback"]
    }
    grant = {
      access_token_lifetime = "15m"  # short tokens, silently refreshed; Access re-checks the allow-list each refresh
      session_duration      = "336h" # 2 weeks before a new Google login
    }
  } : null
}

resource "cloudflare_dns_record" "app" {
  for_each = local.apps

  zone_id = cloudflare_zone.this.id
  name    = "${each.key}.${local.domain}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.winbox.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1

  # An app must never be reachable before its login wall exists.
  depends_on = [cloudflare_zero_trust_access_application.app, cloudflare_zero_trust_access_application.catch_all]
}

# --- Mesh: winbox (WSL) as a Mesh node, for SSH from enrolled devices ------
# No tunnel_secret: the node token is fetched out-of-band, like the tunnel's.
resource "cloudflare_zero_trust_tunnel_warp_connector" "winbox" {
  account_id = var.account_id
  name       = "winbox-mesh" # tunnels and Mesh nodes share one namespace
}

# Mesh nodes default to sending ALL host traffic through Cloudflare. winbox's
# scrapers must egress from the home IP (Itau blocks datacenter IPs), so nodes
# only tunnel the Mesh range; everything else stays on the local ISP.
resource "cloudflare_zero_trust_device_custom_profile" "mesh_nodes" {
  account_id      = var.account_id
  name            = "Mesh nodes: Mesh traffic only"
  match           = "identity.email == \"warp_connector@${var.team_name}.cloudflareaccess.com\""
  precedence      = 100
  tunnel_protocol = "masque" # required for Mesh nodes
  include         = [{ address = "100.96.0.0/12", description = "Cloudflare Mesh" }]
}

# Your own devices (Cloudflare One Client): same Mesh-only routing, and no DNS
# takeover, so Tailscale + MagicDNS keep working alongside it. Full-tunnel mode
# knocked Tailscale offline on the Mac.
resource "cloudflare_zero_trust_device_custom_profile" "owner_devices" {
  account_id      = var.account_id
  name            = "Owner devices: Mesh traffic only"
  match           = join(" or ", [for e in var.owner_emails : "identity.email == \"${e}\""])
  precedence      = 110
  tunnel_protocol = "masque"
  service_mode_v2 = { mode = "warp_tunnel_only" }
  include         = [{ address = "100.96.0.0/12", description = "Cloudflare Mesh" }]
}
