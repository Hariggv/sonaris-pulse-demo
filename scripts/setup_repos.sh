#!/bin/bash
# Align GitHub repos: sonaris-pulse-demo (PUBLIC) + sonaris-pulse-main (PRIVATE)
set -euo pipefail

OWNER="${GITHUB_OWNER:-Hariggv}"
DEMO_REPO="sonaris-pulse-demo"
MAIN_REPO="sonaris-pulse-main"
LEGACY_DEMO="Sonaris"
LEGACY_MAIN="sonaris-pulse-private"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PULSE="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v gh >/dev/null; then
  echo "Install: brew install gh && gh auth login"
  exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Sonaris Pulse — two-repo setup                              ║"
echo "║  PUBLIC:  $OWNER/$DEMO_REPO  (marketing demo)               ║"
echo "║  PRIVATE: $OWNER/$MAIN_REPO  (full development)             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

_repo_exists() {
  gh repo view "$OWNER/$1" >/dev/null 2>&1
}

_rename_if_exists() {
  local old="$1" new="$2"
  if _repo_exists "$old" && ! _repo_exists "$new"; then
    echo "→ Renaming $old → $new"
    gh repo rename "$new" --repo "$OWNER/$old" --yes
  elif _repo_exists "$new"; then
    echo "✓ $new already exists"
  else
    echo "· $old not found (skip rename)"
  fi
}

_create_demo() {
  if _repo_exists "$DEMO_REPO"; then
    echo "✓ Demo repo exists: $OWNER/$DEMO_REPO"
    gh repo edit "$OWNER/$DEMO_REPO" --visibility public --accept-visibility-change-consequences 2>/dev/null || true
    return
  fi
  echo "→ Creating public demo repo: $DEMO_REPO"
  gh repo create "$DEMO_REPO" --public --description "Sonaris Pulse — public marketing demo (static, mock data)"
}

_create_main() {
  if _repo_exists "$MAIN_REPO"; then
    echo "✓ Main repo exists: $OWNER/$MAIN_REPO"
    gh repo edit "$OWNER/$MAIN_REPO" --visibility private --accept-visibility-change-consequences 2>/dev/null || true
    return
  fi
  echo "→ Creating private main repo: $MAIN_REPO"
  gh repo create "$MAIN_REPO" --private --description "Sonaris Pulse — internal development (CONFIDENTIAL)"
}

echo "Step 1: Rename legacy repos (if present)"
_rename_if_exists "$LEGACY_MAIN" "$MAIN_REPO"
_rename_if_exists "$LEGACY_DEMO" "$DEMO_REPO"

echo ""
echo "Step 2: Ensure repos exist with correct visibility"
_create_main
_create_demo

echo ""
echo "Step 3: Configure local git remotes"
cd "$ROOT"

if [ -d .git ]; then
  # demo = public static pushes (optional separate clone)
  if git remote get-url demo >/dev/null 2>&1; then
    git remote set-url demo "https://github.com/$OWNER/$DEMO_REPO.git"
  else
    git remote add demo "https://github.com/$OWNER/$DEMO_REPO.git" 2>/dev/null || true
  fi

  # main = private full source
  if git remote get-url main >/dev/null 2>&1; then
    git remote set-url main "https://github.com/$OWNER/$MAIN_REPO.git"
  elif git remote get-url private >/dev/null 2>&1; then
    git remote rename private main 2>/dev/null || git remote set-url private "https://github.com/$OWNER/$MAIN_REPO.git"
  else
    git remote add main "https://github.com/$OWNER/$MAIN_REPO.git"
  fi

  # origin → point at demo for Pages workflow, or main for dev — user chooses
  if git remote get-url origin >/dev/null 2>&1; then
    echo "  origin  → $(git remote get-url origin)"
  fi
  echo "  demo    → https://github.com/$OWNER/$DEMO_REPO.git"
  echo "  main    → https://github.com/$OWNER/$MAIN_REPO.git"
fi

echo ""
echo "Step 4: Visibility check"
gh repo view "$OWNER/$DEMO_REPO" --json name,visibility,isInOrganization -q '"Demo: \(.name) = \(.visibility)"' 2>/dev/null || echo "Demo repo: create manually"
gh repo view "$OWNER/$MAIN_REPO" --json name,visibility -q '"Main: \(.name) = \(.visibility)"' 2>/dev/null || echo "Main repo: create manually"

cat <<EOF

╔══════════════════════════════════════════════════════════════╗
║  Setup complete                                              ║
╚══════════════════════════════════════════════════════════════╝

NEXT — push full source to PRIVATE main:
  cd "$PULSE"
  git add .
  git commit -m "chore: sonaris-pulse-main development" || true
  git push main main

NEXT — push static demo to PUBLIC demo:
  bash "$PULSE/scripts/publish_demo.sh"

Pages URL (after demo deploy):
  https://${OWNER,,}.github.io/$DEMO_REPO/

EOF