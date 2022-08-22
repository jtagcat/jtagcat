#!/usr/bin/env bash
set -eou pipefail

if [[ "$#" != 1 ]]; then
	echo "Expected exactly 1 argument."
	echo "USAGE: pull_calllog.sh <outputDir>"
	exit 1
fi

mkdir -p "$1"
adb shell content query --uri content://call_log/calls > "$1/$(date -uI)"
