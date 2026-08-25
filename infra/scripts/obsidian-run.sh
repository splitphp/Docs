#!/usr/bin/env bash
export HOME=/home/ubuntu
export DISPLAY=:99
/usr/local/bin/obsidian --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-port=9222 &
OBS=$!
# espera o canal de depuração e destrava o Modo Restrito (idempotente; persiste no perfil)
until curl -sf -m 2 http://127.0.0.1:9222/json/list >/dev/null 2>&1; do sleep 1; done
sleep 3
python3 /home/ubuntu/cdp.py 'app.plugins.isEnabled() ? "ja-ligado" : app.plugins.setEnable(true).then(()=>"ligado-agora")' >/dev/null 2>&1 || true
wait $OBS
