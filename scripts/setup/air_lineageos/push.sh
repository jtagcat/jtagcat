#!/bin/bash
set -e
# post-update touch-ups

adb root
adb remount

# aurora gplay store priviledged installation
adb push AuroraServices_v1.1.1.apk /system/priv-app
adb push permissions_com.aurora.services.xml /system/etc/permissions

# fixes recents thing
adb shell pm disable com.android.launcher3
adb shell pm enable com.android.launcher3
adb shell cmd package set-home-activity 'com.teslacoilsw.launcher/com.teslacoilsw.launcher.NovaLauncher'

# mobile data
adb shell svc data enable

adb reboot

