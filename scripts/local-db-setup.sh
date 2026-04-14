#!/usr/bin/env bash
# ─── Yeedoy Local Supabase Setup ─────────────────────────────────────────────
# Runs from repo root. Starts local Supabase stack and applies all migrations.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Starting local Supabase stack..."
supabase start

echo ""
echo "==> Applying migrations..."
supabase db push --local

echo ""
echo "==> Local stack is ready."
echo ""
supabase status
echo ""
echo "Copy the values above into your .env files (see instructions in README or docs/LOCAL_DEV.md)"
