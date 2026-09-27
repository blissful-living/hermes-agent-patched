# Third-party notices

The images published from this repository redistribute the following software. Apart from the Debian package upgrade in the Hermes image, each is redistributed unmodified; this repository's MIT licence does not apply to it.

## Hermes Agent

- Image: `ghcr.io/blissful-living/hermes-agent-patched`
- Upstream: [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent), distributed as `nousresearch/hermes-agent`
- Licence: [MIT](https://github.com/NousResearch/hermes-agent/blob/main/LICENSE), copyright Nous Research
- Source: an image tagged `<tag>-p<date>` contains Hermes Agent release `<tag>`, whose source is at `https://github.com/NousResearch/hermes-agent/tree/<tag>`

The upstream image also contains software that Hermes bundles (among others Node.js, Chromium, SQLite, and Python and JavaScript packages), each under its own licence.

## signal-cli

- Image: `ghcr.io/blissful-living/signal-cli-distroless`
- Upstream: [AsamK/signal-cli](https://github.com/AsamK/signal-cli), distributed as `ghcr.io/asamk/signal-cli:<version>-native`
- Licence: [GNU General Public License v3.0](https://github.com/AsamK/signal-cli/blob/master/LICENSE)
- Source: an image tagged `<version>-p<date>` contains the unmodified native binary of signal-cli release `<version>`. Its complete corresponding source is the upstream release at `https://github.com/AsamK/signal-cli/tree/v<version>`, with source archives at `https://github.com/AsamK/signal-cli/releases/tag/v<version>`. For example, for `0.14.8-p20260927` that is [v0.14.8](https://github.com/AsamK/signal-cli/tree/v0.14.8).

The binary includes the Java libraries signal-cli depends on, each under its own licence as listed by the upstream project.

## Debian and distroless

- The Hermes image is based on Debian 13; the signal-cli image is based on [distroless](https://github.com/GoogleContainerTools/distroless) `cc-debian13`, which is built from Debian packages. Distroless is licensed under the [Apache License 2.0](https://github.com/GoogleContainerTools/distroless/blob/main/LICENSE).
- Each Debian package is under its own licence, recorded in the image at `/usr/share/doc/<package>/copyright`.
- The exact package versions are listed in each image's SBOM. Their source is available from Debian at [sources.debian.org](https://sources.debian.org) and, for any past version, [snapshot.debian.org](https://snapshot.debian.org).
