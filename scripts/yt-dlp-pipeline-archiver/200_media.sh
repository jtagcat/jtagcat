#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

source "$(dirname "$0")/env"

for category in "$DLBASE/"*"/_indexes/known_urls.txt"; do
	indexloc="$(basename "$category")"

	yt-dlp --config-locations "$(dirname "$0")/common.conf" \
		--batch-file="$indexloc/known_urls.txt" \
		--download-archive="$indexloc/media.txt" \
                --paths home:"$DLBASE/$category" --paths temp:"$DLBASE/$category/_temp"
done
