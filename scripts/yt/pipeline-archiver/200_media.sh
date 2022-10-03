#!/usr/bin/env bash
set -uo pipefail
shopt -s nullglob

source "$(dirname "$0")/env"

for categorypath in "$DLBASE/"*; do if [ -s "$categorypath/_indexes/known_urls.txt" ]; then
	category="$(basename "$categorypath")"
        echo "starting $category"

	yt-dlp --config-locations "$(dirname "$0")/common.conf" \
		--batch-file="$categorypath/_indexes/known_urls.txt" \
		--download-archive="$categorypath/_indexes/media.txt" \
                --paths home:"$DLBASE/$category" --paths temp:"$DLBASE/$category/_temp"
fi; done
