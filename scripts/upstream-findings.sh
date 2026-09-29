#!/usr/bin/env bash
# Prints, as Markdown, the HIGH and CRITICAL vulnerabilities with a fix
# available that a rebuild cannot fix in the published images: those in
# application and language packages (Trivy's lang-pkgs class), which need a
# new upstream release. That includes Go programs in Debian packages, such as
# the docker CLI, which carry the Go runtime Debian built them with until
# Debian rebuilds them. Prints nothing when there are none.
#
# Scans the SBOMs recorded on the state branch, so the images are never
# pulled.
#
# Usage: upstream-findings.sh <state directory>
set -euo pipefail

state=$1
here=$(dirname "$0")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

for name in hermes-agent-patched signal-cli-distroless hermes-ssh-sandbox; do
  [ -f "$state/$name/sbom.spdx.json.gz" ] || continue
  gunzip -c "$state/$name/sbom.spdx.json.gz" > "$work/$name.spdx.json"
  "$here/scan-sbom.sh" "$work/$name.spdx.json" > "$work/$name.trivy.json"
  findings=$(jq -r --arg class lang-pkgs -f "$here/findings.jq" "$work/$name.trivy.json" | sort -u)
  if [ -n "$findings" ]; then
    printf '\n### %s\n%s\n\n%s\n' "$name" "Published image: \`$(cat "$state/$name/image")\`" "$findings"
  fi
done
