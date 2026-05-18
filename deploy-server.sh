#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
LOCAL_URL="http://127.0.0.1:${PORT}"
export HOST PORT

echo "== Claude Web single-user server deploy =="
echo "project: ${PROJECT_DIR}"
echo "listen:  ${HOST}:${PORT}"

chmod +x install.sh start-local.sh scripts/smoke_test.py 2>/dev/null || true

echo "== install runtime =="
BOOTSTRAP_INSTALL_NGROK="${BOOTSTRAP_INSTALL_NGROK:-0}" ./install.sh

echo "== compile check =="
".venv/bin/python" -m py_compile app.py db.py config.py schemas.py chat_utils.py services.py

echo "== start service =="
START_PUBLIC="${START_PUBLIC:-0}" HOST="${HOST}" PORT="${PORT}" ./start-local.sh

echo "== health check =="
for _ in 1 2 3 4 5; do
  if curl -fsS "${LOCAL_URL}/api/health" >/dev/null 2>&1; then
    echo "health: ok"
    break
  fi
  sleep 1
done

curl -fsS "${LOCAL_URL}/api/health" >/dev/null

echo "== smoke test =="
".venv/bin/python" scripts/smoke_test.py "${LOCAL_URL}"

echo "== done =="
echo "local:  ${LOCAL_URL}"
echo "public: http://<server-ip>:${PORT}/"
