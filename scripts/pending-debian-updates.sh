#!/usr/bin/env bash
# Lists the Debian updates pending for a package database, one line per
# upgradable package, by running apt in a small Debian container loaded with
# that database. The image the database came from is never pulled.
#
# Usage: pending-debian-updates.sh <dpkg status file>
set -euo pipefail

debian_image="debian:13-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a"

status="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
docker run --rm -v "$status:/tmp/status:ro" "$debian_image" sh -c \
  'cp /tmp/status /var/lib/dpkg/status && apt-get -qq -o Acquire::Retries=3 update && apt list --upgradable 2>/dev/null' \
  | { grep -F '[upgradable from:' || true; }
