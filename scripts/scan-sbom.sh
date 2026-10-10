#!/usr/bin/env bash
# Scans an SPDX SBOM with Trivy for HIGH and CRITICAL vulnerabilities that
# have a fix, and writes Trivy's JSON report to standard output.
#
# Syft records the distribution only in each Debian package's purl, which
# Trivy does not read, so it is passed to Trivy explicitly; without it Trivy
# skips the operating system packages.
#
# Trivy runs in a container that sees only the SBOM's directory, read-only,
# and its own database cache.
#
# Usage: scan-sbom.sh <sbom.spdx.json>
# Environment: RUNNER_TEMP, where the vulnerability database is cached between
# scans (default: TMPDIR, then /tmp).
set -euo pipefail

trivy_image="aquasec/trivy:0.75.0@sha256:af6acf9a6b85dfe389a1941505c0ce9efef52a4719635e1a962f022a3d855daa"

sbom=$1
distro=$(jq -r 'first(.packages[].externalRefs[]? | .referenceLocator
  | capture("^pkg:deb/.*[?&]distro=(?<family>[a-z]+)-(?<version>[0-9]+)")
  | "\(.family)/\(.version)") // empty' "$sbom")

cache="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/trivy"
mkdir -p "$cache"
docker run --rm \
  -v "$(cd "$(dirname "$sbom")" && pwd):/work:ro" \
  -v "$cache:/cache" \
  "$trivy_image" sbom --cache-dir /cache --quiet \
  --severity HIGH,CRITICAL --ignore-unfixed --format json \
  ${distro:+--distro "$distro"} \
  "/work/$(basename "$sbom")"
