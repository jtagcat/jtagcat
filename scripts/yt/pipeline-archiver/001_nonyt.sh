#!/usr/bin/env bash
set -uo pipefail
shopt -s nullglob

DLBASE=/fryer/jtagcat/ia/yt/nonyt
INPUTS=/fryer/jtagcat/g/jc/jtagcat/scripts/yt/pipeline-archiver/inputs.nonyt

for input in "$INPUTS/"*; do if [ -s "$input" ]; then # has something in it
	category="$(basename "$input")"
	categorypath="$DLBASE/$category"
	mkdir -p "$categorypath/_indexes"

        echo "starting $category"
	>&2 echo "starting $category"

	yt-dlp --config-locations "$(dirname "$0")/common.conf" \
		--batch-file="$input" \
		--write-info-json --write-description --write-thumbnail --write-subs --write-comments \
        --paths home:"$DLBASE/$category" --paths temp:"$DLBASE/$category/_temp" \
		--download-archive="$categorypath/_indexes/download_archive.txt" \
		--print-to-file 'after_video:%(webpage_url)s' "$DLBASE/$category/_indexes/after_download.txt"

	>&2 echo "yt-dlp exit $?"
fi; done
