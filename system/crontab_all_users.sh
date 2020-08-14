#!/usr/bin/env bash
sudo awk -F: '{print $1}' /etc/passwd | xargs -l1 crontab -lu 2> /dev/null