# Sonaris Pulse — Repository Layout

Two repositories. No overlap in purpose.

| Repo | Visibility | What it is | Who uses it |
|------|------------|------------|-------------|
| **[sonaris-pulse-demo](https://github.com/Hariggv/sonaris-pulse-demo)** | **Public** | Yesterday's marketing demo — static web only, mock data | Visitors, recruiters, customers |
| **[sonaris-pulse-main](https://github.com/Hariggv/sonaris-pulse-main)** | **Private** | Today's full product — Flutter, API, Sonaris Core SDK, Firebase | You and your team only |

## Legacy names (migrate away)

| Old name | New name |
|----------|----------|
| `Hariggv/Sonaris` | → `sonaris-pulse-demo` (public) |
| `Hariggv/sonaris-pulse-private` | → `sonaris-pulse-main` (private) |

## URLs

| Surface | URL |
|---------|-----|
| Public demo (after migration) | https://hariggv.github.io/sonaris-pulse-demo/ |
| Local internal dev | http://localhost:8080 (`bash deploy_local.sh` in main repo) |

## Local folders

```
Desktop/Sonaris Pulse/Sonaris/
├── Sonaris Pulse/          ← work here (clone of sonaris-pulse-main)
├── sonaris-pulse-public/   ← static export staging (push → demo repo)
└── REPOS.md                ← this file
```

## Daily workflow

```
sonaris-pulse-main (private)     develop → commit → push
        ↓
   build demo (mock mode)
        ↓
sonaris-pulse-demo (public)      static files only → push → GitHub Pages
```

## Never put in the demo repo

- `backend/`
- `packages/sonaris_core/`
- `lib/` source (only compiled `main.dart.js`)
- `firebase_options.dart`
- `.env` / databases

## One-time setup

```bash
cd "/Users/haritashtamvada/Desktop/Sonaris Pulse/Sonaris"
bash "Sonaris Pulse/scripts/setup_repos.sh"
```