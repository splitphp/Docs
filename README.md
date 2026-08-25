# SplitPHP — Documentação oficial

Documentação oficial do framework **SplitPHP**, versionada como um vault Obsidian e servida ao mundo,
read-only, por um servidor **MCP** (Model Context Protocol) — para que qualquer assistente de IA (e o
dev-bot da Lambda TT) possa buscar e ler a doc semanticamente.

- **MCP público:** `https://mcp.splitphp.org/mcp` (read-only, sem auth para o público).
- Futuro: uma **REST API** (`api.splitphp.org`) + um **SPA** de docs no apex `splitphp.org` renderizando
  o Markdown.

## Estrutura do repo

```
.
├── vault/     # o conteúdo da doc (vault Obsidian: .md em pastas numeradas 001-…/014-…)
└── infra/     # como servir o vault como MCP público (Caddy + Obsidian headless + systemd) — ver infra/README.md
```

- **`vault/`** é a fonte de verdade da documentação. Edite os `.md` aqui e faça `push`.
- A EC2 de produção faz `git pull` deste repo a cada 15 min e re-indexa automaticamente — ou seja,
  **o que entra em `vault/` no `master` vira doc publicada** em poucos minutos.
- `.obsidian/` (config local do Obsidian, incl. a chave do servidor) é **gitignored** — não versione.

## Contribuindo com a doc

1. Edite/adicione `.md` em `vault/` (mantendo o padrão de pastas numeradas).
2. `git commit` + `git push` no `master`.
3. Em até ~15 min a EC2 puxa e a doc fica disponível via MCP (e, no futuro, no site).

## Servindo (infra)

Todo o provisionamento do servidor está em [`infra/`](infra/README.md) — reprodutível do zero com
`infra/scripts/provision.sh` numa EC2 Ubuntu 24.04 arm64. Detalhes de arquitetura, requisitos (DNS/SG) e
segredos: ver [infra/README.md](infra/README.md).
