#!/bin/bash
printf '\033[1;36m,git-top-buggy-files\033[0m \033[2m[path]\033[0m\n'
echo "Top 20 files most associated with bug-fix commits."
echo "Files that appear on both ,git-top-changed-files and ,git-top-buggy-files are highest-risk code."
echo ""
[ "${1:-}" = "--help" ] && exit 0
git log -i -E --grep="fix|bug|broken" --name-only --format="" \
  | { if [ -n "$1" ]; then grep -F "$1"; else cat; fi; } \
  | sort | uniq -c | sort -nr | head -20
