#!/bin/bash
# usage: .sh <input_DCIM_dir_with_101APPLE_inside> <absolute_output_dir>

#set -e # allow failures, as all don't exist

absolute_out="$2"

mkdir -p "$absolute_out"

cd "$1"

for dir in $(ls); do
	echo "Switching to $dir."
	cd "$dir"
	dirnr="$(sed 's/APPLE//' <<< "$dir")"
	for imagedir in $(ls); do
		imagedirnr="$(sed 's/IMG_//' <<< "$imagedir")"
		for format in {FullSizeRender.{jpg,mov,heic},PenultimateFullSizeRender.{jpg,heic},Adjustments.plist}; do
			[[ -f "${imagedir}/Adjustments/${format}" ]] && mv -n "${imagedir}/Adjustments/${format}" "${absolute_out}/IMG_${dirnr}_${imagedirnr}_${format}"
		done
	done
	cd ..
done
cd ..
find "$1" -type d -empty -delete
