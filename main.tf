# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

locals {
  tunnel_name  = "${var.tunnel_prefix_name}-${var.tunnel_name}"
  tunnel_token = try(base64encode(random_password.tunnel_token[0].result), null)

  # Parses a timeout value that may be a number (seconds) or a duration string
  # (e.g. "30s", "1m30s", "2m") into a number of seconds. Returns null for null input.
  # This provides backward compatibility with the old string-based timeout format.
  _parse_timeout = {
    for k, v in merge(
      # Global origin_request timeouts
      {
        global_connect_timeout    = try(var.tunnel_config.origin_request.connect_timeout, null)
        global_tls_timeout        = try(var.tunnel_config.origin_request.tls_timeout, null)
        global_tcp_keep_alive     = try(var.tunnel_config.origin_request.tcp_keep_alive, null)
        global_keep_alive_timeout = try(var.tunnel_config.origin_request.keep_alive_timeout, null)
      },
      # Per-ingress-rule origin_request timeouts
      merge([for i, rule in var.tunnel_config.ingress_rule : {
        "ingress_${i}_connect_timeout"    = try(rule.origin_request.connect_timeout, null)
        "ingress_${i}_tls_timeout"        = try(rule.origin_request.tls_timeout, null)
        "ingress_${i}_tcp_keep_alive"     = try(rule.origin_request.tcp_keep_alive, null)
        "ingress_${i}_keep_alive_timeout" = try(rule.origin_request.keep_alive_timeout, null)
      }]...)
      ) : k => (
      v == null ? null :
      try(tonumber(v), null) != null ? tonumber(v) :
      can(regex("^(\\d+)m(\\d+)s$", tostring(v))) ? (
        tonumber(regex("^(\\d+)m(\\d+)s$", tostring(v))[0]) * 60 +
        tonumber(regex("^(\\d+)m(\\d+)s$", tostring(v))[1])
      ) :
      can(regex("^(\\d+)m$", tostring(v))) ? (
        tonumber(regex("^(\\d+)m$", tostring(v))[0]) * 60
      ) :
      can(regex("^(\\d+)s$", tostring(v))) ? (
        tonumber(regex("^(\\d+)s$", tostring(v))[0])
      ) :
      tonumber(v)
    )
  }
}

# TODO: change resource with ephemeral resource once it's released:
# https://github.com/hashicorp/terraform-provider-random/pull/625
resource "random_password" "tunnel_token" {
  count  = var.module_enabled ? 1 : 0
  length = 64

  keepers = {
    tunnel_name = local.tunnel_name
  }

  depends_on = [var.module_depends_on]
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  count      = var.module_enabled ? 1 : 0
  depends_on = [var.module_depends_on]

  account_id    = var.account_id
  name          = local.tunnel_name
  tunnel_secret = local.tunnel_token
  config_src    = var.tunnel_config_src
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel_config" {
  count      = var.module_enabled ? 1 : 0
  depends_on = [var.module_depends_on]

  account_id = var.account_id
  tunnel_id  = try(cloudflare_zero_trust_tunnel_cloudflared.tunnel[0].id, null)

  config = {
    origin_request = var.tunnel_config.origin_request != null ? {
      connect_timeout          = local._parse_timeout["global_connect_timeout"]
      tls_timeout              = local._parse_timeout["global_tls_timeout"]
      tcp_keep_alive           = local._parse_timeout["global_tcp_keep_alive"]
      no_happy_eyeballs        = var.tunnel_config.origin_request.no_happy_eyeballs
      keep_alive_connections   = var.tunnel_config.origin_request.keep_alive_connections
      keep_alive_timeout       = local._parse_timeout["global_keep_alive_timeout"]
      http_host_header         = var.tunnel_config.origin_request.http_host_header
      origin_server_name       = var.tunnel_config.origin_request.origin_server_name
      ca_pool                  = var.tunnel_config.origin_request.ca_pool
      no_tls_verify            = var.tunnel_config.origin_request.no_tls_verify
      disable_chunked_encoding = var.tunnel_config.origin_request.disable_chunked_encoding
      http2_origin             = var.tunnel_config.origin_request.http2_origin
      proxy_type               = var.tunnel_config.origin_request.proxy_type
      access                   = var.tunnel_config.origin_request.access
    } : null

    ingress = [for i, rule in var.tunnel_config.ingress_rule : {
      hostname = rule.hostname
      path     = rule.path
      service  = rule.service
      origin_request = rule.origin_request != null ? {
        connect_timeout          = local._parse_timeout["ingress_${i}_connect_timeout"]
        tls_timeout              = local._parse_timeout["ingress_${i}_tls_timeout"]
        tcp_keep_alive           = local._parse_timeout["ingress_${i}_tcp_keep_alive"]
        no_happy_eyeballs        = rule.origin_request.no_happy_eyeballs
        keep_alive_connections   = rule.origin_request.keep_alive_connections
        keep_alive_timeout       = local._parse_timeout["ingress_${i}_keep_alive_timeout"]
        http_host_header         = rule.origin_request.http_host_header
        origin_server_name       = rule.origin_request.origin_server_name
        ca_pool                  = rule.origin_request.ca_pool
        no_tls_verify            = rule.origin_request.no_tls_verify
        disable_chunked_encoding = rule.origin_request.disable_chunked_encoding
        http2_origin             = rule.origin_request.http2_origin
        proxy_type               = rule.origin_request.proxy_type
        access                   = rule.origin_request.access
      } : null
    }]
  }
}
