#!/bin/bash

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo $BRANCH

if [[ "$@" == *"--to-clipboard"* ]]; then	
	printf $BRANCH | xclip -selection c
fi