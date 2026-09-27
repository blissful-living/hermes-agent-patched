#!/usr/bin/env bash
# Prints the pinned upstream image an image is built from: the first FROM line
# of its Containerfile that names an image rather than a build argument.
#   hermes-agent-patched   nousresearch/hermes-agent:<version>@sha256:<digest>
#   signal-cli-distroless  ghcr.io/asamk/signal-cli:<version>-native@sha256:<digest>
#
# Usage: upstream-image.sh <image name>
set -euo pipefail

containerfile="$(dirname "$0")/../images/$1/Containerfile"
# shellcheck disable=SC2016 # awk fields, and a literal $ for build arguments
from=$(awk '$1 == "FROM" && $2 !~ /^\$/ { print $2; exit }' "$containerfile")
if [ -z "$from" ]; then
  echo "no upstream image in $containerfile" >&2
  exit 1
fi
echo "$from"
