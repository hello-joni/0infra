#!/bin/bash
printf '\033[1;36m,git-line-authors\033[0m \033[2m<path> [start[:end]]\033[0m\n'
echo "Blame summary: % of lines per author and median line age."
echo "Old + concentrated lines are stable; young + scattered lines are in flux."
echo ""
[ "${1:-}" = "--help" ] && exit 0
[ $# -ge 1 ] || { echo "usage: ,git-line-authors <path> [start[:end]]" >&2; exit 1; }
path=$1
range_args=()
if [ $# -ge 2 ]; then
  range=$2
  case "$range" in
    *:*) start=${range%:*}; end=${range#*:} ;;
    *)   start=$range; end=$range ;;
  esac
  range_args=(-L "$start,$end")
fi
blame=$(git blame --line-porcelain "${range_args[@]}" -- "$path")
[ -n "$blame" ] || { echo "no blame output for $path"; exit 0; }
echo "$blame" | awk '
  /^author / { author = substr($0, 8) }
  /^author-time / { by_author[author]++; total++ }
  END { for (a in by_author) printf "%6.1f%%  %s\n", 100*by_author[a]/total, a }
' | sort -nr
echo ""
echo "$blame" | awk '/^author-time / { print $2 }' | sort -n \
  | awk -v now="$(date +%s)" '
    { a[NR]=$1 }
    END {
      if (NR == 0) exit
      m = (NR % 2) ? a[(NR+1)/2] : (a[NR/2]+a[NR/2+1])/2
      days = int((now - m) / 86400)
      printf "median line age: %d days\n", days
    }'
