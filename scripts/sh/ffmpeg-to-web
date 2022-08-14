#!/bin/sh

ffmpeg -hide_banner -loglevel warning -i "$1" -preset slow -map 0 -c copy -c:v libx264 -crf 23 -c:a aac -movflags faststart "$2"
