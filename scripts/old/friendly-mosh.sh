#!/bin/bash
host=$1
function rclone-conf {
ssh $host "mkdir -p $PWD/.config/rclone"
scp -q ~/.config/rclone/rclone.conf $host:/home/jc/.config/rclone &
}
function run-ping {
    ping $host -c 2 -W 5 > /dev/null
    ping_result=$?
}

mosh $host
mosh_result=$?
if [[ $mosh_result = 10 ]]; then
    echo Retrying.
    run-ping
    while [[ $ping_result = 1 ]]; do
        run-ping
    done
    while [[ $mosh_result = 10 ]]; do
        mosh $host > /dev/null
        mosh_result=$?
    done
else
    rclone-conf
fi
