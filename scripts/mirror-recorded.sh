#!/usr/bin/env bash
# Makes Docker Hub match the images recorded on the state branch. mirror-image.sh
# moves Docker Hub's `latest` last, so a `latest` that already points at the
# recorded digest means that image is fully mirrored and is left alone; any
# other recorded image is mirrored with its recorded SBOM. A mirror that
# failed part-way is therefore completed by the next run.
#
# Prints one Markdown line per recorded image.
#
# Usage: mirror-recorded.sh <state directory> <Docker Hub namespace>
# Needs a Docker Hub login with push rights and, for keyless signing, the
# workflow's OIDC token (id-token: write).
set -euo pipefail

state=$1
namespace=$2
here=$(dirname "$0")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

for name in hermes-agent-patched signal-cli-distroless; do
  [ -f "$state/$name/image" ] || continue
  image=$(cat "$state/$name/image")
  dest="docker.io/$namespace/$name"
  if [ "$("$here/image-digest.sh" "$dest:latest" 2>/dev/null || true)" = "${image#*@}" ]; then
    echo "Already mirrored: \`$image\`"
    continue
  fi
  gunzip -c "$state/$name/sbom.spdx.json.gz" > "$work/$name.spdx.json"
  mirrored=$("$here/mirror-image.sh" "$image" "$dest" "$work/$name.spdx.json")
  echo "Mirrored \`$mirrored\`"
done
