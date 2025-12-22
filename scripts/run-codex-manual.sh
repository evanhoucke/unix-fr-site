#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
prompt_file="$repo_root/scripts/codex-daily-prompt.txt"

if ! command -v codex >/dev/null 2>&1; then
  echo "codex command not found in PATH." >&2
  exit 1
fi

echo "Launching Codex in: $repo_root"
echo ""
echo "Prompt (paste into Codex if needed):"
echo "----------------------------------"
cat "$prompt_file"
echo "----------------------------------"
echo ""

cd "$repo_root"
codex "$(cat "$prompt_file")"
