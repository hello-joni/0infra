#!/bin/bash
printf '\033[1;36m,git-file-related-files\033[0m \033[2m<path>\033[0m\n'
echo "Top 20 files most often committed alongside the given file."
echo "Files high on this list often share concerns or get touched together for the same reason."
echo ""
[ "${1:-}" = "--help" ] && exit 0
[ $# -eq 1 ] || { echo "usage: ,git-file-related-files <path>" >&2; exit 1; }
path=$1
shas=$(git log --follow --format=%H -- "$path")
[ -n "$shas" ] || { echo "no commits touching $path"; exit 0; }
echo "$shas" \
  | xargs -n 50 git show --name-only --format= \
  | grep -v '^$' \
  | grep -vFx "$path" \
  | sort | uniq -c | sort -nr | head -20
