#!/bin/sh
# Starts the SSH server with a host key and authorized keys supplied from
# outside the image, in /etc/sandbox:
#   host_ed25519_key  the server's private host key; without it a key is
#                     generated for this start only, which a client that
#                     pins the host key then refuses after every restart
#   authorized_keys   the public keys allowed to log in as the agent;
#                     required
# Both are copied into place owned by root, as sshd requires, so they may be
# read-only mounts or files a platform writes at start. The supplied host key
# is then removed where it can be, leaving only the root-only copy.
set -eu

src=/etc/sandbox
chown root:root "$src" 2>/dev/null || true
chmod 0700 "$src" 2>/dev/null || true

if [ -s "$src/host_ed25519_key" ]; then
    install -o root -g root -m 0600 "$src/host_ed25519_key" /etc/ssh/ssh_host_ed25519_key
    rm -f "$src/host_ed25519_key" 2>/dev/null || true
else
    echo "[sandbox] no host key in $src; generating one for this start only" >&2
    rm -f /etc/ssh/ssh_host_ed25519_key
    ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key
fi

if [ ! -s "$src/authorized_keys" ]; then
    echo "[sandbox] no authorized keys in $src/authorized_keys; nobody could log in" >&2
    exit 1
fi
install -o root -g root -m 0644 "$src/authorized_keys" /etc/ssh/authorized_keys/agent

# A volume mounted over the agent's home starts out owned by root.
chown agent:agent /home/agent
chmod 0700 /home/agent

mkdir -p /run/sshd
echo "[sandbox] host key $(ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key)" >&2
exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config
