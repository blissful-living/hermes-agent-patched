#!/usr/bin/env bash
# Records what the daily jobs need to know about a built Hermes image, so they
# never have to pull it:
#   <directory>/dpkg-status.gz    its Debian package database
#   <directory>/chromium-version  its bundled Chromium's version, empty when
#                                 none is found
# Chromium is at the path Hermes records or in Playwright's browsers
# directory.
#
# Usage: hermes-facts.sh <image> <directory>
set -euo pipefail

image=$1
dir=$2
mkdir -p "$dir"

docker run --rm --entrypoint cat "$image" /var/lib/dpkg/status | gzip -9n > "$dir/dpkg-status.gz"

# shellcheck disable=SC2016 # expanded by the shell inside the image
docker run --rm --entrypoint sh "$image" -c \
  'p=$(cat /etc/hermes/agent-browser-executable-path 2>/dev/null || ls /opt/hermes/.playwright/*/chrome-*/chrome* 2>/dev/null | head -n 1); "$p" --version' \
  | grep -oE '[0-9]+(\.[0-9]+){3}' | head -n 1 > "$dir/chromium-version" || true
echo "Bundled Chromium: $(cat "$dir/chromium-version")"
