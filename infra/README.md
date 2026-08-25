# infra/ — serve these docs as a public read-only MCP

Provisions the EC2 that exposes the content of [`../vault/`](../vault) as a **public read-only MCP** at
**`https://mcp.splitphp.org/mcp`** — usable by any MCP/AI client (and by Lambda TT's dev-bot).

```
EC2 (t4g.nano arm64, Ubuntu 24.04, 2GB swap)
 ├─ headless Obsidian (xvfb) opening the vault at ../vault
 │   └─ semantic-vault-mcp plugin → readOnlyMode:true, loopback :3001, apiKey (Caddy only)
 ├─ Caddy → mcp.splitphp.org:443 (Let's Encrypt), rate-limit 60/min/IP
 │           reverse_proxy → 127.0.0.1:3001, injects Authorization: Bearer {$MCP_KEY}
 └─ systemd timer → git pull --ff-only every 15min (the vault auto-updates from this repo)
```
The public hits Caddy **without auth**; Caddy injects the internal apiKey → Obsidian is never exposed
directly. `readOnlyMode` is enforced **server-side** (writes blocked for everyone). **No secrets** in the vault.

## Contents

- `Caddyfile` — the `mcp.splitphp.org` vhost (uses `{$MCP_KEY}` from the env; no secret in the file).
- `systemd/` — `xvfb.service`, `obsidian-vault.service`, `caddy.service`, `vault-pull.service` + `.timer`.
- `scripts/obsidian-run.sh` — launches Obsidian and **disables Restricted Mode via CDP** (otherwise the
  plugin won't load). `scripts/cdp.py` — a minimal CDP client (stdlib only). `scripts/provision.sh` — the provisioner.
- `obsidian-skeleton/` — the vault config `.json` files (community/core-plugins, app, appearance). **The
  plugin itself (main.js/manifest.json/styles.css) is NOT versioned** (third-party). Get it from
  <https://github.com/aaronsb/semantic-vault-mcp> and place it under
  `obsidian-skeleton/plugins/semantic-vault-mcp/` (or directly into the vault) before provisioning.

## Provision (from scratch)

Prerequisites: an Ubuntu 24.04 **arm64** EC2 + Elastic IP; a **Security Group** with inbound `443`+`80`
← 0.0.0.0/0 (443 = MCP, 80 = ACME challenge) and `22` restricted to your IP; a **DNS** A record
`mcp.splitphp.org` → the Elastic IP.

```sh
git clone https://github.com/splitphp/Docs.git ~/vault
bash ~/vault/infra/scripts/provision.sh
# verify (once the cert is issued):
curl -s -o /dev/null -w '%{http_code}\n' https://mcp.splitphp.org/mcp    # 400 = ok (internal auth + MCP endpoint)
```

## Keys / secrets

The plugin's `apiKey` is generated during provisioning and lives in `/etc/mcp.key` (and `/etc/caddy/mcp.env`
as `MCP_KEY`) **on the instance** — never in this repo. The root `.gitignore` excludes `.obsidian/` (which
holds the `data.json` with the key). The vault is **pull-only**: the instance never commits/pushes.

## Notes

- A `t4g.nano` (ARM, ~408MB) is enough (real workload ~150MB) **with the 2GB swap**. If it OOMs under
  load, bump to `t4g.micro`.
- Always re-clone / re-point with clone-to-temp + atomic swap (`provision.sh` already does this).
