#!/usr/bin/env bash
# Records published images on the `state` branch, which the daily jobs and the
# build read instead of pulling the images. For each <name>=<image> pair, the
# branch's <name> directory is replaced by <new-state directory>/<name> plus
# an `image` file holding the published reference. Pairs with an empty image
# are skipped. Commits as github-actions[bot] only when something changed;
# the branch is created on first use.
#
# Usage: record-state.sh <new-state directory> <name>=<image>...
# Environment: GH_TOKEN, a token with contents: write; GITHUB_REPOSITORY, the
# repository (owner/name).
set -euo pipefail

new_state=$(cd "$1" && pwd)
shift

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

auth=$(printf 'x-access-token:%s' "$GH_TOKEN" | base64 | tr -d '\n')
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="http.https://github.com/.extraheader" GIT_CONFIG_VALUE_0="AUTHORIZATION: basic $auth"

cd "$work"
git init -q
git remote add origin "https://github.com/${GITHUB_REPOSITORY}.git"
if git fetch -q --depth 1 origin state; then
  git checkout -q -b state FETCH_HEAD
else
  git checkout -q --orphan state
fi

message="Record"
for pair in "$@"; do
  name=${pair%%=*}
  image=${pair#*=}
  [ -n "$image" ] || continue
  rm -rf "$name"
  cp -R "$new_state/$name" "$name"
  echo "$image" > "$name/image"
  message="$message ${image%@*}"
done

git add -A
if git diff --cached --quiet; then
  exit 0
fi
git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
  commit -q -m "$message"
git push -q origin state
