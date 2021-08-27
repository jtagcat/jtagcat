#!/bin/sh
# run me from the same di
set -e

# don't you dare put this in a package / mass-distribute

# https://support.mozilla.org/en-US/kb/install-firefox-linux
mkdir -p ~/.opt
pushd ~/.opt >> /dev/null

# https://unix.stackexchange.com/a/591258 # get file to dl
filename="$(curl --silent 'https://download-installer.cdn.mozilla.net/pub/firefox/nightly/latest-mozilla-central/' | grep -o 'href=".*">' | sed 's/href="//;s/">//g' | grep '.en-US.linux-x86_64.tar.bz2$' | xargs -- basename)"

# download shit
wget -q "https://download-installer.cdn.mozilla.net/pub/firefox/nightly/latest-mozilla-central/$filename" #{$filename,$filename.asc}

# don't verify pgp :^)

# oh we could've piped it in, but pgp seems nice, but there is nobody to actually confirm it :) any signature is valid is no point
tar xjf "$filename"
rm "$filename"

mkdir -p ~/.local/share/icons/hicolor/128x128
cp firefox/browser/chrome/icons/default/default128.png ~/.local/share/icons/hicolor/128x128/firefox_nightly.png

popd
mkdir -p ~/.local/share/applications
cp *.desktop ~/.local/share/applications
