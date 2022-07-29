#!/usr/bin/env bash
set -eo pipefail

if [[ -z "$JOPLIN_TOKEN" ]]; then
	echo "JOPLIN_TOKEN is required"
	exit 1
fi
if [[ "$#" != 1 ]]; then
	echo "expected exactly 1 argument (note id)"
	exit 1
fi
JOPLIN_NOTE="$1"

t="$(mktemp)"

curl -s "http://localhost:41184/notes/$JOPLIN_NOTE?fields=body&token=$JOPLIN_TOKEN" | jq -r .body > "$t"

cat < /dev/stdin >> "$t"

curl -s -X PUT "http://localhost:41184/notes/$JOPLIN_NOTE?token=$JOPLIN_TOKEN" --json "$(jq --raw-input --slurp --null-input '{"body":inputs}' "$t")" > /dev/null

rm "$t"
