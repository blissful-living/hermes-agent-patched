#!/usr/bin/env bash
# Builds images/<name>/Containerfile into local/<name> from scratch: the
# upstream image is pulled again and no build cache is used, so every Debian
# update published so far is applied. The image carries OCI labels for its
# build time, source revision and base image.
#
# signal-cli's distroless base is named by tag in SIGNAL_BASE. It is resolved
# to its current digest here and passed to the build, and the digest is kept
# in the image's org.opencontainers.image.base.digest label, so the image
# records exactly which base it was built on.
#
# Usage: build-image.sh <image name>
# Environment: GITHUB_SHA, the source revision (default: the checked-out
# commit); SIGNAL_BASE, the distroless tag (signal-cli only).
set -euo pipefail

name=$1
here=$(dirname "$0")
revision=${GITHUB_SHA:-$(git -C "$here" rev-parse HEAD)}
build_args=()

case $name in
  hermes-agent-patched | hermes-ssh-sandbox)
    from=$("$here/upstream-image.sh" "$name")
    base_name="docker.io/${from%@*}"
    base_digest=${from#*@}
    ;;
  signal-cli-distroless)
    base_name=${SIGNAL_BASE:?SIGNAL_BASE is not set}
    base_digest=$("$here/image-digest.sh" "$base_name")
    build_args+=(--build-arg "BASE=${base_name%:*}@$base_digest")
    ;;
  *)
    echo "unknown image: $name" >&2
    exit 2
    ;;
esac

docker build --pull --no-cache --provenance=false --sbom=false \
  ${build_args[@]+"${build_args[@]}"} \
  --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --label "org.opencontainers.image.revision=$revision" \
  --label "org.opencontainers.image.base.name=$base_name" \
  --label "org.opencontainers.image.base.digest=$base_digest" \
  -f "$here/../images/$name/Containerfile" -t "local/$name" "$here/../images/$name"
