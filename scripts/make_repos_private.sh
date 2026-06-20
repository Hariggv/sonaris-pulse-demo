#!/bin/bash
# Make ONLY sonaris-pulse-main private. Keep sonaris-pulse-demo PUBLIC.
set -euo pipefail

OWNER="${GITHUB_OWNER:-Hariggv}"
DEMO_REPO="sonaris-pulse-demo"
MAIN_REPO="sonaris-pulse-main"

if ! command -v gh >/dev/null; then
  echo "Install: brew install gh && gh auth login"
  exit 1
fi

echo "=== Repo visibility policy ==="
echo "  PUBLIC:  $OWNER/$DEMO_REPO"
echo "  PRIVATE: $OWNER/$MAIN_REPO"
echo ""

if gh repo view "$OWNER/$DEMO_REPO" >/dev/null 2>&1; then
  echo "→ Ensuring demo is PUBLIC"
  gh repo edit "$OWNER/$DEMO_REPO" --visibility public --accept-visibility-change-consequences
  echo "✓ $DEMO_REPO is public"
else
  echo "! $DEMO_REPO not found — run: bash scripts/setup_repos.sh"
fi

if gh repo view "$OWNER/$MAIN_REPO" >/dev/null 2>&1; then
  echo "→ Ensuring main is PRIVATE"
  gh repo edit "$OWNER/$MAIN_REPO" --visibility private --accept-visibility-change-consequences
  echo "✓ $MAIN_REPO is private"
else
  echo "! $MAIN_REPO not found — run: bash scripts/setup_repos.sh"
fi

echo ""
echo "Done. Demo stays public; main stays private."