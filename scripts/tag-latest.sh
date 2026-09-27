#!/usr/bin/env bash
# Points each repository's `latest` tag at a published image, then checks
# that `latest` resolves to that image's digest. Empty arguments are skipped.
#
# Usage: tag-latest.sh <repository>:<tag>@<digest>...
# Needs a registry login with push rights, and the images present locally
# under <repository>:<tag>.
set -euo pipefail

here=$(dirname "$0")

for image in "$@"; do
  [ -n "$image" ] || continue
  ref=${image%@*}
  repo=${ref%:*}
  digest=${image#*@}
  docker tag "$ref" "$repo:latest"
  docker push "$repo:latest"
  latest=$("$here/image-digest.sh" "$repo:latest")
  if [ "$latest" != "$digest" ]; then
    echo "::error::$repo:latest is $latest, expected $digest"
    exit 1
  fi
done
