#!/bin/bash
file=elmarCurrentlyPlaying.json
dir=elmar_flatten
gitdir=elmar
branch=master

git -C "$gitdir" rev-list "$branch" | tac | while IFS= read -r sha; do
	time="$(date -u --iso-8601=seconds -d@"$(git -C "$gitdir" show --format="%at" "$sha" | head -n1)" | revcut -c 7-)Z"

	date="$(cut -c -10 <<< "$time")"
	echo "$time","$(git -C "$gitdir" show "$sha:$file")" >> "$dir/$date.csv"

done
