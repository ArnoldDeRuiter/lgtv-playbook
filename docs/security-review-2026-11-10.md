# Security review 2026-11-10: TV findings

Nothing on the TV was changed or logged into. The only test was a TCP connect probe of two ports.

- `tvtje` is `192.168.1.120` (the `~/.ssh/config` alias). `22/tcp` and `23/tcp` are both open.
- Port 23 is webosbrew's passwordless root telnet shell. Any device on `192.168.1.0/24` can get root on the TV
  without a key. The TV holds the F1TV and Family7 logins (`/var/lib/webosbrew/tv-credentials.json`), its MQTT
  password and root's `authorized_keys`.
- `ansible/files/telnet_bootstrap.py` and a comment in `ansible/site.yml` still say `192.168.1.210`. That
  address does not answer; the bootstrap would fail, or reach another device if one gets that lease.

## Recommendations

1. Keep telnet for now: it is the documented recovery path when SSH is lost (TV-HANDOVER.md). Do not disable
   it on the TV without a tested second way back in.
2. Limit who can reach it at the network level instead: a UniFi rule that allows TCP 22 and 23 to the TV only
   from the laptop and pikvm (Home Assistant), or move the TV to an IoT VLAN with that rule. This changes
   nothing on the TV, so it cannot brick it.
3. Give the TV a fixed DHCP lease in UniFi and make `telnet_bootstrap.py` read the address from the `tvtje`
   alias, so the recovery script cannot point at a stale IP.
