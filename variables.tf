# SPDX-FileCopyrightText: Copyright Boozt Fashion, AB
# SPDX-License-Identifier: MIT

variable "api_token" {
  description = "(Optional) The API Token for operations. Alternatively, can be configured using the CLOUDFLARE_API_TOKEN environment variable."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.api_token == null || can(regex("^[a-zA-Z0-9_-]{40}$", var.api_token))
    error_message = "API Token must be 40 characters long and only contain characters a-z, A-Z, 0-9, hyphens and underscores."
  }
}

variable "account_id" {
  description = "(Required) The account ID for the Cloudflare account."
  type        = string
}

variable "tunnel_prefix_name" {
  description = "(Optional) The prefix name of the Cloudflare Tunnel."
  type        = string
  default     = "tf-tunnel"
}

variable "tunnel_name" {
  description = "(Required) The name of the Cloudflare Tunnel."
  type        = string
}

variable "tunnel_config_src" {
  description = "(Optional) Indicates if this is a locally or remotely configured tunnel. If local, manage the tunnel using a YAML file on the origin machine. If cloudflare, manage the tunnel on the Zero Trust dashboard or using tunnel_config, tunnel_route or tunnel_virtual_network resources. Available values: local, cloudflare."
  type        = string
  default     = "cloudflare"

  validation {
    condition     = can(regex("^(cloudflare|local)$", var.tunnel_config_src))
    error_message = "The Cloudflare Tunnel configuration source must be either 'cloudflare' or 'local'."
  }
}

variable "tunnel_config" {
  description = <<-EOT
    (Required) The configuration for the Cloudflare Tunnel.

    Deprecated fields (ignored by provider >= 5.17.0, kept for backward compatibility):
    - warp_routing: No longer supported in tunnel config resource.
    - origin_request.bastion_mode: No longer supported in provider >= 5.17.0.
    - origin_request.proxy_address: No longer supported in provider >= 5.17.0.
    - origin_request.proxy_port: No longer supported in provider >= 5.17.0.
    - origin_request.ip_rules: No longer supported in provider >= 5.17.0.

    Changed fields:
    - Timeout fields (connect_timeout, tls_timeout, tcp_keep_alive, keep_alive_timeout)
      now expect numbers (seconds). String values (e.g. "30s") are still accepted for
      backward compatibility and will be automatically converted.
  EOT
  type = object({
    # Deprecated: no longer supported in provider >= 5.17.0, kept for backward compatibility.
    warp_routing = optional(bool, false)

    origin_request = optional(object({
      connect_timeout          = optional(any)
      tls_timeout              = optional(any)
      tcp_keep_alive           = optional(any)
      no_happy_eyeballs        = optional(bool, false)
      keep_alive_connections   = optional(number, 100)
      keep_alive_timeout       = optional(any)
      http_host_header         = optional(string, "")
      origin_server_name       = optional(string, "")
      ca_pool                  = optional(string, "")
      no_tls_verify            = optional(bool, false)
      disable_chunked_encoding = optional(bool, false)
      http2_origin             = optional(bool, false)
      proxy_type               = optional(string, "")

      # Deprecated: no longer supported in provider >= 5.17.0, kept for backward compatibility.
      bastion_mode  = optional(bool, false)
      proxy_address = optional(string, "127.0.0.1")
      proxy_port    = optional(string, "0")

      # Deprecated: no longer supported in provider >= 5.17.0, kept for backward compatibility.
      ip_rules = optional(list(object({
        prefix = optional(string)
        ports  = optional(list(number))
        allow  = optional(bool)
      })))

      access = optional(object({
        required  = optional(bool)
        team_name = optional(string)
        aud_tag   = optional(list(string))
      }))
    }))

    ingress_rule = list(object({
      hostname = optional(string)
      path     = optional(string)
      service  = string

      origin_request = optional(object({
        connect_timeout          = optional(any)
        tls_timeout              = optional(any)
        tcp_keep_alive           = optional(any)
        no_happy_eyeballs        = optional(bool, false)
        keep_alive_connections   = optional(number, 100)
        keep_alive_timeout       = optional(any)
        http_host_header         = optional(string, "")
        origin_server_name       = optional(string, "")
        ca_pool                  = optional(string, "")
        no_tls_verify            = optional(bool, false)
        disable_chunked_encoding = optional(bool, false)
        http2_origin             = optional(bool, false)
        proxy_type               = optional(string, "")

        # Deprecated: no longer supported in provider >= 5.17.0, kept for backward compatibility.
        bastion_mode  = optional(bool, false)
        proxy_address = optional(string, "127.0.0.1")
        proxy_port    = optional(string, "0")

        # Deprecated: no longer supported in provider >= 5.17.0, kept for backward compatibility.
        ip_rules = optional(list(object({
          prefix = optional(string)
          ports  = optional(list(number))
          allow  = optional(bool)
        })))

        access = optional(object({
          required  = optional(bool)
          team_name = optional(string)
          aud_tag   = optional(list(string))
        }))
      }))
    }))
  })

  validation {
    condition     = can(length(var.tunnel_config.ingress_rule))
    error_message = "The Cloudflare Tunnel configuration must have at least one ingress rule."
  }
}

variable "module_enabled" {
  type        = bool
  description = "(Optional) Whether to create resources within the module or not."
  default     = true
}

variable "module_depends_on" {
  type        = any
  description = "(Optional) A list of external resources the module depends_on."
  default     = []
}
