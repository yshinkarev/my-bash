#!/usr/bin/env bash

MODE=$1

if [ -z "$MODE" ]; then
	>&2 echo "Missing MODE (0 / 1)"
	exit 1
fi

case "$MODE" in
	1) xrandr --output "eDP-1" --right-of "HDMI-1" --mode 1600x900
	    ;;
	0) xrandr --output "eDP-1" --off
	    ;;
	*) >&2 echo "Unsupported mode"
	   exit 1
	   ;;
esac