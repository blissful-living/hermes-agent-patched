# Third-party notices

The images published from this repository redistribute the following software. Apart from the Debian package upgrades in the Hermes and SSH sandbox images, and the SSH server configuration and entrypoint in the sandbox, each is redistributed unmodified; this repository's MIT licence does not apply to it.

## Hermes Agent

- Image: `ghcr.io/blissful-living/hermes-agent-patched`
- Upstream: [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent), distributed as `nousresearch/hermes-agent`
- Licence: [MIT](https://github.com/NousResearch/hermes-agent/blob/main/LICENSE), copyright Nous Research
- Source: an image tagged `<tag>-p<date>` contains Hermes Agent release `<tag>`, whose source is at `https://github.com/NousResearch/hermes-agent/tree/<tag>`

The upstream image also contains software that Hermes bundles (among others Node.js, Chromium, SQLite, and Python and JavaScript packages), each under its own licence.

## tirith

- Image: `ghcr.io/blissful-living/hermes-agent-patched`, at `/usr/local/bin/tirith`
- Upstream: [sheeki03/tirith](https://github.com/sheeki03/tirith), the release archive `tirith-x86_64-unknown-linux-gnu.tar.gz`
- Licence: [GNU Affero General Public License v3.0](https://github.com/sheeki03/tirith/blob/main/LICENSE-AGPL) (tirith is also offered under a commercial licence, which does not apply here)
- Source: `tirith --version` in the image names the release; its complete corresponding source is at `https://github.com/sheeki03/tirith/tree/v<version>`. The release the image is built from is the `TIRITH_VERSION` argument in [images/hermes-agent-patched/Containerfile](images/hermes-agent-patched/Containerfile).

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

## Debian packages in the SSH sandbox

- Image: `ghcr.io/blissful-living/hermes-ssh-sandbox`
- Upstream: [Debian 13](https://www.debian.org/releases/trixie/), distributed as `debian:13-slim`, with the packages `openssh-server`, `bash`, `python3`, `git`, `curl`, `ripgrep`, `procps` and `ca-certificates` and their dependencies installed from Debian's archive
- Licences: each package's own, recorded in the image under `/usr/share/doc/<package>/copyright` and in the image's SBOM
- Source: every package's source is in Debian's archive; `apt-get source <package>` or [sources.debian.org](https://sources.debian.org) gives the exact version the image's package database names
