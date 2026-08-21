#!/bin/bash
printf '\033[1;36m,git-line-log\033[0m \033[2m<path> <start>[:<end>]\033[0m\n'
echo "Commit history for specific lines in a file (one line per commit, no diff)."
echo "Useful for spotting whether a region is stable, recently rewritten, or thrashed."
echo ""
[ "${1:-}" = "--help" ] && exit 0
[ $# -eq 2 ] || { echo "usage: ,git-line-log <path> <start>[:<end>]" >&2; exit 1; }
path=$1
range=$2
case "$range" in
  *:*) start=${range%:*}; end=${range#*:} ;;
  *)   start=$range; end=$range ;;
esac
git log -L "$start,$end:$path" --date=short --pretty=format:'%ad %h %an: %s' -s
echo ""
