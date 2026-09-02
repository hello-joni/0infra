#!/bin/bash
printf '\033[1;36m,git-commits-by-month\033[0m \033[2m[since]\033[0m\n'
echo "Commit count by month."
echo "'since' is a date like '2025-01-01' or a relative phrase like '1 year ago'."
echo ""
[ "${1:-}" = "--help" ] && exit 0
if [ -n "$1" ]; then
  git log --since="$1" --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
else
  git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
fi
