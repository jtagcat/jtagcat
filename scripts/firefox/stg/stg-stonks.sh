#!/usr/bin/env bash
set -eou pipefail

function stgfile {
    timestamp="$(jq -r '.autoBackupLastBackupTimeStamp' "$1")"
    count="$(jq '[ .groups[].tabs[] , .pinnedTabs[]? ] | length' "$1")"
    echo "${timestamp};${count};$(basename "$1")"
}

function bakdir {
    for file in "$1"/*.json; do
        stgfile "$file" &
    done
}


out="stg-stonks_$(date --iso-8601)"
mkdir -p "$out"

cat > "$out/command.gnuplot" << EOF
set datafile separator ';'
set xdata time
set timefmt "%s"
set title "Tabs open on desktop profiles"
set format x "%b %y"

plot 
EOF
truncate -s -1 "$out/command.gnuplot"

for dir in "$@"; do
    name="$(basename "$dir")"
    dir="$(readlink -m "$dir")"

    bakdir "$dir" | sort > "$out/$name"
    printf "'%s' using 1:2 with lines title '%s'," "$name" "$name" >> "$out/command.gnuplot"
done

pushd "$out"
gnuplot -p -c "command.gnuplot"
