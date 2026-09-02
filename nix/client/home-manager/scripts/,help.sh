#!/bin/bash
printf '\033[1;36m,help\033[0m\n'
echo "Lists all ',' prefixed personal scripts on PATH with their descriptions."
echo ""
[ "${1:-}" = "--help" ] && exit 0
echo "$PATH" | tr ':' '\n' | while read -r d; do
  [ -d "$d" ] || continue
  for f in "$d"/,*; do
    [ -x "$f" ] && basename "$f"
  done
done | sort -u | while read -r cmd; do
  [ "$cmd" = ",help" ] && continue
  "$cmd" --help 2>/dev/null
done
