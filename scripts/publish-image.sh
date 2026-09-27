#!/usr/bin/env bash
# Publishes a built image as <repository>:<version>-p<UTC date>, with a
# counter (.2, .3, ...) appended when that tag already exists, so a published
# tag is never rewritten. The image is then signed with cosign and <sbom> is
# attached as a signed SPDX attestation, both by digest.
#
# Prints the published reference, <repository>:<tag>@<digest>; everything
# else goes to standard error.
#
# Usage: publish-image.sh <local image> <repository> <version> <sbom>
# Needs a registry login with push rights and, for keyless signing, the
# workflow's OIDC token (id-token: write).
set -euo pipefail

image=$1
repo=$2
version=$3
sbom=$4
here=$(dirname "$0")

today=$(date -u +%Y%m%d)
tag="$version-p$today"
n=1
while docker buildx imagetools inspect "$repo:$tag" > /dev/null 2>&1; do
  n=$((n + 1))
  tag="$version-p$today.$n"
done

docker tag "$image" "$repo:$tag"
docker push "$repo:$tag" >&2
digest=$("$here/image-digest.sh" "$repo:$tag")
cosign sign --yes "$repo@$digest" >&2
cosign attest --yes --type spdxjson --predicate "$sbom" "$repo@$digest" >&2
echo "$repo:$tag@$digest"
