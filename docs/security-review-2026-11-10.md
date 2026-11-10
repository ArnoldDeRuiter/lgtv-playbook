# Security review 2026-11-10: TV findings

Nothing on the TV was changed or logged into. The only test was a TCP connect probe of two ports.

- `tvtje` is `192.168.1.120` (the `~/.ssh/config` alias). `22/tcp` and `23/tcp` are both open.
- Port 23 is webosbrew's passwordless root telnet shell. Any device on `192.168.1.0/24` can get root on the TV
  without a key. The TV holds the F1TV and Family7 logins (`/var/lib/webosbrew/tv-credentials.json`), its MQTT
  password and root's `authorized_keys`.
- `ansible/files/telnet_bootstrap.py` and a comment in `ansible/site.yml` said `192.168.1.210`, which does not
  answer. Both now say `192.168.1.120`, which Captain fixed for the TV on 2026-11-10.

## Recommendations

1. Keep telnet for now: it is the documented recovery path when SSH is lost (TV-HANDOVER.md). Do not disable
   it on the TV without a tested second way back in.
2. Limit who can reach it at the network level instead: a UniFi rule that allows TCP 22 and 23 to the TV only
   from the laptop and pikvm (Home Assistant), or move the TV to an IoT VLAN with that rule. This changes
   nothing on the TV, so it cannot brick it.
3. Give the TV a fixed DHCP lease in UniFi and make `telnet_bootstrap.py` read the address from the `tvtje`
   alias, so the recovery script cannot point at a stale IP.

## Limiting ports 22 and 23 in UniFi

Important first: **the gateway firewall only sees traffic that crosses between networks.** The laptop, pikvm
and the TV are all in `192.168.1.0/24`, so their traffic is switched, never routed, and no firewall rule on
the gateway can filter it. There are two ways to get a filter in between. Menu names differ a little between
UniFi Network versions.

### A. Put the TV in its own network (works on any UniFi gateway)

1. Settings -> Networks -> New Virtual Network, for example `IoT`, VLAN ID 20, `192.168.20.0/24`.
2. Move the TV to it: for a wired TV set the switch port's native network to `IoT`; for Wi-Fi create an SSID
   bound to `IoT` and join the TV to it. Give the TV a fixed IP in the new range.
3. Settings -> Security -> Firewall (zone-based on Network 9; "Firewall Rules, LAN In" on older versions).
   Create, in this order:
   - Allow: source laptop IP and pikvm (`192.168.1.110`), destination TV IP, TCP 22 and 23.
   - Allow: source TV IP, destination pikvm, TCP 8883 (MQTT) and UDP 514 (syslog).
   - Allow whatever else must reach the TV from the main network: Home Assistant's webOS integration
     (TCP 3000 and 3001), casting from phones.
   - Block: source any, destination TV IP, TCP 22 and 23.
4. Turn on mDNS between the two networks (Settings -> Networks -> Multicast DNS) if casting or discovery
   should keep working.
5. Update what points at the old address: the `tvtje` alias, `TV_IP` in `telnet_bootstrap.py`, Home Assistant
   and pikvm-playbook's TV settings.

This is the larger change, and it is the one that also keeps every other IoT device away from Unraid.

### B. Switch ACL, TV stays where it is (needs UniFi switches that support ACLs)

Settings -> Security -> Access Control (ACL), IP ACL rules, in this order:

- Allow: source laptop IP, destination `192.168.1.120`, TCP 22-23.
- Allow: source `192.168.1.110`, destination `192.168.1.120`, TCP 22-23.
- Block: source any, destination `192.168.1.120`, TCP 22-23.

It only filters traffic that passes through a UniFi switch that supports ACLs. Two Wi-Fi clients on the same
access point talk to each other without touching a switch, so this does not cover a Wi-Fi TV against other
Wi-Fi devices.

Either way, give the laptop a fixed IP first, or the allow rule follows a lease that changes. Nothing in A or B
changes anything on the TV itself. After either one, check from the laptop that SSH and the telnet bootstrap
still connect, and from another device that `nmap -p 22,23 <tv ip>` shows them filtered.
