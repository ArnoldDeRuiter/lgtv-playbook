#!/usr/bin/env python3
"""One-shot SSH bootstrap for the rooted LG webOS TV over its passwordless
telnet failsafe shell (port 23) — used only when SSH isn't reachable yet.

Mirrors exactly what was run by hand over telnet in the 2026-08-21 session:
install our pubkey into root's authorized_keys, flag SSH as enabled, and
start dropbear directly (rather than waiting for a reboot to pick up the
webosbrew_sshd_enabled flag).
"""
import os
import socket
import sys
import time

TV_IP = "192.168.1.210"
PUBKEY_PATH = os.path.expanduser("~/.ssh/id_ed25519_tvtje.pub")
DROPBEAR_BIN = (
    "/media/developer/apps/usr/palm/services/"
    "org.webosbrew.hbchannel.service/bin/dropbear"
)


def main():
    with open(PUBKEY_PATH) as f:
        pubkey = f.read().strip()

    s = socket.create_connection((TV_IP, 23), timeout=10)
    time.sleep(1)
    s.recv(4096)  # drain telnet negotiation + shell prompt banner

    cmd = (
        "mkdir -p /home/root/.ssh && chmod 700 /home/root/.ssh && "
        f"printf '%s\\n' '{pubkey}' > /home/root/.ssh/authorized_keys && "
        "chmod 600 /home/root/.ssh/authorized_keys && "
        "chown 0:0 /home/root/.ssh/authorized_keys && "
        "touch /var/luna/preferences/webosbrew_sshd_enabled && "
        "mkdir -p /var/lib/webosbrew/sshd && "
        f"setsid {DROPBEAR_BIN} -R </dev/null >/dev/null 2>&1 & "
        "sleep 1; echo BOOTSTRAP_DONE\n"
    )
    s.sendall(cmd.encode())
    time.sleep(3)
    out = s.recv(8192).decode(errors="replace")
    s.close()

    if "BOOTSTRAP_DONE" not in out:
        print(out)
        sys.exit(1)
    print("telnet bootstrap: sshd started, pubkey installed")


if __name__ == "__main__":
    main()
