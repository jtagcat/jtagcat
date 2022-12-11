#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

YTDLPFFMPEG="$(dirname "$0")/ffmpeg"
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
	echo "starting $file"
	>&2 echo "starting $file"

	category="$(basename "$file" | sed 's/.txt$//' | cut -d+ -f1)"
	mkdir -p "$DLBASE/$category/_indexes"

	touch "$DLBASE/$category/_indexes/meta.txt" # using _staging allows for interrupts
	cp "$DLBASE/$category/_indexes/meta.txt" "$DLBASE/$category/_indexes/meta_staging.txt"
	
	truncate -s 0 "$DLBASE/$category/_indexes/known_urls_staging.txt"

	mkdir -p "$INPUTS""/../tmp"
	yt-dlp --config-locations "$(dirname "$0")/common.conf" \
		--batch-file="$INPUTS/$(basename "$file")" --skip-download \
		--write-info-json --write-description --write-thumbnail \
		--force-write-archive --download-archive="$DLBASE/$category/_indexes/meta_staging.txt" \
		--print-to-file 'after_video:%(webpage_url)s' "$DLBASE/$category/_indexes/known_urls_staging.txt" \
		--paths home:"$DLBASE/$category" --paths temp:"$DLBASE/$category/_temp"
	>&2 echo "yt-dlp exit $?"
	
	cat "$DLBASE/$category/_indexes/known_urls_staging.txt" >> "$DLBASE/$category/_indexes/known_urls.txt"
	if echo "$file" |grep -q "+comments"; then
		cat "$DLBASE/$category/_indexes/known_urls_staging.txt" >> "$DLBASE/$category/_indexes/comments_urls.txt"
	fi
	
	mv "$DLBASE/$category/_indexes/meta_staging.txt" "$DLBASE/$category/_indexes/meta.txt"

fi; done
