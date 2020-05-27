#!/usr/bin/env bash

for i in *.apk; do
	adb install -r $i
done