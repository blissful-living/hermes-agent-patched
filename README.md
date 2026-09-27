# hermes-agent-patched

Security-patched container images of [Hermes Agent](https://github.com/NousResearch/hermes-agent) and [signal-cli](https://github.com/AsamK/signal-cli), published to GitHub Container Registry.

Each image is the official upstream release, kept current with Debian's updates, and published with the evidence to check it:

- **Official releases:** the upstream Hermes Agent image and signal-cli's official native binary, pinned by digest and not rebuilt from source.
- **Latest Debian security patches:** Debian 13's updates, security fixes included, reach the images at the next daily check after Debian publishes them. Official Hermes releases do not pick them up (see [Why](#why)).
- **SBOM:** every published image carries an SPDX software bill of materials as a signed attestation.
- **Security scan results:** every build has a Trivy report of HIGH and CRITICAL vulnerabilities that have a fix, in the summary of its workflow run, and each finding that only a new upstream release can fix is tracked in this repository's issues.

Every image is also signed with cosign and has a GitHub build provenance attestation.

| Image | Contents |
| --- | --- |
| `ghcr.io/blissful-living/hermes-agent-patched` | The official Hermes Agent image (`nousresearch/hermes-agent`) with Debian's pending updates applied by `apt-get upgrade`. |
| `ghcr.io/blissful-living/signal-cli-distroless` | signal-cli's official native (GraalVM) binary (`ghcr.io/asamk/signal-cli:<version>-native`) on Google's distroless Debian 13 base (`gcr.io/distroless/cc-debian13:nonroot`). |

These images are unofficial. They are not affiliated with, or endorsed by, Nous Research or the signal-cli project.

## Why

- As of v2026.9.24 (September 2026), the official Hermes image is built on the Debian 13.4 base from May 2026, with Debian packages installed in August 2026 and carried forward by the build cache; its Dockerfile installs packages without running `apt-get upgrade`. Applying Debian's pending updates to v2026.9.24 upgrades 44 packages and resolves 9 critical and 13 high severity vulnerabilities (CVSS 3.1) that Debian 13 has since fixed.
- Nous Research builds each release image once and never rebuilds its tag, so a release tag always holds the same bytes ([NousResearch/hermes-agent#30128](https://github.com/NousResearch/hermes-agent/pull/30128)). These images apply Debian's updates under their own tags and leave Nous Research's tags and pins untouched.
- Nous Research publishes no signatures or SBOMs for the image, only unsigned build provenance, and Hermes release tags have been unsigned since v2026.8.13 ([NousResearch/hermes-agent#87948](https://github.com/NousResearch/hermes-agent/issues/87948)).
- Scanner findings in the image are an open topic upstream ([#103798](https://github.com/NousResearch/hermes-agent/issues/103798), [#89097](https://github.com/NousResearch/hermes-agent/issues/89097), [#51212](https://github.com/NousResearch/hermes-agent/issues/51212)).
- The official signal-cli image is built only at release, roughly monthly, on `debian:testing-slim`, which has no Debian security support.

## How

- Every day a workflow checks, without pulling the published images, whether a rebuild would change anything: any pending Debian update for the packages in the Hermes image, or a new build of the distroless base for signal-cli.
- If so, both images are rebuilt from scratch and tested. An image whose inputs (Containerfile and Debian package database, or Containerfile and distroless digest) match the published one is not published again.
- Each build produces an SPDX SBOM and a Trivy report of HIGH and CRITICAL vulnerabilities that have a fix.
- Each published image is signed with cosign (keyless, with the workflow's GitHub OIDC identity), carries its SBOM as a cosign attestation, and has a GitHub build provenance attestation.
- Upstream images are pinned by digest; [Pinning and trust](#pinning-and-trust) describes how updates to them are merged.
- The workflows ([publish](.github/workflows/publish.yml), [upstream report](.github/workflows/upstream-report.yml)) call the scripts in [scripts/](scripts), each documented in its header and runnable locally with Docker.
- What a rebuild cannot fix is reported as issues in this repository, so it stays visible until an upstream release fixes it: vulnerabilities in software that Hermes or signal-cli bundles, and a bundled Chromium older than Chrome stable. The workflow updates each issue daily and closes it once the finding is gone.

## Pinning and trust

Hermes pins its dependencies on purpose. Its [pinning policy](https://github.com/NousResearch/hermes-agent/blob/main/AGENTS.md#dependency-pinning-policy) follows two supply-chain attacks:
- the March 2026 compromise of [litellm 1.82.7 and 1.82.8](https://docs.litellm.ai/blog/security-update-march-2026) on PyPI, reached through a poisoned Trivy release in litellm's CI; and
- the May 2026 [Mini Shai-Hulud](https://www.aikido.dev/blog/mini-shai-hulud-is-back-tanstack-compromised) npm worm.

In both compromises, attackers published malicious versions through the projects' own release pipelines, so those versions passed hash, signature and provenance checks. What protected users was not installing a new release straight away. Hermes caps every dependency's version, pins GitHub Actions and Git dependencies to commit SHAs, waits 14 days before adopting a new release of a Python dependency, and moves pins after review rather than on a schedule.

These images follow the same principle:

- Every Hermes pin stays as it is. Chromium, Node.js, Python, and the Python and JavaScript dependencies change only with a new Hermes release.
- The only updates applied are Debian 13's own: its security updates and the fixes in its point releases. They come through a separate chain of trust. Debian's security team and stable release managers review each update and keep it to fixes for the versions already in the release, and apt checks every package against the archive's signed metadata.
- Upstream images, build tools and GitHub Actions are pinned by digest or commit SHA. Renovate merges an update on its own only once it is at least seven days old, and Hermes and signal-cli releases wait for approval.
- Each published tag is built once and never rewritten; only `latest` moves.

## What is not patched

- Hermes installs part of its runtime outside Debian's package manager: Node.js, Chromium and its own SQLite library, along with its Python and JavaScript dependencies. Releases after v2026.9.24 add FFmpeg, ripgrep and Python to that list. Only a new Hermes release updates them.
- From the release after v2026.9.24, Hermes runs on its own Python build, which carries its own OpenSSL and SQLite. Debian's fixes to those libraries then no longer reach Hermes's interpreter.
- Some Debian packages contain Go programs, such as the `docker` CLI, that carry the Go runtime Debian built them with. Their Go vulnerabilities are fixed only when Debian rebuilds the package.
- signal-cli compiles its Java libraries into the native binary. Only a new signal-cli release updates them.

Hermes ships its own Chromium rather than Debian's `chromium` package. It installs one exact, checksum-verified build on every platform it supports: its Linux, macOS and Windows installers, its desktop app and its container image. Up to v2026.9.24 the image installs that build with Playwright's installer; later releases pin it in Hermes's own toolchain lock file (`pm/lock.json`), and `hermes doctor` reports an installation that differs from it. Chrome's stable releases usually include security fixes, and Debian's security archive follows them, so the pinned build is often older than Debian's. These images keep the pinned build and report its age against Chrome stable in this repository's issues.

## Usage

Tags are `<upstream version>-p<build date>`, plus `latest`:

```sh
docker pull ghcr.io/blissful-living/hermes-agent-patched:v2026.9.24-p20260927
docker pull ghcr.io/blissful-living/signal-cli-distroless:0.14.8-p20260927
```

A second build on the same day gets a counter (for example `-p20260927.2`). For reproducible deployments, pin a digest (`image@sha256:...`).

The Hermes image replaces `nousresearch/hermes-agent` directly; see the [Hermes documentation](https://github.com/NousResearch/hermes-agent) for how to run it.

The signal-cli image runs as the distroless `nonroot` user (UID 65532) with the upstream entrypoint, `signal-cli --config=/var/lib/signal-cli`:

```sh
docker run --rm -it -v signal-cli:/var/lib/signal-cli ghcr.io/blissful-living/signal-cli-distroless:latest link -n my-device
```

### Verifying

With [cosign](https://github.com/sigstore/cosign) 3 or later, check the signature and the SBOM attestation:

```sh
cosign verify \
  --certificate-identity https://github.com/blissful-living/hermes-agent-patched/.github/workflows/publish.yml@refs/heads/main \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/blissful-living/hermes-agent-patched:latest

cosign verify-attestation --type spdxjson \
  --certificate-identity https://github.com/blissful-living/hermes-agent-patched/.github/workflows/publish.yml@refs/heads/main \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/blissful-living/hermes-agent-patched:latest
```

With the [GitHub CLI](https://cli.github.com), check the build provenance:

```sh
gh attestation verify oci://ghcr.io/blissful-living/hermes-agent-patched:latest \
  --repo blissful-living/hermes-agent-patched \
  --signer-workflow blissful-living/hermes-agent-patched/.github/workflows/publish.yml \
  --source-ref refs/heads/main
```

The same commands apply to `ghcr.io/blissful-living/signal-cli-distroless`.

## Limitations

- Images are built for `linux/amd64` only.
- The signal-cli image has no shell or package manager. signal-cli extracts its libsignal library to `/tmp` when it starts, so `/tmp` must be writable (for example a tmpfs when the root file system is read-only).
- The images differ slightly from upstream: newer Debian packages in the Hermes image; a different base, user (65532 rather than `signal-cli`) and no shell tools in the signal-cli image.
- A Debian fix reaches the images at the first daily check after Debian (or, for the distroless base, Google) publishes it.

## Licences

This repository's own files are under the [MIT licence](LICENSE). The images contain third-party software under its own licences: Hermes Agent (MIT), signal-cli (GPL-3.0), and Debian and distroless packages (various). [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) lists them and links to the corresponding signal-cli source.

The images and this repository are provided as is, without warranty of any kind. To report a problem, see [SECURITY.md](SECURITY.md).
