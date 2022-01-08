#!/usr/bin/env bash
set -euo pipefail
#TODO: implement locking with timeouts

scriptloc="${1}"
basepath="${2}"
hostname="${3}"

outdir="${basepath}/${hostname}"

if [ -d "${outdir}/.git" ]; then
	if [[ -n $(shopt -s nullglob; echo "${outdir}"/*) ]]; then
		rm -r "${outdir}/"* # all but hidden
	fi
	"${scriptloc}" "${outdir}" || exit 0 # will error if no tmux session
	git -C "${outdir}" add -- . >> /dev/null # no -q available
	git -C "${outdir}" commit -qm'autoflush' --allow-empty || true # if nothing has changed
else
	mkdir "${outdir}"
	git init "${outdir}"
	git -C "${outdir}" config user.email "noreply@${hostname}"
	git -C "${outdir}" config user.name "$USER"
	git -C "${outdir}" commit -m'Initial commit' --allow-empty
	# actual flush will happen on next execute, too minor to reuse-wrap-bla
fi

