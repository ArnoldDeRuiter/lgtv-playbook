# TODO

- [x] 2026-11-08: TV syslog to the PiKVM receiver. `ansible/site.yml` sets only the `syslog` key of `/var/lib/tvweb/config.json` (`glasshouse_syslog` var, sources `system` + `glasshouse`, kernel off) and restarts tvweb when it changed. Logs land in pikvm `logs/lgtv/`; pikvm syslog-ng reparses Glasshouse's RFC 5424 lines (`p_rfc5424`).
