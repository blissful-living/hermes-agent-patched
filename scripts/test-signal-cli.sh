#!/usr/bin/env bash
# Tests a built signal-cli image with its default entrypoint, user and
# configuration directory:
#   - it reports the expected version and runs as the distroless nonroot user;
#   - it starts with an empty configuration (listAccounts);
#   - /var/lib is root's and world-readable, and /var/lib/signal-cli belongs
#     to the nonroot user and is closed to others, so a named volume mounted
#     there starts out writable and private.
#
# Usage: test-signal-cli.sh <image> <signal-cli version>
# Needs GNU tar, whose listing shows numeric owners.
set -euo pipefail

image=$1
version=$2

out=$(docker run --rm "$image" --version)
echo "$out"
[ "$out" = "signal-cli $version" ]
[ "$(docker image inspect -f '{{.Config.User}}' "$image")" = "65532:65532" ]
docker run --rm "$image" listAccounts

container=$(docker create "$image")
entries=$(docker export "$container" | tar -tvf - --no-recursion var/lib var/lib/signal-cli)
docker rm "$container" > /dev/null
echo "$entries"
grep -qE '^drwxr-xr-x 0/0 .* var/lib/$' <<< "$entries"
grep -qE '^drwx------ 65532/65532 .* var/lib/signal-cli/$' <<< "$entries"
