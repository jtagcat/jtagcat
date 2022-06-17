#!/bin/bash
# the script is scheduled to run against the last backup file, it's used as a terminal splash, to monitor tabs
# most useful for:
# - are backups running
# - has tab rot occured, or will occur, if group is archived?
# - is a group too large?

backloc="$1"
#hidelist="$2" # how to implement?

file="$backloc"/"$(exa --sort=new "$backloc" | tail -n 1)"
#datebase="$(rev <<< "$file" | cut -d@ -f 2 | cut -d- -f 1-4 | rev)" # rev implementation not needed anymore, retains compatability with different backup nameschemes.
#stgepoch="$(date -ud "$(cut -d- -f 4-6 <<< "$file" | cut -d@ -f1)"T"$(cut -d~ -f 2 <<< "$datebase" | sed "s/-/:/")+00:00")" "+%s")"
stgepoch="$(date -ud "$(cut -d- -f 5-7 <<< "$file" | cut -d@ -f1)" "+%s")"
epochdiff="$(echo "$(date "+%s")"-"$stgepoch" | bc)"

# header, nonarchived/total tabs, last backup relative time
echo "STG" "$(jq '.groups[] | select(.isArchive == false) | .tabs[].url' "$file" | wc -l)"/"$(jq '.groups[].tabs[].url' "$file" | wc -l)" -"$(date -d@"$epochdiff" -u +%H:%M:%S)" @"$(date -u +%H:%M:%S)"
jq -r ".groups[].tabs[].url" "$file" | sort | grep -vFx "about:newtab" | grep -vFx "about:blank" | uniq -d | sort # duped tabs
jq -r ".groups[].tabs[].url" "$file" | grep -Fx "about:blank" | uniq -c # blank tabs (tab rot!!)

echo

groups="$(jq -r ".groups[] | select(.isArchive == false) | .id" "$file")" # hide archived groups

tmpfile=$(mktemp)

while read -r group; do
	case "$group" in
		742|748|756|763|764|773|776|806|820) # groups hidden by user
			;;
		*)
			title="$(jq -r --arg gid "$group" '.groups[] | select( .id == ($gid | tonumber) ) | .title' "$file")"
			count="$(jq -r --arg gid "$group" '.groups[] | select( .id == ($gid | tonumber) ) | .tabs[].url' "$file" | wc -l)"
			if [ "$count" -ne 0 ];then
				printf "$count:$title\n"  >> "$tmpfile"
			fi
			;;
	esac
done <<< "$groups"

column -t -s':' < "$tmpfile" | column
rm "$tmpfile"

