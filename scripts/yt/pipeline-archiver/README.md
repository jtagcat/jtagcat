WIP

based off of https://github.com/rebane2001/sensible-yt-dlp-archive-scripts/

Make a file named env in the root, with the following:
```env
DLBASE=/path/to/output/dir
INPUTS=/path/to/inputs/dir
```

Usual `--batch-file` files should be dropped in to `$INPUTS`. The comments archiver whitelists based on filenames containing `+comments`.

 - 100_meta.sh (picks up inputs, .info.json, .description, indexing)
    - → 200_media.sh (video files)
    - → 201_subs.sh (subtitles)
    - `+comments` → 202_comments.sh (pulls comments to seperate .comments.info.json, also keeps track of when it archived comments in `_indexes`)

