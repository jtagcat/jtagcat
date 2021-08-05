#!/bin/bash
BRAINZ_APIROOT="https://api.listenbrainz.org"
#BRAINZ_TOKEN
brainz_file="$1"
tempfile="$(mktemp)"

echo "Track count: $(jq '.[].endTime' "${brainz_file}" | wc -l)" & # Is there a native way in jq to count objects?

jq -c '{"listen_type": "import", "payload": (.[] |= {"listened_at": (.endTime | split (" ") | .[0] + "T" + .[1] + ":00Z" | fromdateiso8601),'\
'"track_metadata": {"additional_info":{"listening_from":"spotify"}, "artist_name": .artistName, "track_name": .trackName } })}' "${brainz_file}" > "${tempfile}"

#TODO: split? 

curl "${BRAINZ_APIROOT}/1/submit-listens" -H "Authorization: Token ${BRAINZ_TOKEN}" -H "Content-Type: application/json" -d "@${tempfile}"

echo "${tempfile}"