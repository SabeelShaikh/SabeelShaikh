#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/workspace/Ecommerce-Website-main"
API_PORT=5050
CLIENT_PORT=5173

if [[ ! -d "${APP_DIR}/server" ]]; then
  echo "Ecommerce app not installed; run install first." >&2
  exit 1
fi

if ! tmux has-session -t ecommerce_api 2>/dev/null; then
  tmux new-session -d -s ecommerce_api \
    "cd ${APP_DIR}/server && node server.js 2>&1 | tee /tmp/ecommerce-api.log"
fi

for _ in $(seq 1 60); do
  if curl -sf "http://127.0.0.1:${API_PORT}/api" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! curl -sf "http://127.0.0.1:${API_PORT}/api" >/dev/null 2>&1; then
  echo "API server did not become ready on port ${API_PORT}" >&2
  tail -n 50 /tmp/ecommerce-api.log 2>/dev/null || true
  exit 1
fi

if ! tmux has-session -t ecommerce_client 2>/dev/null; then
  tmux new-session -d -s ecommerce_client \
    "cd ${APP_DIR}/client && npm run dev -- --host 0.0.0.0 --port ${CLIENT_PORT} 2>&1 | tee /tmp/ecommerce-client.log"
fi

for _ in $(seq 1 90); do
  if curl -sf "http://127.0.0.1:${CLIENT_PORT}/" >/dev/null 2>&1; then
    exit 0
  fi
  sleep 1
done

echo "Vite dev server did not become ready on port ${CLIENT_PORT}" >&2
tail -n 50 /tmp/ecommerce-client.log 2>/dev/null || true
exit 1
