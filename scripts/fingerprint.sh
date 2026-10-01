#!/usr/bin/env bash
# Prints the fingerprint of a built image, a SHA-256 over what makes it:
#   hermes-agent-patched   its Containerfile and Debian package database
#                          (<directory>/dpkg-status.gz)
#   signal-cli-distroless  its Containerfile and the distroless digest it was
#                          built on (<directory>/base-digest)
#   hermes-ssh-sandbox     its Containerfile, SSH server configuration and
#                          entrypoint, and its Debian package database
#                          (<directory>/dpkg-status.gz)
# A rebuild whose fingerprint matches the published image's changed nothing.
#
# Usage: fingerprint.sh <image name> <directory holding its facts>
set -euo pipefail

name=$1
dir=$2
image_dir="$(dirname "$0")/../images/$name"
containerfile="$image_dir/Containerfile"

sha256() {
  if command -v sha256sum > /dev/null; then sha256sum; else shasum -a 256; fi | cut -d' ' -f1
}

case $name in
  hermes-agent-patched) { cat "$containerfile"; gunzip -c "$dir/dpkg-status.gz"; } | sha256 ;;
  signal-cli-distroless) { cat "$containerfile"; cat "$dir/base-digest"; } | sha256 ;;
  hermes-ssh-sandbox)
    { cat "$containerfile" "$image_dir/sshd_config" "$image_dir/entrypoint.sh"; gunzip -c "$dir/dpkg-status.gz"; } | sha256 ;;
  *)
    echo "unknown image: $name" >&2
    exit 2
    ;;
esac
