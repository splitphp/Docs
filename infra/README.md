# infra/ — servir esta doc como MCP público read-only

Provisiona a EC2 que expõe o conteúdo de [`../vault/`](../vault) como **MCP público read-only** em
**`https://mcp.splitphp.org/mcp`** — consumível por qualquer cliente MCP/IA (e pelo dev-bot da Lambda TT).

```
EC2 (t4g.nano arm64, Ubuntu 24.04, swap 2GB)
 ├─ Obsidian headless (xvfb) abrindo o vault  ../vault
 │   └─ plugin semantic-vault-mcp → readOnlyMode:true, loopback :3001, apiKey (só p/ o Caddy)
 ├─ Caddy → mcp.splitphp.org:443 (Let's Encrypt), rate-limit 60/min/IP
 │           reverse_proxy → 127.0.0.1:3001, injeta Authorization: Bearer {$MCP_KEY}
 └─ systemd timer → git pull --ff-only a cada 15min (o vault se auto-atualiza deste repo)
```
O público bate no Caddy **sem auth**; o Caddy injeta a apiKey interna → o Obsidian nunca fica exposto cru.
`readOnlyMode` é imposto **no servidor** (escrita bloqueada pra todos). **Nenhum segredo** no vault.

## Conteúdo

- `Caddyfile` — vhost `mcp.splitphp.org` (usa `{$MCP_KEY}` do env; sem segredo no arquivo).
- `systemd/` — `xvfb.service`, `obsidian-vault.service`, `caddy.service`, `vault-pull.service` + `.timer`.
- `scripts/obsidian-run.sh` — sobe o Obsidian e **destrava o Modo Restrito via CDP** (senão o plugin não
  carrega). `scripts/cdp.py` — cliente CDP mínimo (stdlib). `scripts/provision.sh` — o provisionador.
- `obsidian-skeleton/` — os `.json` de config do vault (community/core-plugins, app, appearance). **O
  plugin em si (main.js/manifest.json/styles.css) NÃO é versionado** (third-party). Obtenha em
  <https://github.com/aaronsb/semantic-vault-mcp> e coloque em
  `obsidian-skeleton/plugins/semantic-vault-mcp/` (ou direto no vault) antes de provisionar.

## Provisionar (do zero)

Pré-requisitos: EC2 Ubuntu 24.04 **arm64** + Elastic IP; **SG** inbound `443`+`80`←0.0.0.0/0 (443 = MCP,
80 = desafio ACME) e `22` restrito ao seu IP; **DNS** A `mcp.splitphp.org` → Elastic IP.

```sh
git clone https://github.com/splitphp/Docs.git ~/vault
bash ~/vault/infra/scripts/provision.sh
# verifica (após o cert emitir):
curl -s -o /dev/null -w '%{http_code}\n' https://mcp.splitphp.org/mcp    # 400 = ok (auth interna + endpoint MCP)
```

## Chaves / segredos

A `apiKey` do plugin é gerada no provisionamento e mora em `/etc/mcp.key` (+ `/etc/caddy/mcp.env` como
`MCP_KEY`) **na instância** — nunca neste repo. O `.gitignore` da raiz ignora `.obsidian/` (que contém o
`data.json` com a chave). O vault é **pull-only**: a instância nunca faz commit/push.

## Notas

- Instância `t4g.nano` (ARM, ~408MB) é suficiente (workload real ~150MB) **com o swap de 2GB**. Se der
  OOM sob carga, subir pra `t4g.micro`.
- Re-clonar/re-apontar SEMPRE com clone-em-temp + swap atômico (o `provision.sh` já faz isso).
