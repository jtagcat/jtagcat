#!/usr/bin/env bash
set -uo pipefail
shopt -s nullglob

source "$(dirname "$0")/env"

for categorypath in "$DLBASE/"*; do if [ -s "$categorypath/_indexes/comments_urls.txt" ]; then
        category="$(basename "$categorypath")"
        echo "starting $category"

	yt-dlp --config-locations "$(dirname "$0")/common.conf" \
		--batch-file="$categorypath/_indexes/comments_urls.txt" --skip-download \
		--write-comments \
		--output "%(uploader).200s (%(uploader_id)s)/%(upload_date)s %(id)s.comments_%(ext)s" `# don't touch the original info.json` \
		--force-write-archive --download-archive="$categorypath/_indexes/comments.txt" \
		--print-to-file after_video:"%(epoch)s %(webpage_url)s" "$categorypath/_indexes/comments_timestamps.txt" \
                --paths home:"$DLBASE/$category" --paths temp:"$DLBASE/$category/_temp"
fi;done
