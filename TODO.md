# TODO

- [ ] Ship the TV's syslog to the PiKVM receiver (192.168.1.110 UDP 514, pikvm-playbook `roles/syslog_receiver`, lands in a per-host dir there). Check what webOS has (busybox `syslogd -R`, or `logger -n` from a boot script), add it to `ansible/site.yml`, test live, confirm the host dir appears on the PiKVM. Also tracked in unraid-playbook `docs/TODO.md`.
