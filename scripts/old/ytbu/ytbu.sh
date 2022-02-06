#!/bin/bash
LOCKFILE="/var/lock/`basename $0`"

(
    flock -n 9 || {
	echo "$0 already running"
	exit 1
    }
#above was to make sure only 1 instance can be running at any time
#
#
####################################################################################################
#
# SET YOUR WORKING DIRECTORY make sure you don't have a slash after the last directory!, insert full path to ensure cron finds it! Insert between double quotes. Make sure the directory exists, this directory is the root of the github directory.
wdir="/home/redacted/.ytbu"
#
# SET OWN YOUTUBE CHANNEL ID BELOW Go to youtube, my channel, get it from url https://www.youtube.com/channel/###OWNID###?view_as=subscriber Insert between double quotes. ID usually begins with UC
ownid="Uredacted"
#
# To retrive your client_secret.json open: https://console.developers.google.com/apis/credentials?project=_
# If you don't have one, create a project. Under APIs, Youtube's Data API v3 needs to be enabled.
# If you are not already, go to the credentials page under APIs & Services.
# Ensure, that at the top left the right project is selected.
# Click on 'OAuth consent screen' in the top bar, Enter a name and at the bottom click Save.
# Now, again in the Credentials screen press 'Create credentials', 'OAuth client ID', 'Other', Enter a name for the backup app, click 'Create'.
# You will be presented with your client ID and your client secret. Close that.
# Now under 'OAuth 2.0 client IDs' you will find the client you just created. On the far right there is a download button. Click that.
# You have now downloaded your file. Rename it to client_secret.json and move it in to the working directory.
#
# To install everything, run:
# $ sudo apt update && sudo apt install ffmpeg python3 python3-pip -y && sudo pip3 install --upgrade youtube_dl google-api-python-client google-auth google-auth-oauthlib google-auth-httplib2 oauth2client
# ^ Let me know if I missed anything (I'm pretty sure I did, haven't tested it)!
#
# Please run this and ensure no errors occur.
# $ /usr/bin/python3 --version && /usr/bin/rclone --version && /usr/bin/youtube-dl --version
#
# Sample output:
#
# Python 3.6.7
# rclone v1.43.1
# - os/arch: linux/amd64
# - go version: go1.11
# 2018.09.26
#
#
# What to do when you get any errors like 'bash: /usr/bin/youtube-dl: No such file or directory'?
# 1. Identify what is not found. In the above example youtube-dl is not found.
# 2. use 'whereis youtube-dl' to find the path, look for /bin/youtube-dl
#     If you can't find it, then
#       a) you don't have the program installed (empty output), run 'sudo apt install youtube-dl'
#       b) you may also want to try all paths listed
# 3. In this example I found youtube-dl in /usr/local/bin/youtube-dl
# 4. change the path above: (inside double quotes, not ending with a slash)
# Python3:
py3="/usr/bin/python3"
# Rclone:
rcl="/usr/bin/rclone"
# youtube-dl:
ydl="/usr/bin/youtube-dl"
# 5. run (in this example) /usr/local/bin/youtube-dl --version (your found path and --version)
# 6. If you get the expected result you are good!
#
# If you still can't get it working, it's probably the program's or your system's fault.
#
# 
#
# If you want to edit how youtube-dl downloads, edit below.
ytbu_downloadfiles () {
$ydl --download-archive $wdir/ytbu_downloaded.txt -i -o "$wdir/ytbu_downloaded/%(uploader)s/%(upload_date)s-%(id)s.%(ext)s" -f bestvideo+bestaudio --batch-file $wdir/ytbu_channels.txt
echo all downloaded
}
#
# Choose what to do with downloaded files:
ytbu_sendfiles () {
    #If you want to do nothing to the files and leave them in the working directory, do nothing.
    #If you want to move the files locally to somewhere else, change the destination and uncomment the line below.
      #mv $wdir/dowloaded/* /your/destination
    #If you want to move the files offsite, uncomment the line below, change the remote's name, path and add an rclone.config to your working directory.
      #rcl $wdir/downloaded/ remote: --config $wdir/rclone.config
echo ytbu run finished
}
#
#
####################################################################################################
#
#
# Just to make sure, go to working directory
cd $wdir
# remove leftovers from previous run, prepare
echo ignore errors about file doesn not exist on first run
rm $wdir/ytbu_nextpager.py
rm $wdir/ytbu_channels_old.txt
mv $wdir/ytbu_channels.txt $wdir/ytbu_channels_old.txt
#get data from google
$py3 $wdir/ytbu_getdata.py --noauth_local_webserver | tee $wdir/ytbu_data.txt
#filter out channel ids from data, append youtube url in front of every id, for youtube-dl, remove your own channelIds
cat $wdir/ytbu_data.txt | grep -o "'channelId': '[a-zA-Z0-9_-]*" | sed "s#^.*'#https://www.youtube.com/channel/#" | grep -v $ownid | tee $wdir/ytbu_channels.txt
#filter out nextpage (api can get only 50 channels at once)
checknextempty=$(cat $wdir/ytbu_data.txt | grep -o "'nextPageToken': '[a-zA-Z0-9_-]*" | sed "s#^.*'##" )
#if more than 2 pages, loop
while ! [ "$checknextempty" = "" ]; do
# Get ready for python injection, needs to be in the format of nextpagevar= 'pageid'
cat $wdir/ytbu_data.txt | grep -o "'nextPageToken': '[a-zA-Z0-9_-]*" | sed "s#^.*'##" | sed -e "s@^@nextpagevar='@" -e "s@\$@'@" | tee $wdir/ytbu_nextpager.py
# get the next page of data
$py3 $wdir/ytbu_getdata.py --noauth_local_webserver | tee $wdir/ytbu_data.txt
#filter new data and append to the channel list
cat $wdir/ytbu_data.txt | grep -o "'channelId': '[a-zA-Z0-9_-]*" | sed "s#^.*'#https://www.youtube.com/channel/#" | grep -v $ownid >> $wdir/ytbu_channels.txt
# Check if there is any more pages (checks if there is a token for next page)
checknextempty=$(cat $wdir/ytbu_data.txt | grep -o "'nextPageToken': '[a-zA-Z0-9_-]*" | sed "s#^.*'##" )
# Loop if there is more
done
#Finished retriveing Channels from your channel.
#Download everything new
ytbu_downloadfiles
# Transfer files: call a function
ytbu_sendfiles
# Unlock the file so this script could be run again.
) 9>$LOCKFILE

