# TODO

- [x] 2026-11-08: TV syslog to the PiKVM receiver. `ansible/site.yml` sets only the keys in `glasshouse_config` of `/var/lib/tvweb/config.json` (`glasshouse_config` var, sources `system`, `glasshouse` and `kernel`) and restarts tvweb when it changed. Logs land in pikvm `logs/lgtv/`; pikvm syslog-ng reparses Glasshouse's RFC 5424 lines (`p_rfc5424`).
