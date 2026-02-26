#!/usr/bin/env bash

# https://www.ipify.org
curl -Ss 'https://api.ipify.org?format=json' | jq .