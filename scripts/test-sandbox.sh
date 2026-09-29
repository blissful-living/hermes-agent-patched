#!/usr/bin/env bash
# Tests a built SSH sandbox image as Hermes' ssh backend uses it, with a host
# key and an authorized key supplied the way the entrypoint expects:
#   - the server presents the supplied host key, and the agent logs in with
#     the supplied key and finds bash, Python 3, git, curl and ripgrep;
#   - the agent cannot read the host key, change its authorized keys or
#     become root, and owns its private home;
#   - root logins, passwords, forwarded environment and TCP forwarding are
#     refused, and files transfer over scp (SFTP);
#   - its Debian package database is consistent, with any Debian update still
#     pending listed for review, as for the Hermes image.
#
# Usage: test-sandbox.sh <image>
# Needs the OpenSSH client.
set -euo pipefail

image=$1
here=$(dirname "$0")
work=$(mktemp -d)
name="sandbox-test-$$"
port=22222

cleanup() {
  docker rm -f "$name" > /dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

mkdir -m 0700 "$work/sandbox"
ssh-keygen -q -t ed25519 -N '' -C test-host -f "$work/sandbox/host_ed25519_key"
ssh-keygen -q -t ed25519 -N '' -C test-client -f "$work/client"
cp "$work/client.pub" "$work/sandbox/authorized_keys"
echo "[127.0.0.1]:$port $(cut -d' ' -f1-2 "$work/sandbox/host_ed25519_key.pub")" > "$work/known_hosts"

# docker cp creates the files owned by root, as a platform writing them at
# start does; a bind mount would keep the host user's ownership.
docker create --name "$name" -p "127.0.0.1:$port:2222" "$image" > /dev/null
docker cp "$work/sandbox/." "$name:/etc/sandbox/"
docker start "$name" > /dev/null

opts=(-p "$port" -i "$work/client" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes
      -o "UserKnownHostsFile=$work/known_hosts" -o ConnectTimeout=5 -o LogLevel=ERROR)
# shellcheck disable=SC2029 # callers pass single-quoted commands for the sandbox
as_agent() { ssh "${opts[@]}" agent@127.0.0.1 "$@"; }

for _ in $(seq 1 30); do
  as_agent true 2> /dev/null && break
  sleep 1
done

# Logs in with the pinned host key, as the agent, with the tools Hermes uses.
[ "$(as_agent 'id -un')" = agent ]
as_agent 'bash --version | head -n 1; python3 --version; git --version; curl --version | head -n 1; rg --version | head -n 1'

# The agent cannot read the host key, change its keys or become root, and its
# home is its own and private.
as_agent 'test ! -r /etc/ssh/ssh_host_ed25519_key && test ! -r /etc/sandbox/host_ed25519_key'
as_agent 'test ! -w /etc/ssh/authorized_keys/agent && test ! -w /etc/ssh/authorized_keys'
as_agent '! command -v sudo'
[ "$(as_agent 'stat -c "%U %a" /home/agent')" = "agent 700" ]

# Refused: root, passwords, forwarded environment and TCP forwarding.
if ssh "${opts[@]}" root@127.0.0.1 true 2> /dev/null; then echo "root login accepted" >&2; exit 1; fi
if ssh "${opts[@]}" -o PreferredAuthentications=password,keyboard-interactive agent@127.0.0.1 true 2> /dev/null; then
  echo "password login accepted" >&2; exit 1
fi
[ "$(ssh "${opts[@]}" -o SetEnv=SANDBOX_TEST=leaked agent@127.0.0.1 'echo "${SANDBOX_TEST:-unset}"')" = unset ]
if ssh "${opts[@]}" -W 127.0.0.1:2222 agent@127.0.0.1 < /dev/null > /dev/null 2>&1; then
  echo "TCP forwarding accepted" >&2; exit 1
fi

# Files transfer over scp, which uses SFTP.
head -c 100000 /dev/urandom > "$work/blob"
scp -q -P "$port" -i "$work/client" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes \
  -o "UserKnownHostsFile=$work/known_hosts" "$work/blob" agent@127.0.0.1:blob
[ "$(as_agent 'sha256sum blob' | cut -d' ' -f1)" = "$(sha256sum "$work/blob" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$work/blob" | cut -d' ' -f1)" ]

# Debian's package database is consistent; pending updates are shown, not
# treated as a failure.
docker run --rm --entrypoint sh "$image" -c 'dpkg --audit && apt-get check -qq'
status="$work/status"
docker run --rm --entrypoint cat "$image" /var/lib/dpkg/status > "$status"
pending=$("$here/pending-debian-updates.sh" "$status")
if [ -n "$pending" ]; then
  echo "$pending"
fi
echo "Debian updates pending after the upgrade: $(printf '%s' "$pending" | grep -c '^' || true)"
echo "Sandbox tests passed."
