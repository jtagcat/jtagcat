#!/bin/bash
set -e

case "$#" in
  1)
    proj="$1"
    out="${proj}"
    ;;
  2)
    proj="$1"
    out="$2"
    ;;
  *)
    echo >&2
    echo "usage: sourceforge-import.sh <sourcehut_slug> [output_dir]"
    exit 1
    ;;
esac

cvsdir="$(mktemp -d)"

rsync -a "rsync://${proj}.cvs.sourceforge.net/cvsroot/${proj}/*" "${cvsdir}"

git cvsimport -a -k -d "${cvsdir}" -C "${out}" "${out}"

