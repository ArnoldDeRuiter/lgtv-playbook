# TODO

- [x] 2026-11-08: TV syslog to the PiKVM receiver. `ansible/site.yml` sets only the keys in `glasshouse_config` of `/var/lib/tvweb/config.json` (`glasshouse_config` var, sources `system`, `glasshouse` and `kernel`) and restarts tvweb when it changed. Logs land in pikvm `logs/lgtv/`; pikvm syslog-ng reparses Glasshouse's RFC 5424 lines (`p_rfc5424`).

## Hue Sync (LG TV app) - decide, then install and set up

- [ ] Decide whether Hue Sync is worth it here; only then buy/install. Checked 2026-11-08, nothing bought or installed yet.

**What it is:** Philips' own *Hue Sync TV* app from the LG Content Store. The TV analyses its own picture and drives Philips Hue colour lights in real time (a Hue Entertainment area), for every source: built-in apps (F1TV, Netflix, ...) and HDMI. No HDMI Sync Box needed. Once installed, Glasshouse adds a `switch.lg_g5_huesync` to HA (start/stop syncing), so it can go on the LG G5 dashboard or into automations.

**Requirements:**
- LG TV on webOS 24 or later: the G5 (webOS 26) qualifies.
- A **Philips Hue Bridge** plus at least one **colour-capable Hue light** in an Entertainment area. The app talks only to the Bridge's Entertainment API.
- Internet, and a paid app bought on the TV (one-off and/or subscription per Philips' pages, tied to this one TV, 14-day refund). Check the current price on the TV before buying.

**Does it work with just HA + Zigbee2MQTT? No.** There is no Hue Bridge here (the Hue dimmer is paired to Zigbee2MQTT, see pikvm-playbook `automations.yaml`). Lights paired to Z2M are invisible to Hue Sync. Options:
1. Buy a Hue Bridge and move the Hue colour lights that should sync from Z2M to the Bridge. HA keeps controlling them through its Philips Hue integration (local API), but they leave Z2M, so Z2M groups/automations that use them must move to the Hue entities. Non-Hue Zigbee bulbs can't join the Entertainment sync.
2. Skip Hue Sync and finish the local, free Ambilight pipeline that's already half deployed: PicCap (on the TV) -> Hyperion.NG (pikvm) -> WLED strip, see pikvm-playbook `docs/ambilight-setup.md`. No cloud, no subscription. Driving Z2M bulbs from it is not built in and would need separate research.

**Gain vs. option 2:** official, zero-maintenance, works on DRM apps/HDR the TV can see, and HA control via Glasshouse. Cost: Bridge + app, cloud account, and moving lights off Z2M.

## Glasshouse sensors this G5 doesn't get (checked 2026-11-08)

- [ ] Optional upstream Glasshouse issue (draft only, Captain posts): **Ambient Light** never appears because Glasshouse asks `com.webos.service.tv.display/getLightSensorData`, and on webOS 10 that service doesn't exist ("Service does not exist"). LG OLEDs normally have an ambient light sensor for automatic brightness (not verified on this G5), so it is likely there behind an API Glasshouse doesn't know. Finding the webOS 10 equivalent would need luna-service research first.
- GPU Clock: Glasshouse reads `gpu pll out` from `/proc/lg/sys/status`, which this SoC doesn't print. The GPU's devfreq node (`/sys/class/devfreq/f5000000.gpu`) shows a single fixed 700 MHz (`available_frequencies` = 700000000), so the sensor would be a constant: nothing to do.
