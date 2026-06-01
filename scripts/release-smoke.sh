#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-all}"

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

run_web() {
  echo "==> Running web smoke"
  (
    cd "$ROOT_DIR/uygulamalar/web"
    npm run test:e2e
  )
}

run_web_live() {
  echo "==> Running web live canonical smoke"
  require_env "NEXT_PUBLIC_SUPABASE_URL"
  require_env "NEXT_PUBLIC_SUPABASE_ANON_KEY"
  require_env "SUPABASE_SERVICE_ROLE_KEY"
  require_env "PLAYWRIGHT_SMOKE_BUSINESS_ID"
  require_env "PLAYWRIGHT_SMOKE_BUSINESS_PATH"
  (
    cd "$ROOT_DIR/uygulamalar/web"
    PLAYWRIGHT_REQUIRE_CANONICAL_REDIRECT="${PLAYWRIGHT_REQUIRE_CANONICAL_REDIRECT:-true}" \
      npm run test:e2e:live
  )
}

case "$TARGET" in
  all)
    run_web
    ;;
  web)
    run_web
    ;;
  web-live)
    run_web_live
    ;;
  *)
    echo "Usage: scripts/release-smoke.sh [all|web|web-live]" >&2
    exit 1
    ;;
esac
