#!/bin/bash
printf '\033[1;36m,git-file-log\033[0m \033[2m<path> [n]\033[0m\n'
echo "Last N commits touching the file (default 20). Shows date, sha, author, subject."
echo ""
[ "${1:-}" = "--help" ] && exit 0
[ $# -ge 1 ] || { echo "usage: ,git-file-log <path> [n]" >&2; exit 1; }
path=$1
n=${2:-20}
git log --follow --date=short --pretty=format:'%ad %h %an: %s' -n "$n" -- "$path"
echo ""
