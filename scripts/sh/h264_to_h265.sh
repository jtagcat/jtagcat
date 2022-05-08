#!/bin/sh

ffmpeg -hide_banner -loglevel warning -i "$1" -map 0 -c copy -c:v libx265 "$2"
