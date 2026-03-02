# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

output "tunnel_name" {
  description = "The name of the Cloudflare Tunnel."
  value       = try(cloudflare_zero_trust_tunnel_cloudflared.tunnel[0].name, null)
}

output "tunnel_id" {
  description = "The ID of the Cloudflare Tunnel."
  value       = try(cloudflare_zero_trust_tunnel_cloudflared.tunnel[0].id, null)
}

output "tunnel_token" {
  description = "The token of the Cloudflare Tunnel."
  value       = local.tunnel_token
  sensitive   = true
}

output "tunnel_cname" {
  description = "The CNAME of the Cloudflare Tunnel."
  value       = try("${cloudflare_zero_trust_tunnel_cloudflared.tunnel[0].id}.cfargotunnel.com", null)
}

output "module_enabled" {
  description = "Whether the module is enabled or not."
  value       = var.module_enabled
}
