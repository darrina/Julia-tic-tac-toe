#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_PID=""
FRONTEND_PID=""

cleanup() {
  trap - EXIT INT TERM

  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    kill "$BACKEND_PID" 2>/dev/null || true
  fi

  if [[ -n "$FRONTEND_PID" ]] && kill -0 "$FRONTEND_PID" 2>/dev/null; then
    kill "$FRONTEND_PID" 2>/dev/null || true
  fi

  wait "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

echo "Starting Julia backend on http://localhost:8080 ..."
(
  cd "$ROOT_DIR/backend"
  julia run.jl
) &
BACKEND_PID=$!

echo "Starting Next.js frontend on http://localhost:3000 ..."
(
  cd "$ROOT_DIR/frontend"

  if [[ ! -d node_modules ]]; then
    echo "Installing frontend dependencies ..."
    npm install
  fi

  npm run dev
) &
FRONTEND_PID=$!

wait -n "$BACKEND_PID" "$FRONTEND_PID"

echo "One of the services exited. Stopping the other service ..."
exit 1
