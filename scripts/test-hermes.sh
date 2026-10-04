#!/usr/bin/env bash
# Tests a built Hermes image: its Debian package database is consistent,
# Hermes starts far enough to report its version, and tirith runs from PATH,
# where Hermes looks for it before downloading one of its own.
#
# It also lists any Debian update still pending, as the daily check would see
# it. apt-get upgrade holds an update back only when it needs a package
# removed; such updates are shown for review, not treated as a failure.
#
# Usage: test-hermes.sh <image>
set -euo pipefail

image=$1
here=$(dirname "$0")

docker run --rm --entrypoint sh "$image" -c 'dpkg --audit && apt-get check -qq'
docker run --rm --entrypoint /opt/hermes/.venv/bin/hermes "$image" --version
docker run --rm --entrypoint tirith "$image" --version

status=$(mktemp)
trap 'rm -f "$status"' EXIT
docker run --rm --entrypoint cat "$image" /var/lib/dpkg/status > "$status"
pending=$("$here/pending-debian-updates.sh" "$status")
if [ -n "$pending" ]; then
  echo "$pending"
fi
echo "Debian updates pending after the upgrade: $(printf '%s' "$pending" | grep -c '^' || true)"
