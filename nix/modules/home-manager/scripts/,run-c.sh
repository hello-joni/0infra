#!/bin/bash
printf '\033[1;36m,run-c\033[0m \033[2m<file.c> [args...]\033[0m\n'
echo "Compile a C file into tmp/ with -Wall -Wextra, run it, then clean up regardless of exit code."
echo ""
[ "${1:-}" = "--help" ] && exit 0
[ $# -ge 1 ] || { echo "usage: ,run-c <file.c> [args...]" >&2; exit 1; }
src=$1
shift

[ -f "$src" ] || { echo "no such file: $src" >&2; exit 1; }

mkdir -p tmp
out="tmp/$(basename "${src%.c}").$$"
trap 'rm -f "$out"' EXIT

gcc -Wall -Wextra "$src" -o "$out" || exit 1
"$out" "$@"
