#!/bin/bash

set -e

if [[ $# -ne 1 ]]; then
    echo "err: no input file specified"
    echo ""
    echo "usage: err-raadio.sh <file>"
    exit 1
fi

while read p; do
  m3u8url=$(curl "$p" | grep m3u8 | cut -d\' -f 2)
  name=$(cut -d\/ -f 5 <<< $p)
  youtube-dl $m3u8url -o "$name.%(ext)s" &
done <$1