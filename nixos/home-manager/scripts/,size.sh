#!/bin/bash
printf '\033[1;36m,size\033[0m \033[2m[path]\033[0m\n'
echo "du -ah --max-depth=1, sorted descending by size."
echo ""
[ "${1:-}" = "--help" ] && exit 0
du -ah --max-depth=1 "${1:-.}" | sort -hr
