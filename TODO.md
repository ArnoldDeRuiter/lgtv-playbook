# TODO

- [ ] Ship the TV's syslog to the PiKVM receiver (192.168.1.110 UDP 514, pikvm-playbook `roles/syslog_receiver`, lands in a per-host dir there). Glasshouse has built-in syslog: set `"syslog": {"server": "192.168.1.110", "port": 514, "hostname": "lgtv", "sources": ["system", "glasshouse"], "redact": true}` in the TV's `/var/lib/tvweb/config.json`, restart tvweb, check `logs/lgtv/` on pikvm. Keep `kernel` off (TV memory-tight). Put it in `ansible/site.yml`. Test live. Also tracked in unraid-playbook `docs/TODO.md`.
