#!/usr/bin/env bash

set -e

echo "BitWarden CLI version: $(bw --version)"

echo "Initialising config"
bw config server ${BW_HOST}
echo ""

if [ -n "$BW_CLIENTID" ] && [ -n "$BW_CLIENTSECRET" ]; then
    echo "Logging in via apikey"
    bw login --apikey --raw
    echo "Unlocking"
    export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)
else
    echo "Using username and password to log in"
    export BW_SESSION=$(bw login ${BW_USER} --passwordenv BW_PASSWORD --raw)
fi

#bw unlock --check

echo 'Running `bw serve` on port 8087'
bw serve --hostname 0.0.0.0 #--disable-origin-protection