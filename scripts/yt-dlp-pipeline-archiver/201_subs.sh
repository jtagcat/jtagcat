#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

source "$(dirname "$0")/env"

for category in "$DLBASE/"*"/_indexes/known_urls.txt"; do
        indexloc="$(basename "$category")"

        yt-dlp --config-locations "$(dirname "$0")/common.conf" \
		--batch-file="$indexloc/known_urls.txt" --skip-download \
		--write-subs --sub-langs all --write-auto-subs --extractor-args youtube:skip=translated_subs `# for no live chats (if currnetly live is filtered seperately): --sub-langs all,-live_chat` \
		--force-write-archive --download-archive="$indexloc/subs.txt" \
                --paths home:"$DLBASE/$category" --paths temp:"$DLBASE/$category/_temp"
done
