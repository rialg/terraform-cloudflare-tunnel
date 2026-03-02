# Upgrading Guide

## Upgrading to Cloudflare Provider v5.17.0

The Cloudflare Terraform provider v5.17.0 introduced breaking changes to
several resource types and schemas. This module has been updated to support
the new provider, with backward-compatible variable definitions where possible.

However, **existing Terraform state requires manual migration** before running
`terraform plan` or `terraform apply` with the updated module.

### State Migration Steps

The following resources are affected and must be migrated in the order shown.

#### 1. Tunnel Config (`cloudflare_zero_trust_tunnel_cloudflared_config`)

The `config` attribute changed from a block (list) to an object in the new
provider schema. The provider cannot automatically upgrade the state, so the
resource must be removed from state and re-imported.

**Identify your resources:**

```shell
terraform state list | grep 'cloudflare_zero_trust_tunnel_cloudflared_config'
```

**For each resource, remove and re-import:**

```shell
# Get the account_id and tunnel_id from the current state
terraform state show '<MODULE_PATH>.cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config[0]'

# Remove from state
terraform state rm '<MODULE_PATH>.cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config[0]'

# Re-import using account_id and tunnel_id
terraform import '<MODULE_PATH>.cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config[0]' '<ACCOUNT_ID>/<TUNNEL_ID>'
```

**Example** (for a module named `bastion_tunnel`):

```shell
terraform state rm 'module.bastion_tunnel.cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config[0]'
terraform import 'module.bastion_tunnel.cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config[0]' '699d98642c564d2e855e9661899b7252/f70ff985-a4ef-4643-bbbc-4a0ed4fc8415'
```

#### 2. Tunnel Routes (`cloudflare_zero_trust_tunnel_route` → `cloudflare_zero_trust_tunnel_cloudflared_route`)

The resource type was renamed. Use `terraform state mv` to update the state
without destroying and recreating the resources.

**Identify your resources:**

```shell
terraform state list | grep 'cloudflare_zero_trust_tunnel_route'
```

> **Note:** If you are using the `tunnel-route` submodule, the resources are
> keyed by network CIDR (e.g. `["10.10.10.0/24"]`).

**For each resource, rename in state:**

```shell
terraform state mv \
  '<MODULE_PATH>.cloudflare_zero_trust_tunnel_route.route["<NETWORK_CIDR>"]' \
  '<MODULE_PATH>.cloudflare_zero_trust_tunnel_cloudflared_route.route["<NETWORK_CIDR>"]'
```

**Example:**

```shell
terraform state mv \
  'module.network_routes.cloudflare_zero_trust_tunnel_route.route["10.10.10.0/24"]' \
  'module.network_routes.cloudflare_zero_trust_tunnel_cloudflared_route.route["10.10.10.0/24"]'
```

#### 3. Virtual Networks (`cloudflare_zero_trust_tunnel_virtual_network` → `cloudflare_zero_trust_tunnel_cloudflared_virtual_network`)

The resource type was renamed. Use `terraform state mv` to update the state.

**Identify your resources:**

```shell
terraform state list | grep 'cloudflare_zero_trust_tunnel_virtual_network'
```

**For each resource, rename in state:**

```shell
terraform state mv \
  '<MODULE_PATH>.cloudflare_zero_trust_tunnel_virtual_network.virtual_network[0]' \
  '<MODULE_PATH>.cloudflare_zero_trust_tunnel_cloudflared_virtual_network.virtual_network[0]'
```

**Example:**

```shell
terraform state mv \
  'module.virtual_network_01.cloudflare_zero_trust_tunnel_virtual_network.virtual_network[0]' \
  'module.virtual_network_01.cloudflare_zero_trust_tunnel_cloudflared_virtual_network.virtual_network[0]'
```

### Verification

After completing the state migration steps, run `terraform plan` to verify:

```shell
terraform plan
```

The plan should show **no unexpected changes**. You may see in-place updates
for fields that have new default values in the provider, but there should be
no destroy/recreate actions for the migrated resources.

### Deprecated Variables

The following `tunnel_config` fields are still accepted for backward
compatibility but are **silently ignored** by the provider >= 5.17.0:

| Field | Notes |
|-------|-------|
| `warp_routing` | No longer a tunnel config attribute. |
| `origin_request.bastion_mode` | Removed from provider schema. |
| `origin_request.proxy_address` | Removed from provider schema. |
| `origin_request.proxy_port` | Removed from provider schema. |
| `origin_request.ip_rules` | Removed from provider schema. |

Timeout fields (`connect_timeout`, `tls_timeout`, `tcp_keep_alive`,
`keep_alive_timeout`) now expect **numbers (seconds)** instead of duration
strings. The old string format (e.g. `"30s"`, `"1m30s"`) is still accepted
and automatically converted.
