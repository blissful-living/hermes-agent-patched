#!/usr/bin/env bash
# Prints the current Chrome stable version for Linux, from Google's Chrome
# version history API.
#
# Usage: chrome-stable.sh
set -euo pipefail

url='https://versionhistory.googleapis.com/v1/chrome/platforms/linux/channels/stable/versions?pageSize=1'
curl -sf --max-time 30 "$url" | jq -er '.versions[0].version'
