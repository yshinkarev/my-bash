#!/usr/bin/env bash

adb devices | grep -v "offline|\unauthorized" | tail -n +2 | cut -sf 1 | xargs -IX -P 8 adb -s X "$@"