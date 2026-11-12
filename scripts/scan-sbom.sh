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

trivy_image="aquasec/trivy:0.76.2@sha256:8f6bb947dbc528902e11f2f5be52f7b519f6a39d5d148f41166f2040499768fb"

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
