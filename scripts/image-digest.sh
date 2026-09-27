#!/usr/bin/env bash
# Prints the digest an image reference resolves to in its registry, without
# pulling the image. For a multi-platform image this is the digest of its
# index.
#
# Usage: image-digest.sh <image reference>
set -euo pipefail

docker buildx imagetools inspect "$1" --format '{{json .Manifest}}' | jq -r .digest
