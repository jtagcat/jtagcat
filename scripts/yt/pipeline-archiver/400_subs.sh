#!/usr/bin/env bash
set -uo pipefail
shopt -s nullglob

source "$(dirname "$0")/env"

for categorypath in "$DLBASE/"*; do if [ -s "$categorypath/_indexes/known_urls.txt" ]; then
        category="$(basename "$categorypath")"
        echo "starting $category"
        >&2 echo "starting $category"

        yt-dlp --config-locations "$(dirname "$0")/common.conf" \
		--batch-file="$categorypath/_indexes/known_urls.txt" --skip-download \
		--write-subs --sub-langs all --write-auto-subs --extractor-args youtube:skip=translated_subs `# for no live chats (if currnetly live is filtered seperately): --sub-langs all,-live_chat` \
		--force-write-archive --download-archive="$categorypath/_indexes/subs.txt" \
		--print-to-file after_video:"%(epoch)s %(webpage_url)s" "$categorypath/_indexes/subtitle_timestamps.txt" \
                --paths home:"$DLBASE/$category" --paths temp:"$DLBASE/$category/_temp"
fi;done
