#!/bin/bash

KERNELS=$(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')
if [[ "$@" == *"--delete"* ]]; then
	echo "${KERNELS}" | xargs sudo apt -y purge
else
	echo "${KERNELS}"
fi