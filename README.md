# SplitPHP — Official Documentation

Official documentation for the **SplitPHP** framework, versioned as an Obsidian vault and served to the
world, read-only, through an **MCP** (Model Context Protocol) server — so any AI assistant (and Lambda
TT's dev-bot) can search and read the docs semantically.

- **Public MCP:** `https://mcp.splitphp.org/mcp` (read-only, no auth for the public).
- Future: a **REST API** (`api.splitphp.org`) plus a docs **SPA** at the apex `splitphp.org` rendering
  the Markdown.

## Repository layout

```
.
├── vault/     # the documentation content (Obsidian vault: .md in numbered folders 001-…/014-…)
└── infra/     # how the vault is served as a public MCP (Caddy + headless Obsidian + systemd) — see infra/README.md
```

- **`vault/`** is the source of truth for the docs. Edit the `.md` here and push.
- The production EC2 runs `git pull` on this repo every 15 min and re-indexes automatically — i.e.,
  **whatever lands in `vault/` on `master` becomes published docs** within a few minutes.
- `.obsidian/` (local Obsidian config, incl. the server key) is **gitignored** — do not commit it.

## Contributing to the docs

1. Edit/add `.md` files under `vault/` (keeping the numbered-folder convention).
2. `git commit` + `git push` to `master`.
3. Within ~15 min the EC2 pulls and the docs become available over MCP (and, later, on the site).

## Serving (infra)

All server provisioning lives in [`infra/`](infra/README.md) — reproducible from scratch with
`infra/scripts/provision.sh` on an Ubuntu 24.04 arm64 EC2. Architecture, requirements (DNS/SG) and
secrets: see [infra/README.md](infra/README.md).
