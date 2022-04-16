## Reencode video to h265
```
ffmpeg -i INPUT -map 0 -c copy -c:v libx265 OUTPUT
```
ffmpeg: use INPUT, map: use all tracks (NOTfirst video and audio track) from first `-i`, copy all tracks over, except all video tracks
