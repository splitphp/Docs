# infra/ — serve these docs as a public read-only MCP + REST API

Provisions the EC2 that exposes the content of [`../vault/`](../vault) to the world, **read-only**, through
two services on the **same instance**:

- **MCP** at **`https://mcp.splitphp.org/mcp`** — semantic search/read for any MCP/AI client (and the dev-bot).
- **REST** at **`https://api.splitphp.org/vault/*`** — plain `GET` of file content + folder listings, for a
  browser docs site (a separate SPA project). Only `GET /vault/*` is exposed; everything else is `403`.

```
EC2 (t4g.nano arm64, Ubuntu 24.04, 2GB swap)
 ├─ headless Obsidian (xvfb) opening the vault at ../vault, with two plugins:
 │   ├─ semantic-vault-mcp     → readOnlyMode:true, loopback :3001,  apiKey (Caddy only)
 │   └─ obsidian-local-rest-api → loopback HTTP :27123,               apiKey (Caddy only)
 ├─ Caddy (Let's Encrypt, rate-limit 60/min/IP):
 │   ├─ mcp.splitphp.org:443 → 127.0.0.1:3001,  injects Bearer {$MCP_KEY}
 │   └─ api.splitphp.org:443 → 127.0.0.1:27123, injects Bearer {$REST_KEY};
 │        allowlist GET /vault/* only (403 otherwise), CORS → https://splitphp.org
 └─ systemd timer → git pull --ff-only every 15min (the vault auto-updates from this repo)
```
The public hits Caddy **without auth**; Caddy injects the internal apiKey → Obsidian is never exposed
directly. The MCP's `readOnlyMode` is enforced **server-side**; the REST plugin is write-capable, so its
write surface is fenced off **at Caddy** (only `GET /vault/*` reaches it). **No secrets** in the vault.

## Contents

- `Caddyfile` — the `mcp.splitphp.org` + `api.splitphp.org` vhosts (use `{$MCP_KEY}` / `{$REST_KEY}` from
  the env; no secret in the file).
- `systemd/` — `xvfb.service`, `obsidian-vault.service`, `caddy.service`, `vault-pull.service` + `.timer`.
- `scripts/obsidian-run.sh` — launches Obsidian and **disables Restricted Mode via CDP** (otherwise the
  plugins won't load). `scripts/cdp.py` — a minimal CDP client (stdlib only). `scripts/provision.sh` — the provisioner.
- `obsidian-skeleton/` — the vault config `.json` files (community/core-plugins, app, appearance). **Plugin
  code (main.js/manifest.json/styles.css) is NOT versioned** (third-party). `semantic-vault-mcp` comes from
  <https://github.com/aaronsb/semantic-vault-mcp> (place it under `obsidian-skeleton/plugins/semantic-vault-mcp/`
  or directly into the vault before provisioning); `obsidian-local-rest-api` is fetched automatically by
  `provision.sh` from its public GitHub release.

## Provision (from scratch)

Prerequisites: an Ubuntu 24.04 **arm64** EC2 + Elastic IP; a **Security Group** with inbound `443`+`80`
← 0.0.0.0/0 (443 = MCP + REST, 80 = ACME challenge) and `22` restricted to your IP; **DNS** A records
`mcp.splitphp.org` **and** `api.splitphp.org` → the Elastic IP.

```sh
git clone https://github.com/splitphp/Docs.git ~/vault
bash ~/vault/infra/scripts/provision.sh
# verify (once the certs are issued):
curl -s -o /dev/null -w '%{http_code}\n' https://mcp.splitphp.org/mcp          # 400 = ok (MCP endpoint, internal auth)
curl -s -o /dev/null -w '%{http_code}\n' https://api.splitphp.org/vault/       # 200 = ok (folder listing)
curl -s -o /dev/null -w '%{http_code}\n' https://api.splitphp.org/             # 403 = ok (only GET /vault/* allowed)
```

## Keys / secrets

Two plugin `apiKey`s are generated during provisioning: `/etc/mcp.key` and `/etc/rest.key` (mirrored into
`/etc/caddy/mcp.env` as `MCP_KEY` / `REST_KEY`) **on the instance** — never in this repo. The root
`.gitignore` excludes `.obsidian/` (which holds the `data.json` files with the keys). The vault is
**pull-only**: the instance never commits/pushes.

## Notes

- A `t4g.nano` (ARM, ~408MB) is enough (real workload ~150MB) **with the 2GB swap**. If it OOMs under
  load, bump to `t4g.micro`.
- Always re-clone / re-point with clone-to-temp + atomic swap (`provision.sh` already does this).
