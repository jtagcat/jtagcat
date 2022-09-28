#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

mkdir -p "$YTDLPFFMPEG"
if [ ! -f "$YTDLPFFMPEG/version)" ] || [[ "$(cat "$YTDLPFFMPEG/version)")" != "$(date -uI)" ]]; then
	tdir="$(mktemp -d)"
	curl -sL https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz | tar -xJf- --strip=1 -C "$tdir"
	mv "$tdir/bin/"* "$YTDLPFFMPEG"
	rm -r "$tdir"

	date -uI > "$YTDLPFFMPEG/version"
fi

source "$(dirname "$0")/env"

for file in "$INPUTS/"*; do if [ -s "$file" ]; then # has something in it
	category="$(basename "$file" | sed 's/.txt$//' | cut -d+ -f1)"
	mkdir -p "$DLBASE/$category/_indexes"

	tfile="$(mktemp)"
	yt-dlp --config-locations "$(dirname "$0")/common.conf" \
		--batch-file="$INPUTS/$(basename "$file")" --skip-download \
		--write-info-json --write-description --write-thumbnail \
		--force-write-archive --download-archive="$DLBASE/$category/_indexes/meta.txt" \
		--print-to-file after_video:"%(webpage_url)s" "$tfile" \
		--paths home:"$DLBASE/$category" --paths temp:"$DLBASE/$category/_temp"
	
	cat "$tfile" >> "$DLBASE/$category/_indexes/known_urls.txt"
        if echo "$file" |grep -q "+comments"; then
		cat "$file" >> "$DLBASE/$category/_indexes/comments_urls.txt"
        fi

	rm "$tfile"
fi; done
