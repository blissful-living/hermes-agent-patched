#!/usr/bin/env bash
# Keeps one open GitHub issue, found by its exact title, in step with a
# finding. When <body file> has content, the issue is created, or its body
# replaced, with <intro> followed by that content. When it is empty, an open
# issue with that title is closed.
#
# Usage: track-issue.sh <title> <body file> [intro]
# Environment: GH_TOKEN, a token with issues: write; GH_REPO, the repository
# (owner/name).
set -euo pipefail

title=$1
file=$2
intro=${3:-}

# shellcheck disable=SC2016 # $title is a jq variable
number=$(gh issue list --state open --limit 200 --json number,title \
  | jq -r --arg title "$title" 'map(select(.title == $title)) | .[0].number // empty')

if [ -s "$file" ]; then
  body=$(printf '%s\n%s\n' "$intro" "$(cat "$file")")
  if [ -n "$number" ]; then
    gh issue edit "$number" --body "$body"
  else
    gh issue create --title "$title" --body "$body"
  fi
elif [ -n "$number" ]; then
  gh issue close "$number" --comment "No longer found in the published images."
fi
