#!/bin/bash

SERVICE="Wi-Fi"

case "$1" in
  on)
    networksetup -setsecurewebproxystate "$SERVICE" on
    networksetup -setsocksfirewallproxystate "$SERVICE" on
    ;;
  off)
    networksetup -setsecurewebproxystate "$SERVICE" off
    networksetup -setsocksfirewallproxystate "$SERVICE" off
    ;;
  *)
    echo "Usage: $0 {on|off}"
    ;;
esac
