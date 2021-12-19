#!/bin/sh
# run me from the same di
set -e
# https://support.mozilla.org/en-US/kb/install-firefox-linux


#TODO: test cleanup hooks
#TODO: uninstall
#TODO: application-x-reaper for defaults?

action="install"
mode=user # alt: system
loc=/home/jc/.opt # absolute pls, for .desktop
name="Firefox ESR"
dirname="firefox_esr"
wmclass="ESR"
dlurl="https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=linux64&lang=en-US" # https://www.mozilla.org/en-US/firefox/all
seperate_profile_manager=1
exealias=ffesr
#TODO: check vars?

case "$action" in
	install)
		mkdir -p -- "$loc"
		tdir="$(mktemp -d)"
		
		function cleanup {
			rm -rf "$tdir"
		}
		trap cleanup EXIT

		# dl
		filename="$tdir/$dirname.tar.bz2"
		wget -q -O "$filename" -- "$dlurl" # not using --trust-server-names
		
		# extract
		fidir="$tdir/$dirname"
		mkdir "$fidir"
		tar xjf "$filename" -C "$fidir" --strip-components 1
		
		# atomic move-replace
		mv "$loc/$dirname" "$tdir/old" 2>/dev/null || true # migt fail if nothing there yet
		mv "$tdir/$dirname" "$loc"

		# xdg installs: same name will be overwritten/'updated'
		xdg-icon-resource install --mode "$mode" --size 128 "$loc/$dirname/browser/chrome/icons/default/default128.png" "mozilla-$dirname"
		exeloc="$loc/$dirname/firefox"
		dname="$tdir/mozilla-$dirname.desktop"

		title="$name" exeloc="$exeloc" mainexeloc="$exeloc %u" dirname="$dirname" wmclass="$wmclass" envsubst < "mozilla-template.desktop" > "$dname"
		xdg-desktop-menu install --mode "$mode" "$dname"
		
		if [[ "$seperate_profile_manager" == 1 ]]; then
			dname="$tdir/mozilla-${dirname}_profilemanager.desktop"
			title="$name (Profile Manager)" exeloc="$exeloc" mainexeloc="$exeloc %u --ProfileManager" dirname="$dirname" wmclass="$wmclass" envsubst < "mozilla-template.desktop" > "$dname"
			xdg-desktop-menu install --mode "$mode" "$dname"
		fi
		
		if [ -n "${VAR}" ]; then # not empty
			mkdir -p -- "$HOME/.local/bin"
			ln -s "$exeloc" "$HOME/.local/bin/$exealias"
			[[ $(type -P "$cmd") ]] || { echo "$cmd is NOT in PATH" 1>&2; exit 1; } # https://stackoverflow.com/a/6569837
		fi
		;;
	uninstall)
		#TODO:
		echo uninstall not implemented
		;;
	*)
		echo "available actions: install, uninstall"
		exit 1
		;;
esac

