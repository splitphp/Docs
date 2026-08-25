#!/usr/bin/env bash
# Provisions the EC2 that serves this documentation as a public read-only MCP at mcp.splitphp.org.
# Reproduces the setup: headless Obsidian (xvfb) + semantic-vault-mcp plugin (readOnlyMode) behind
# Caddy (Let's Encrypt), with a git pull of the vault every 15 min.
#
# Target: Ubuntu 24.04 **arm64** (e.g. t4g.nano). Run as the `ubuntu` user.
# Prerequisites (outside this script): a Security Group with 80/443 open to the world + 22 restricted to
# your IP; a DNS A record `mcp.splitphp.org` → the instance's public (Elastic) IP.
#
# Usage:  git clone https://github.com/splitphp/Docs.git ~/vault && bash ~/vault/infra/scripts/provision.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"        # the infra/ dir
REPO_URL="https://github.com/splitphp/Docs.git"
CLONE="$HOME/vault"; VAULT="$CLONE/vault"        # the Obsidian vault is the vault/ subfolder
DOMAIN="mcp.splitphp.org"
OBS_VER="${OBS_VER:-1.13.7}"
PLUGIN_DIR="$VAULT/.obsidian/plugins/semantic-vault-mcp"

echo "== 1/10 2GB swapfile (t4g.nano has only ~408MB) =="
if ! sudo swapon --show | grep -q /swapfile; then
  sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
  grep -q /swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

echo "== 2/10 deps (Electron + xvfb) =="
sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  xvfb python3 curl ca-certificates procps git \
  libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 libdrm2 libxkbcommon0 libxcomposite1 \
  libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2t64 libgtk-3-0t64 libsecret-1-0 xdg-utils

echo "== 3/10 Obsidian arm64 ($OBS_VER) → /opt/obsidian =="
if [ ! -x /usr/local/bin/obsidian ]; then
  curl -fL --retry 3 -o /tmp/obs.tgz \
    "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBS_VER}/obsidian-${OBS_VER}-arm64.tar.gz"
  sudo rm -rf /opt/obsidian && sudo mkdir -p /opt/obsidian && sudo tar -C /opt/obsidian -xzf /tmp/obs.tgz && rm -f /tmp/obs.tgz
  sudo ln -sf "$(sudo find /opt/obsidian -maxdepth 2 -type f -name obsidian | head -1)" /usr/local/bin/obsidian
fi

echo "== 4/10 Caddy arm64 with the rate_limit module → /usr/local/bin/caddy =="
if [ ! -x /usr/local/bin/caddy ]; then
  curl -fL --retry 3 -o /tmp/caddy "https://caddyserver.com/api/download?os=linux&arch=arm64&p=github.com/mholt/caddy-ratelimit"
  sudo mv /tmp/caddy /usr/local/bin/caddy && sudo chmod +x /usr/local/bin/caddy
fi

echo "== 5/10 clone the vault (temp + atomic swap — NEVER rm before a clone) =="
if [ ! -d "$CLONE/.git" ]; then
  rm -rf "$HOME/vault.new"
  git clone --depth 1 "$REPO_URL" "$HOME/vault.new"
  [ "$(find "$HOME/vault.new/vault" -name '*.md' 2>/dev/null | wc -l)" -ge 1 ] || { echo "FATAL: vault/ empty in the clone"; exit 1; }
  [ -e "$CLONE" ] && mv "$CLONE" "$HOME/vault.old.$$"
  mv "$HOME/vault.new" "$CLONE"
  rm -rf "$HOME/vault.old.$$" 2>/dev/null || true
  HERE="$CLONE/infra"   # from here on, infra/ lives inside the clone
fi

echo "== 6/10 semantic-vault-mcp plugin + .obsidian skeleton =="
# The plugin (main.js/manifest.json/styles.css) is third-party and NOT versioned here. Get it from
# https://github.com/aaronsb/semantic-vault-mcp (or copy from an existing Obsidian install) and place it
# under infra/obsidian-skeleton/plugins/semantic-vault-mcp/ before running, OR copy it into PLUGIN_DIR by hand.
mkdir -p "$PLUGIN_DIR"
cp "$HERE"/obsidian-skeleton/*.json "$VAULT/.obsidian/" 2>/dev/null || true
if [ -f "$HERE/obsidian-skeleton/plugins/semantic-vault-mcp/main.js" ]; then
  cp "$HERE"/obsidian-skeleton/plugins/semantic-vault-mcp/* "$PLUGIN_DIR/"
elif [ ! -f "$PLUGIN_DIR/main.js" ]; then
  echo "WARNING: semantic-vault-mcp plugin missing — put main.js/manifest.json/styles.css in $PLUGIN_DIR"
fi

echo "== 7/10 apiKey + data.json (readOnlyMode, loopback) =="
if [ ! -f /etc/mcp.key ]; then
  umask 077
  openssl rand -base64 36 | tr -d '\n/+=' | cut -c1-48 | sudo tee /etc/mcp.key >/dev/null
  sudo chmod 600 /etc/mcp.key
fi
umask 077
KEY="$(sudo cat /etc/mcp.key)" python3 - "$PLUGIN_DIR/data.json" <<'PY'
import json, os, sys
json.dump({
  "httpEnabled": True, "httpPort": 3001, "httpsEnabled": False,
  "bindMode": "loopback", "customBindHost": "",
  "hasShownBindMigrationNotice": True, "debugLogging": False,
  "showConnectionStatus": False, "autoDetectPortConflicts": True,
  "apiKey": os.environ["KEY"], "dangerouslyDisableAuth": False,
  "readOnlyMode": True, "pathExclusionsEnabled": False,
  "enableIgnoreContextMenu": False, "toolVisibility": {},
}, open(sys.argv[1], "w"), ensure_ascii=False, indent=2)
PY

echo "== 8/10 register the vault in the Obsidian profile =="
mkdir -p "$HOME/.config/obsidian"
VAULT="$VAULT" python3 - <<'PY'
import json, os, hashlib
p = os.environ["VAULT"]; vid = hashlib.md5(p.encode()).hexdigest()[:16]
json.dump({"vaults": {vid: {"path": p, "ts": 1, "open": True}}},
          open(os.path.expanduser("~/.config/obsidian/obsidian.json"), "w"))
PY

echo "== 9/10 scripts + Caddy config =="
cp "$HERE/scripts/obsidian-run.sh" "$HOME/obsidian-run.sh" && chmod +x "$HOME/obsidian-run.sh"
cp "$HERE/scripts/cdp.py" "$HOME/cdp.py"
sudo mkdir -p /etc/caddy
sudo cp "$HERE/Caddyfile" /etc/caddy/Caddyfile
printf 'MCP_KEY=%s\n' "$(sudo cat /etc/mcp.key)" | sudo tee /etc/caddy/mcp.env >/dev/null
sudo chmod 600 /etc/caddy/mcp.env

echo "== 10/10 systemd units =="
sudo cp "$HERE"/systemd/*.service "$HERE"/systemd/*.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now xvfb.service obsidian-vault.service caddy.service vault-pull.timer

echo
echo "Done. Verify (after DNS/SG are ready and the cert is issued):"
echo "  curl -s -o /dev/null -w '%{http_code}\\n' https://$DOMAIN/mcp   # expect 400"
