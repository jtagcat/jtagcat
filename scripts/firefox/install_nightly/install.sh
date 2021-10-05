#!/bin/sh
# run me from the same di
set -e
mode=user # alt: system
# https://support.mozilla.org/en-US/kb/install-firefox-linux

mkdir -p ~/.opt
pushd ~/.opt >> /dev/null

# don't you dare put this in a package / mass-distribute
# https://unix.stackexchange.com/a/591258 # get file to dl
filename="$(curl --silent 'https://download-installer.cdn.mozilla.net/pub/firefox/nightly/latest-mozilla-central/' | grep -o 'href=".*">' | sed 's/href="//;s/">//g' | grep '.en-US.linux-x86_64.tar.bz2$' | xargs -- basename)"

# download ff (and signature; no checksum though, that'd be nice.. wait does bz2 include cheksum checking already?)
wget -q "https://download-installer.cdn.mozilla.net/pub/firefox/nightly/latest-mozilla-central/$filename" # {$filename,$filename.asc}

# don't verify pgp :^)
# oh we could've piped it in, but pgp seems nice, but there is nobody to actually confirm it :) any signature being valid is pointless
tar xjf "$filename"
rm "$filename" # .tar.bz2

xdg-icon-resource install --mode $mode --size 128 firefox/browser/chrome/icons/default/default128.png mozilla-firefox_nightly

popd >> /dev/null


xdg-desktop-menu install --mode $mode mozilla-firefox_nightly.desktop 
xdg-desktop-menu install --mode $mode mozilla-firefox_nightly_always_profileman.desktop 

ln -s ~/.opt/firefox/firefox ~/.local/bin/ff

# application-x-reaper for defaults?
