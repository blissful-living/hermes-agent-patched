#!/usr/bin/env bash
# Prints the upstream version an image is built from, taken from the tag of
# its pinned upstream image: v2026.9.24 for nousresearch/hermes-agent:v2026.9.24,
# 0.14.8 for ghcr.io/asamk/signal-cli:0.14.8-native. Published tags start with
# this version.
#
# Usage: upstream-version.sh <image name>
set -euo pipefail

from=$("$(dirname "$0")/upstream-image.sh" "$1")
version=${from%@*}
version=${version##*:}
echo "${version%-native}"
