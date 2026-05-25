# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Termux URL opener for Android. Android Intent invokes `termux-url-opener "$url"`, which fetches OGP via the bundled `ogp` ARM64 binary and routes the result to one of three backends: Notion, Google Keep, or Google Tasks (`gog` CLI). Optionally summarizes via Gemini CLI before saving.

Setup details (gemini install, building `gog` for android arm, gogcli auth) live in `README.md` — read it before recommending setup changes.

## Target environment

Scripts run on Termux on Android, not desktop Linux:
- Main script shebang is `#!/data/data/com.termux/files/usr/bin/bash` (hard-coded path). Do not change it.
- External commands are wrapped with `termux-chroot` so they see a normal Linux FS layout. Keep this wrapping when editing `to_notion` / `to_gtasks` / `main`.
- DNS workaround: `setup_and_check` writes `nameserver 8.8.8.8` into the chroot's `/etc/resolv.conf` if missing. Don't remove it.
- Scripts can't be run/tested locally on dev machine — verification is "scp and run on device."

## Deploy commands

No CI, no tests. Deployment is `scp` over SSH to a host alias `termux`:
- `make deploy` (default) — `.env`, `cookies.json`, `termux-url-opener` only. Use for code changes to the main script.
- `make deploy-keys` — `.env`, `cookies.json` only. Use when only env/credentials changed.
- `make deploy-all` — everything: main script + mode switchers (`k`/`n`/`g`) + `gog-reauth` + `ogp` binary + `prompt.md`. Use for first-time setup or when any auxiliary file changed.

Pick the narrowest target — `deploy-all` re-ships the ARM64 `ogp` binary every time.

## Mode switching

`mode=notion|keep|gtasks` in `.env` selects the backend. The three single-letter scripts mutate `.env` in place:
- `k` → sets `mode=keep`
- `n` → sets `mode=gtasks` (not "notion" — naming is historical)
- `g` → sets `mode=notion`

They `sed -i '/^export mode=.*$/d'` then append. No validation. If you add a new mode, update all three scripts plus the `case "$mode" in` block in `termux-url-opener` (the `*)` arm currently just logs "Unknown mode").

## Env file convention

`.env.template` is the source of truth for required vars (`X_COOKIE_JSON`, `NOTION_API_KEY`, `NOTION_DATABASE_ID`, `GOG_KEYRING_BACKEND`, `GOG_KEYRING_PASSWORD`, `GOG_TASKS_LIST_ID`, `mode`, `GOG_ACCOUNT_EMAIL`). `.env` is gitignored. When adding a new env var, add it to `.env.template` too.

## Bash conventions used in this repo

Follow the patterns already in `termux-url-opener`:
- `set -eo pipefail` inside `main`/`setup_and_check`, not at top level.
- `readonly` for path constants computed from `$BASH_SOURCE`.
- `has()` / `hass()` guard helpers — use them instead of inline `command -v` checks.
- Logging via `log` / `info` / `warn` / `error` (color via optional `ink`, appended to `$log_file`). `error` exits non-zero.
- `# shellcheck disable=...` comments are intentional — preserve them when refactoring.

`shellcheck` and `shfmt` are available locally; run them after editing shell files.
