#!/bin/bash
printf '\033[1;36m,git-contributors\033[0m \033[2m[since] [path]\033[0m\n'
echo "Contributors ranked by commit count."
echo "'since' is a date like '2026-01-01' or a relative phrase like '1 year ago'."
echo ""
[ "${1:-}" = "--help" ] && exit 0
args=(-sn --no-merges)
[ -n "${1:-}" ] && args+=(--since="$1")
if [ -n "${2:-}" ]; then
  git shortlog "${args[@]}" HEAD -- "$2"
else
  git shortlog "${args[@]}" HEAD
fi
