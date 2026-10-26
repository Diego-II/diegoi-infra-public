output "zone_name_servers" {
  description = "Set on the registrar automatically; shown for debugging."
  value       = cloudflare_zone.this.name_servers
}

output "tunnel_id" {
  description = "Fetch the connector token with it (see README), never via Terraform."
  value       = cloudflare_zero_trust_tunnel_cloudflared.winbox.id
}

output "app_urls" {
  value = [for name in keys(local.apps) : "https://${name}.${local.domain}"]
}

output "mesh_node_id" {
  description = "Fetch the node token with it (see home-agent scripts/setup-mesh.sh), never via Terraform."
  value       = cloudflare_zero_trust_tunnel_warp_connector.winbox.id
}

output "app_aud" {
  description = "Access audience tag per app (origins validate Cf-Access-Jwt-Assertion against it)"
  value       = { for k, a in cloudflare_zero_trust_access_application.app : k => a.aud }
}
