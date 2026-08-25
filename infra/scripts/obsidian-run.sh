#!/usr/bin/env bash
export HOME=/home/ubuntu
export DISPLAY=:99
/usr/local/bin/obsidian --no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-port=9222 &
OBS=$!
# wait for the debug channel and disable Restricted Mode (idempotent; persists in the app profile)
until curl -sf -m 2 http://127.0.0.1:9222/json/list >/dev/null 2>&1; do sleep 1; done
sleep 3
python3 /home/ubuntu/cdp.py 'app.plugins.isEnabled() ? "already-on" : app.plugins.setEnable(true).then(()=>"enabled-now")' >/dev/null 2>&1 || true
wait $OBS
