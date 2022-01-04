#!/usr/bin/env bash
set -euo pipefail

# Runs capture-pane on all panes on a tmux server.
baseout="${1}"
# WARN: overwrites only existing panes, does not delete closed panes. Delete baseout before running for a mirror of current state.

panes="$(tmux list-panes -a -F '#{session_created}_#{session_id}/#{window_id}/#{pane_id}')"
  # a: all panes of tmux server
grep -v '^ *#' <<< "$panes" | while IFS= read -r panepath; do
        outpath="${baseout}/${panepath}"
        mkdir -p "$(dirname "${outpath}")"
	paneid="$(basename "${panepath}")"
	tmux capture-pane -peJ -S - -t "${paneid}" > "${outpath}"
	  # p: to stdout
          # e: keep escape sequences
          # unavail: N: preserve trailing spaces
          # J: preserve trailing spaces and join wrapped lines (is N redundant?)
          # S: line nr of caputre start (0 is the top of screen, negative line numbers are history): '-' is infinite negativity, everything
          # (E: end line defaults to max)
          # t: specified pane
done

