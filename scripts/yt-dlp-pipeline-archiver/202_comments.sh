#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

source "$(dirname "$0")/env"

for category in "$DLBASE/"*"/_indexes/known_urls.txt"; do
        indexloc="$(basename "$category")"

	yt-dlp --config-locations "$(dirname "$0")/common.conf" \
		--batch-file="$indexloc/comments_urls.txt" --skip-download \
		--write-comments \
		--output "./%(uploader).200s (%(uploader_id)s)/%(upload_date)s %(id)s.comments.%(ext)s" `# don't touch the original info.json` \
		--force-write-archive --download-archive="$indexloc/comments.txt" \
		--print-to-file after_video:"%(epoch)s %(webpage_url)s" "./indexes/comments_timestamps.txt" \
                --paths home:"$DLBASE/$category" --paths temp:"$DLBASE/$category/_temp"
done
