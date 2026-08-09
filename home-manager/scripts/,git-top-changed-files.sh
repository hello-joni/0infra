#!/bin/bash
printf '\033[1;36m,git-top-changed-files\033[0m \033[2m[path]\033[0m\n'
echo "Top 20 most-changed files in the last year."
echo "Files that appear on both ,git-top-changed-files and ,git-top-buggy-files are highest-risk code."
echo ""
[ "${1:-}" = "--help" ] && exit 0
git log --format=format: --name-only --since="1 year ago" \
  | { if [ -n "$1" ]; then grep -F "$1"; else cat; fi; } \
  | sort | uniq -c | sort -nr | head -20
