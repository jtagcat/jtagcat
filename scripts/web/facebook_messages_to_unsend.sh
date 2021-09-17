#!/bin/bash
# Tool for finding where you have chatted from fb.com/dyi data takeout. Does not count unsent messages.
# mkdir merged; mv inbox/* archived_threads/* merged; ./scanscript.sh merged "Your, or sb's FB full display name (account, not chat)" | sort -n

while IFS= read -r -d '' convo; do
    echo "$(jq --arg sender "$2" '.messages[] | select(.sender_name == $sender) | select(.is_unsent != true) | .sender_name' "$convo"/message_*.json | wc -l)" "$convo" &
done <   <(find "$1" -mindepth 1 -maxdepth 1 -type d -print0)
