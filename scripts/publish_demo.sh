#!/bin/bash
# Build mock demo and publish to PUBLIC sonaris-pulse-demo repo.
set -euo pipefail

OWNER="${GITHUB_OWNER:-Hariggv}"
DEMO_REPO="sonaris-pulse-demo"
PULSE="$(cd "$(dirname "$0")/.." && pwd)"
SONARIS_ROOT="$(cd "$PULSE/.." && pwd)"
EXPORT_DIR="${EXPORT_DIR:-$SONARIS_ROOT/sonaris-pulse-demo-export}"
BASE_HREF="${BASE_HREF:-/$DEMO_REPO/}"

cd "$PULSE"

if [ -f pubspec.yaml ]; then
  echo "=== Building demo from Flutter source ==="
  chmod +x scripts/*.sh 2>/dev/null || true
  if [ -f scripts/build_demo.sh ]; then
    BASE_HREF="$BASE_HREF" bash scripts/build_demo.sh
  else
    flutter pub get
    flutter build web --release \
      --base-href "$BASE_HREF" \
      --dart-define=APP_ENV=demo \
      --dart-define=DEMO_MODE=true \
      --pwa-strategy=none \
      --no-wasm-dry-run
  fi
  BUILD_SRC="$PULSE/build/web"
elif [ -f main.dart.js ]; then
  echo "=== Using existing static build in Sonaris Pulse/ ==="
  BUILD_SRC="$PULSE"
else
  echo "ERROR: No pubspec.yaml or main.dart.js found in $PULSE"
  exit 1
fi

mkdir -p "$EXPORT_DIR"
rm -rf "$EXPORT_DIR"/*
cp -R "$BUILD_SRC/." "$EXPORT_DIR/"
touch "$EXPORT_DIR/.nojekyll"

# Pages workflow for demo repo (app at root)
mkdir -p "$EXPORT_DIR/.github/workflows"
cat > "$EXPORT_DIR/.github/workflows/deploy-pages.yml" <<'YAML'
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: pages
  cancel-in-progress: true
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
      - run: test -f main.dart.js
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: .
      - id: deployment
        uses: actions/deploy-pages@v4
YAML

cp "$SONARIS_ROOT/REPOS.md" "$EXPORT_DIR/README.md" 2>/dev/null || \
  echo "# Sonaris Pulse Demo\n\nPublic marketing demo. Mock data only." > "$EXPORT_DIR/README.md"

echo ""
echo "Export ready: $EXPORT_DIR"
echo ""

if ! command -v gh >/dev/null; then
  echo "Push manually:"
  echo "  cd $EXPORT_DIR && git init -b main && git add . && git commit -m 'chore: demo release'"
  echo "  git remote add origin https://github.com/$OWNER/$DEMO_REPO.git"
  echo "  git push -u origin main"
  exit 0
fi

cd "$EXPORT_DIR"
[ -d .git ] || git init -b main
git add .
git commit -m "chore: demo release $(date +%Y-%m-%d)" || true

REMOTE="https://github.com/$OWNER/$DEMO_REPO.git"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE"
else
  git remote add origin "$REMOTE"
fi

if [ "${CONFIRM_PUSH:-}" = "yes" ]; then
  git push -u origin main --force
  OWNER_LC=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')
  echo "Pushed. Enabling Pages..."
  bash "$PULSE/scripts/enable_demo_pages.sh" 2>/dev/null || true
  echo "Live (after deploy): https://${OWNER_LC}.github.io/$DEMO_REPO/"
else
  echo "Review $EXPORT_DIR then:"
  echo "  CONFIRM_PUSH=yes bash $PULSE/scripts/publish_demo.sh"
fi