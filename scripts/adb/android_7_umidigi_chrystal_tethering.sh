#!/bin/sh 

# https://stackoverflow.com/a/49650552/12470046
result="$(adb shell dumpsys input_method | grep -c "mScreenOn=true")"
if [ "$result" == 1 ]; then
    adb shell input keyevent 26
fi
adb shell input keyevent KEYCODE_WAKEUP
adb shell input keyevent 62

# disable autorotate
adb shell content insert --uri content://settings/system --bind name:s:accelerometer_rotation --bind value:i:0
# set portrait
adb shell content insert --uri content://settings/system --bind name:s:user_rotation --bind value:i:0

# does not work, changes get reverted by the phone
#adb shell am start -n com.android.settings/.Settings
#adb shell input tap 1030 150
#adb shell input text Developer
#adb shell input keyevent 61 62
#adb shell input keyevent 61 61 61 61 61 61 61 61 61 61
#adb shell input keyevent 61 61 61 61 61 61 61 61 61 61
#adb shell input keyevent 61 61 61 61 61 61 61 62
#adb shell input tap 200 565
#sleep 5
#adb shell input keyevent 4 4

adb shell cmd statusbar collapse
adb shell cmd statusbar expand-notifications
adb shell input tap 500 1450 # termux, adb, and SMSForwarder running, 4th item, very fragile
adb shell input tap 200 565
sleep 5
adb shell input keyevent 4 4

adb shell am start -n com.android.settings/.TetherSettings
adb shell input keyevent 61 61
adb shell input keyevent 62
sleep 5
adb shell input keyevent 4
adb shell input keyevent 26
