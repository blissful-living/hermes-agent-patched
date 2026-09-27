# Security

## Reporting a problem

Report a vulnerability privately through [GitHub's private vulnerability reporting](https://github.com/blissful-living/hermes-agent-patched/security/advisories/new) for this repository. Please do not open a public issue for it.

## Scope

In scope:

- The build and publishing pipeline in this repository, including anything that could let someone alter, replace or forge a published image, signature, SBOM or attestation.
- Changes these images make to upstream: the Debian package upgrade in the Hermes image, and the base image, user and file layout of the signal-cli image.
- A Debian or distroless fix that the images have not picked up within a few days of its release.

Out of scope:

- Vulnerabilities in Hermes Agent, signal-cli or the software they install outside Debian's package manager (such as Chromium, Node.js, and Python, JavaScript and Java dependencies). Report these upstream: [Hermes Agent](https://github.com/NousResearch/hermes-agent/security) or [signal-cli](https://github.com/AsamK/signal-cli/issues). Known ones with a fix are tracked in this repository's issues until an upstream release ships it.
- Vulnerabilities in Debian or distroless packages that have no fix yet. Report these to [Debian](https://www.debian.org/security/) or [distroless](https://github.com/GoogleContainerTools/distroless).
