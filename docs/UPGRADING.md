# Upgrading Guide

## Upgrading to Cloudflare Provider v5

The Cloudflare Terraform provider v5 introduced breaking changes to
several resource types and schemas. This module has been updated to
support the new provider, with backward-compatible variable definitions
where possible.

However, **existing Terraform state requires manual migration** before
running `terraform plan` or `terraform apply` with the updated module.

### State Migration Steps

The following resources are affected and must be migrated in the order
shown below.

In all examples below, replace `<MOD>` with your actual module path
(e.g. `module.bastion_tunnel`).

<!-- markdownlint-disable MD013 -->

#### 1. Tunnel Config

The `config` attribute changed from a block (list) to an object in the
new provider schema. The provider cannot automatically upgrade the
state, so the resource must be removed from state and re-imported.

**Identify your resources:**

```shell
terraform state list | grep tunnel_cloudflared_config
```

**For each resource, remove and re-import:**

```shell
# Get the account_id and tunnel_id from state
terraform state show '<MOD>.cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config[0]'

# Remove from state
terraform state rm '<MOD>.cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config[0]'

# Re-import using account_id and tunnel_id
terraform import '<MOD>.cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config[0]' '<ACCOUNT_ID>/<TUNNEL_ID>'
```

#### 2. Tunnel Routes

Resource type renamed from `cloudflare_zero_trust_tunnel_route` to
`cloudflare_zero_trust_tunnel_cloudflared_route`.

Use `terraform state mv` to update the state without destroying and
recreating the resources.

**Identify your resources:**

```shell
terraform state list | grep tunnel_route
```

> **Note:** If you are using the `tunnel-route` submodule, the
> resources are keyed by network CIDR (e.g. `["10.10.10.0/24"]`).

**For each resource, rename in state:**

```shell
terraform state mv \
  '<MOD>.cloudflare_zero_trust_tunnel_route.route["<CIDR>"]' \
  '<MOD>.cloudflare_zero_trust_tunnel_cloudflared_route.route["<CIDR>"]'
```

#### 3. Virtual Networks

Resource type renamed from
`cloudflare_zero_trust_tunnel_virtual_network` to
`cloudflare_zero_trust_tunnel_cloudflared_virtual_network`.

Use `terraform state mv` to update the state.

**Identify your resources:**

```shell
terraform state list | grep tunnel_virtual_network
```

**For each resource, rename in state:**

```shell
terraform state mv \
  '<MOD>.cloudflare_zero_trust_tunnel_virtual_network.virtual_network[0]' \
  '<MOD>.cloudflare_zero_trust_tunnel_cloudflared_virtual_network.virtual_network[0]'
```

<!-- markdownlint-enable MD013 -->

### Verification

After completing the state migration steps, run `terraform plan` to
verify:

```shell
terraform plan
```

The plan should show **no unexpected changes**. You may see in-place
updates for fields that have new default values in the provider, but
there should be no destroy/recreate actions for the migrated resources.

### Deprecated Variables

The following `tunnel_config` fields are still accepted for backward
compatibility but are **silently ignored** by the provider v5:

| Field                          | Notes                              |
| ------------------------------ | ---------------------------------- |
| `warp_routing`                 | No longer a tunnel config attr.    |
| `origin_request.bastion_mode`  | Removed from provider schema.      |
| `origin_request.proxy_address` | Removed from provider schema.      |
| `origin_request.proxy_port`    | Removed from provider schema.      |
| `origin_request.ip_rules`      | Removed from provider schema.      |

Timeout fields (`connect_timeout`, `tls_timeout`, `tcp_keep_alive`,
`keep_alive_timeout`) now expect **numbers (seconds)** instead of
duration strings. The old string format (e.g. `"30s"`, `"1m30s"`) is
still accepted and automatically converted.
