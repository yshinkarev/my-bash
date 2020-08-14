#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Build image"
docker build -t h2 .

echo "Start container"
docker run -d -t --name=h2 h2
