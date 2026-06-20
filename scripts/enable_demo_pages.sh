#!/bin/bash
# Enable GitHub Pages on sonaris-pulse-demo and trigger deploy.
set -euo pipefail

OWNER="${GITHUB_OWNER:-Hariggv}"
DEMO_REPO="sonaris-pulse-demo"

if ! command -v gh >/dev/null; then
  echo "Install: brew install gh && gh auth login"
  exit 1
fi

echo "=== Enabling GitHub Pages on $OWNER/$DEMO_REPO ==="

# Ensure Pages uses GitHub Actions (not legacy branch deploy)
gh api "repos/$OWNER/$DEMO_REPO/pages" -X POST \
  -f build_type=workflow 2>/dev/null || \
gh api "repos/$OWNER/$DEMO_REPO/pages" -X PUT \
  -f build_type=workflow 2>/dev/null || \
echo "Pages may already be configured — check Settings → Pages"

echo ""
echo "=== Repo status ==="
gh repo view "$OWNER/$DEMO_REPO" --json name,visibility,url -q '"\(.name) (\(.visibility)) \(.url)"'

echo ""
echo "=== Workflows ==="
gh workflow list --repo "$OWNER/$DEMO_REPO" 2>/dev/null || echo "No workflows yet — push publish_demo.sh first"

echo ""
echo "=== Trigger deploy ==="
if gh workflow list --repo "$OWNER/$DEMO_REPO" --json name -q '.[].name' 2>/dev/null | grep -q "Deploy"; then
  gh workflow run "Deploy to GitHub Pages" --repo "$OWNER/$DEMO_REPO" --ref main
  echo "Workflow triggered. Watch:"
  echo "  gh run watch --repo $OWNER/$DEMO_REPO"
  echo "  https://github.com/$OWNER/$DEMO_REPO/actions"
else
  echo "ERROR: No deploy workflow on remote. Run:"
  echo "  CONFIRM_PUSH=yes bash Sonaris\\ Pulse/scripts/publish_demo.sh"
fi

OWNER_LC=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')
echo ""
echo "After green check (~1 min):"
echo "  https://${OWNER_LC}.github.io/${DEMO_REPO}/"