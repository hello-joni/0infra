#!/bin/bash
printf '\033[1;36m,git-file-stats\033[0m \033[2m<path>\033[0m\n'
echo "Stats for a single file: commits, distinct authors, first/last touched, commits/month."
echo "Use to assess how active or stable a file is over time."
echo ""
[ "${1:-}" = "--help" ] && exit 0
[ $# -eq 1 ] || { echo "usage: ,git-file-stats <path>" >&2; exit 1; }
path=$1
commits=$(git log --follow --format=%H -- "$path" | wc -l)
if [ "$commits" -eq 0 ]; then
  echo "no commits touching $path"
  exit 0
fi
authors=$(git log --follow --format=%aN -- "$path" | sort -u | wc -l)
first=$(git log --follow --format=%ad --date=short --reverse -- "$path" | head -1)
last=$(git log --follow --format=%ad --date=short -- "$path" | head -1)
months=$(( ( $(date -d "$last" +%s) - $(date -d "$first" +%s) ) / 2629800 + 1 ))
rate=$(awk -v c="$commits" -v m="$months" 'BEGIN { printf "%.2f", c/m }')
printf "commits:        %s\n" "$commits"
printf "authors:        %s\n" "$authors"
printf "first touched:  %s\n" "$first"
printf "last touched:   %s\n" "$last"
printf "commits/month:  %s\n" "$rate"
