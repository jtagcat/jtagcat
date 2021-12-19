#!/bin/bash
# deprecated: stonks on git now available
set -e # Exit on error
command -v jq tr grep >> /dev/null # Check for dependencies.

#TODO: replace with find . $1
# Takes one optional argument:
#if [ -z ${1+x} ]; then # Is 1st argument not set?
#    listing=$(ls *stg*.json)
#else # Directory to look in was specified.
    listing=$(ls $1/*stg*.json)
#fi
# Any furhter arguments will just be ignored.
for i in $listing; do # For each backup file
#     count="$(jq '.groups[].tabs[].url' "$i" | wc -l)" # Get total tab (url) count of all groups.
#     timestamp=$(tr '~' '-' <<< $i | sed 's/^auto-//' | tr '@' '-' | cut -d- -f 3-7)
#     date=$(cut -d- -f 1-3 <<< $timestamp)
#     time=$(cut -d- -f 4-5 <<< $timestamp | tr '-' ':')
#     date="$(jq -r '.autoBackupLastBackupTimeStamp' "$i")"
#     echo "$date;$count"
echo "$(date -d@$(jq -r '.autoBackupLastBackupTimeStamp' "$i") --utc +'%Y-%m-%d %H');$(jq '.groups[].tabs[].url' "$i" | wc -l)" &
done
