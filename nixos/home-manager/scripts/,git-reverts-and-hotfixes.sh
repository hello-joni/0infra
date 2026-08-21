#!/bin/bash
printf '\033[1;36m,git-reverts-and-hotfixes\033[0m \033[2m[since] [path]\033[0m\n'
echo "Reverts, hotfixes, and rollbacks."
echo "'since' defaults to '1 year ago'."
echo ""
[ "${1:-}" = "--help" ] && exit 0
since=${1:-1 year ago}
if [ -n "${2:-}" ]; then
  git log --oneline --since="$since" -- "$2"
else
  git log --oneline --since="$since"
fi | grep -iE 'revert|hotfix|emergency|rollback'
