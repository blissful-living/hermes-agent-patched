#!/usr/bin/env bash
# Prints a Markdown report on built images: each image's size and SBOM, then
# the HIGH and CRITICAL vulnerabilities with a fix available, counted per
# target and listed one per line (at most 200 per image).
#
# Reads local/<name> and <name>.spdx.json from the working directory, and
# writes Trivy's report for each image to <name>.trivy.json there.
#
# Usage: report.sh <image name>...
set -euo pipefail

here=$(dirname "$0")

size() {
  awk -v b="$1" 'BEGIN {
    split("B KiB MiB GiB", unit); i = 1
    while (b >= 1024 && i < 4) { b /= 1024; i++ }
    printf(i == 1 ? "%d %s\n" : "%.1f %s\n", b, unit[i])
  }'
}

echo "## Images"
echo "| Image | Size | SBOM packages | SBOM size |"
echo "| --- | --- | --- | --- |"
for name in "$@"; do
  image_size=$(docker image inspect -f '{{.Size}}' "local/$name")
  sbom_size=$(wc -c < "$name.spdx.json")
  echo "| $name | $(size "$image_size") | $(jq '.packages | length' "$name.spdx.json") | $(size "$sbom_size") |"
done

for name in "$@"; do
  "$here/scan-sbom.sh" "$name.spdx.json" > "$name.trivy.json"
  echo
  echo "## $name: HIGH and CRITICAL vulnerabilities with a fix available"
  echo "| Target | Class | Critical | High |"
  echo "| --- | --- | --- | --- |"
  jq -r '.Results[]? | "| \(if (.Target // "") == "" then .Type else .Target end) | \(.Class) | \([.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length) | \([.Vulnerabilities[]? | select(.Severity == "HIGH")] | length) |"' "$name.trivy.json"
  echo
  jq -r --arg class "" -f "$here/findings.jq" "$name.trivy.json" | sort -u | head -n 200
done
