## ytbu - Automatically backup your youtube subscription's videos.
Supports webhook notifications for OAuth token refresh. Main code in bash, API retrived with python, downloads with [youtube-dl](https://github.com/rg3/youtube-dl).

### Setup:
ytbu is meant to be run on linux, with [crontab](https://www.ostechnix.com/a-beginners-guide-to-cron-jobs/). ([timing guide](https://crontab.guru/))
Cron should execute [ytbu.sh](ytbu.sh)

See [ytbu.sh](ytbu.sh) for more instructions and for the main config.
Also edit [ytbu_getdata.py](ytbu_getdata.py) to set the working directory for it aswell and set up webhooks for token refresh notifications.

youtube-dl may be configured at the bottom of [ytbu.sh](ytbu.sh)

#### Troubleshooting
 - youtube-dl errors: Make sure youtube-dl is up to date by running `sudo youtube-dl -U`
  - Your API token may be expired. If so, run it manually, without crontab and authenticate.
   - Out of space? Split the ytbu_channels.txt to multiple files and run 69th line of [ytbu.sh](ytbu.sh) to download the files (the line beginning with $ydl), then manually move them to your storage and repeat. Alternatively change youtube-dl's output to an rclone mount
