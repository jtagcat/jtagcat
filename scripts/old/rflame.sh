#!/bin/bash

# 2018-12-04 „Sends a flameshot via rclone with unique filename, copies link to the picture on your webserver to your clipboard.“

LOCKFILE="/var/lock/`basename $0`"

(
    flock -n 9 || {
	echo "$0 already running"
	exit 1
    }
##### Lock down to one instance
###############CONFIG###############
# run this: sudo apt install rclone flameshot xsel
#
wdir="$HOME/.rflame"
#Workind directory's location
flame="/usr/bin/flameshot"
#flameshot's executable's location
rclone="/usr/bin/rclone"
#rclone's executable's location
url="s.redacted.tld"
#location, where your screenshots are being hosted (without ending with slash)
rflame_default () {
flameshot config -f prtscf_%y-%m-%d_%T
#your default naming configuration here please
}
#
#rclone's config is workingdir/rfl_rclone.conf
#
#---#---#---#Config End#---#---#---#
#
timesig=$(date +%s)
#make timesig equal current unix time (once)
$flame config -f $timesig
#tmp change filename
mkdir -p $wdir/output
#making sure the directory exists for flameshot
#changed filename to be unique
$flame gui -p $wdir/output
#get screenshot
rflame_default
#call config function
##### allow multiple instances moving forward
) 9>$LOCKFILE
$rclone copy $wdir/output/$timesig.png rflame: --config=$wdir/rfl_rclone.conf
#transfer file to server
mv $wdir/output/$timesig.png $wdir/old/$timesig.png
#move to old
echo $url/$timesig.png | xsel -b
#copy link to clipboard
notify-send -u normal "rflame on clip"
#send notification of job completion

