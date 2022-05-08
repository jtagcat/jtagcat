#!/bin/bash
# tastebuds_push_artists.sh <input file> <label_id> <user_credentials cookie>
# get label_id with:
# jq -s '[ .[].label_links[].label | { id, title }] | unique'
input_file="$1"
lid="$2"
cookie="$3"

input_file="issues.ndjson"
cookie="redacted"

jq -rs --arg lid "$lid" '.[] | select(.label_links[].label.id == ($lid | tonumber)) | .title' "$input_file" | \
grep -v '^ *#' | sed 's/ /+/g' | while IFS= read -r line; do
    curl 'https://tastebuds.fm/users/add_artist' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data-raw "add_artist_name=$line" -H "Cookie: user_credentials=$cookie"
done
