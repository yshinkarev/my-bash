#!/usr/bin/env bash

# https://www.ipify.org
IP4=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
echo $IP4