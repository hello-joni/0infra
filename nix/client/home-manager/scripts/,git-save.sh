#!/bin/bash
set -euo pipefail

printf '\033[1;36m,git-save\033[0m\n'
echo "Stage all changes at the repo root and commit with the literal output of $(date)."
echo ""
[ "${1:-}" = "--help" ] && exit 0

root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "not inside a git repository" >&2
  exit 1
}

cd "$root"
msg=$(date)
git add .
git commit -m "$msg"
