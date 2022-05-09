#!/usr/bin/env bash
set -eou pipefail
# AUTHOR: jtagcat
# LICENCE:  GPL3

array=( "pdfjam" ) # "pdftk" )
for i in "${array[@]}"; do
    if ! command -v "$i" >/dev/null 2>&1; then
        echo >&2 "$i not found, please install the dependancy."; 
        exit 1 
    fi
done

if [[ "$#" != 2 ]]; then
  echo "usage: a5-a4doublesideFoldable.sh <input.pdf> <output.pdf>"
  exit 1
fi

#t="$(mktemp)"
pdfjam -q --booklet true --page a4paper --landscape --nup 2x1 "$1" -o "$2" # $t"
#pdftk "$t" rotate oddDown output "$2"
#rm "$t"
