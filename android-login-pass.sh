#!/bin/bash

LOGIN=$1
PASS=$2

android-text.sh $LOGIN

# Tab to password field
adb shell input keyevent KEYCODE_TAB

android-text.sh $PASS

# Tab to Login/SignIn button and press it
adb shell input keyevent KEYCODE_TAB
adb shell input keyevent KEYCODE_SPACE