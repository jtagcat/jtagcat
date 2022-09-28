#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

source "$(dirname "$0")/env"

cat "$INPUTS/"* | cut -d" " -f1 | sort | uniq -D | uniq -c
