#!/usr/bin/env bash
# Mirrors a published image to another registry under the same tag. The image
# is copied byte for byte, so it keeps its digest, then signed there with
# cosign, with <sbom> attached as a signed SPDX attestation. The mirror's
# `latest` moves last, once the image is signed and attested, so a `latest`
# that already points at the digest means the mirror is complete.
#
# Build provenance is not copied: GitHub keeps it against the digest, so
# `gh attestation verify` finds it for the image in either registry.
#
# Prints the mirrored reference, <repository>:<tag>@<digest>; everything else
# goes to standard error.
#
# Usage: mirror-image.sh <repository>:<tag>@<digest> <destination repository> <sbom>
# Needs a registry login with push rights to the destination and, for keyless
# signing, the workflow's OIDC token (id-token: write).
set -euo pipefail

image=$1
dest=$2
sbom=$3
here=$(dirname "$0")

ref=${image%@*}
tag=${ref##*:}
digest=${image#*@}
source="${ref%:*}@$digest"

# --prefer-index=false copies the single manifest as it is instead of wrapping
# it in a new index, which keeps the digest; the check makes sure of it.
copy() {
  docker buildx imagetools create --prefer-index=false --tag "$1" "$source" >&2
  copied=$("$here/image-digest.sh" "$1")
  if [ "$copied" != "$digest" ]; then
    echo "$1 is $copied, expected $digest" >&2
    exit 1
  fi
}

copy "$dest:$tag"
cosign sign --yes "$dest@$digest" >&2
cosign attest --yes --type spdxjson --predicate "$sbom" "$dest@$digest" >&2
copy "$dest:latest"
echo "$dest:$tag@$digest"
