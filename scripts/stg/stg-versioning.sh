#!/bin/bash
set -e
# vars
VCDIR="$1"
OUT="$VCDIR/differ"
INPUTDIR="$2"

case "$#" in
  2)
    echo "MOVETO inactive."
    ;;
  3)
    echo "MOVETO active."
    MOVETO="$3"
    ;;
  *)
    echo >&2
    echo "usage: stg-versioning.sh <git dir> <input dir>"
    exit 1
    ;;
esac

# prepare
git init "$VCDIR"

# loop through files
ls -Art "$INPUTDIR" | grep -v '^ *#' | while IFS= read -r backupinput
do
  # prepare
  rm -rf "$OUT" # we can't just overwrite, as some groups change id-s and some groups get deleted
  mkdir "$OUT"
  # split a file
  jq --raw-output 'del(.groups,.autoBackupLastBackupTimeStamp,.containers,.pinnedTabs)' "$INPUTDIR/$backupinput" > "$OUT/_.json"
  jq --raw-output '.pinnedTabs' "$INPUTDIR/$backupinput" > "$OUT/_pinnedTabs.json"
  jq --compact-output --raw-output '(del(.groups)) as $parent|.groups[]|{"filename":"\(.id).json","content":(.|del(.id,.tabs[].thumbnail,.tabs[].cookieStoreId)|@base64)}|"\(.filename):\(.content)"' "$INPUTDIR/$backupinput" |\
  grep -v '^ *#' | while IFS=: read -r filename content
  do
    base64 -d <<< "$content" | jq '{"tabs":(.tabs | sort_by(.id))} + del(.tabs)' > "$OUT/$filename"
  done
  # commit the files
  git "--git-dir=$VCDIR/.git" "--work-tree=$VCDIR" add -A
  git "--git-dir=$VCDIR/.git" "--work-tree=$VCDIR" commit --allow-empty -m "$backupinput" "--date=$(jq --raw-output '.autoBackupLastBackupTimeStamp' "$INPUTDIR/$backupinput")"

  # move file to processed dir, if set
  if [ -n "$MOVETO" ]; then
    mv "$INPUTDIR/$backupinput" "$MOVETO"
  fi
done
