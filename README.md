# LG webOS TV — rooting & customization notes

TV: `tvtje` (DHCP, the IP drifts; the alias in `~/.ssh/config` is the source of truth, currently 192.168.1.120), LG G5 (2025 OLED), webOS TV 10.3.1 (marketing
name "webOS 26"). Rooted via [SlopBro](https://github.com/throwaway96/slopbro)
(separate repo — the exploit/root tooling itself is out of scope here).

## Reapply everything with one command

```sh
ansible-playbook ansible/site.yml
```

Idempotent, safe to rerun any time (e.g. after a factory reset + re-root, or
just to confirm nothing drifted). Covers: SSH access, the custom home screen
(below), removal of dead boot hooks, the AmazOff autostart toggle, the
login-autofill credentials, and Glasshouse (installed or updated from
`~/git/personal/glasshouse` when its commit differs from the build on the TV;
its `config.json` with the MQTT settings is left alone, see below).
See `ansible/site.yml` for the exact task list and what it deliberately does
**not** manage (listed at the bottom of that file).

The TV itself has no Python — the playbook runs from `localhost` and shells
out to `ssh`/`scp` against the `tvtje` alias in `~/.ssh/config` rather than
using normal Ansible remote modules.

## What's in this folder

- **`ansible/`** — the playbook above, plus `files/telnet_bootstrap.py` (used
  only if SSH isn't already reachable — falls back to the always-on
  passwordless telnet root shell webosbrew ships to re-establish it).
- **`homescreen/`** — the custom home-screen override (bind-mount overlay
  over the stock Flutter Home app): working copy of `apply.sh` +
  `assets/home.xml` + wallpaper images + i18n edits, and its own README with
  manual enable/disable/re-apply commands if you don't want to go through
  Ansible. **This is also the basis for the separate `webos-home-customizer`
  app repo** (packaged, installable version of the same two presets) — see
  below.
- **`glasshouse/`** — backup of the [Glasshouse](https://github.com/rorygallagher2024/glasshouse)
  dashboard/MQTT bridge running on the TV (`tvweb`, dashboard on port 8080):
  `glasshouse-backup-OLED65G56LS.json.vault`, exported from the dashboard's
  backup function (Glasshouse 0.118.0, 2026-10-21) and encrypted with this
  repo's ansible-vault (the same `vault_password` as `vault.yml`). It holds
  the LG settings toggles, Glasshouse's own config, the home-screen layout and
  the app list. It has no MQTT broker or credentials (those live in
  `/var/lib/tvweb/config.json` on the TV, mode 600, and the broker side is in
  `pikvm-playbook`). To restore, decrypt it, then upload it on the dashboard's
  backup page:
  ```sh
  cd ansible && ansible-vault decrypt --output /tmp/glasshouse-backup.json ../glasshouse/glasshouse-backup-OLED65G56LS.json.vault
  ```
  To replace it after a new export: `ansible-vault encrypt --output ../glasshouse/glasshouse-backup-OLED65G56LS.json.vault <new-export.json>` (from `ansible/`), and delete the plaintext.
- **`github-issue-draft-mareklarek.md`** — drafted GitHub issue for the
  upstream guide's repo about the boot-time delay we diagnosed. Written,
  not confirmed posted yet.

## SSH access

Root, key-based, alias `tvtje` in `~/.ssh/config` on this machine
(`~/.ssh/id_ed25519_tvtje`). Set up by dropping the pubkey into
`/home/root/.ssh/authorized_keys` over the TV's always-on passwordless
telnet root shell (webosbrew's intentional emergency-access feature, not
something we broke into), then starting `dropbear` and flipping
`webosbrew_sshd_enabled`. Managed idempotently by the Ansible playbook now.

## Homebrew Channel repositories added

13 third-party repos added to Homebrew Channel's app-store list (via
Settings → Add repository), on top of the official `repo.webosbrew.org`:

```
https://webosappclub.github.io
https://syspoke.github.io
https://syspoke.github.io/backup.json/
https://syspoke.github.io/apps.json/
https://throwaway96.github.io/apps-repo/api/apps.json
https://tbsniller.github.io/apps-repo/api/apps.json
https://webosbrew.github.io/apps-repo/api/apps.json
https://raw.githubusercontent.com/webosbrew/docs/main/test/repo.json
https://itsrealm12c.github.io/launchingapps/
https://epsill.github.io/plugins/bylampa_test
https://raw.githubusercontent.com/NicholasBly/youtube-webos/main/repo.json
https://raw.githubusercontent.com/RF1705/youtube-webos-cobalt-adfree/main/repo.json
https://atlet99.github.io/rezkatv-public/repository.json
```

**Skipped on purpose** (flagged as risky before adding, never added):
- `tinyurl.com/lg-tiktok` — link-shortener hiding an unofficial modded TikTok
  APK; shorteners get repointed after the fact, classic bait-and-switch risk.
- `pastebin.com/raw/YuSSrivd` — pastebin content is editable by its owner at
  any time after you've trusted it as a repo source.

**Known issue**: `itsrealm12c.github.io/launchingapps/` serves genuinely
malformed JSON upstream (missing `}`/`,` between two package entries around
the `vlc.lgapp` entry) — not fixable on our end, repo just won't load until
the maintainer patches their file.

**Flagged for removal, not yet confirmed removed**: `webosappclub.github.io`
and `atlet99.github.io/rezkatv-public` are almost entirely Russian-market
region-exclusive apps / a piracy-streaming brand (RezkaTV) — Captain asked
how to remove these; the how-to was given (Settings → repo list → remove),
but no automated removal path was found (same as adding, it needs a manual
tap), and it's unconfirmed whether this was actually done yet.

## Apps installed — current known state

- **AmazOff** (Prime Video ad-patcher) — working, ad-blocking active,
  autostart **on** (toggled via its own `patchctl.sh autostart_toggle`,
  managed idempotently by the Ansible playbook).
- **Sound Mode Fix** — installed, then fully **uninstalled** by Captain.
- **Custom Screensaver** (`org.webosbrew.custom-screensaver`) — installed,
  but its `apply.sh` fails every run: targets the pre-webOS-10 QML
  screensaver path, which no longer exists now that LG's screensaver is
  Flutter-based. Its boot hook was removed (dead weight, was failing
  silently every boot); the app itself is still installed, just inert.
- **Aerial screensaver** (`org.aabytt.webos.custom-screensaver-aerial`) —
  install was attempted at some point but the app directory is gone; same
  underlying incompatibility as above, looks like it failed/rolled back.
- **LG Input Hook** — installed, used to remap physical remote buttons
  (find a button's numeric ID via its on-screen log view, then remap/disable
  it in its "Add keybind" screen). Relevant because this TV's remote is the
  stripped-down variant with no pointer and very few buttons.
- **Glasshouse** (`tvweb`, dashboard on port 8080, MQTT bridge to Home
  Assistant) — installed via its own `server/deploy.sh`, which the playbook
  runs (section 5 of `site.yml`) only when the local clone's commit differs
  from `/var/lib/tvweb/build.json` on the TV. `/var/lib/tvweb/config.json`
  (broker, topics, dashboard settings) is TV-owned and not managed here; the
  broker side is in `pikvm-playbook` (`docs/mosquitto-tls.md`). Glasshouse
  Home (taking over LG Home) was tried and switched off: it leaves no home
  screen for the first ~minute after boot. LG's Automatic Standby is set to
  2 hours (`automaticStandBy` in the `time` settings category), which is what
  shows "TV will be turned off in 5 minutes" after 2 h without remote input.
- **NPO Start (black)** (`nl.arnolderuiter.npo`) — own app, see the
  `npo-webos` repo; installed through the Homebrew Channel, not by this playbook.
- **Custom home screen** — see `homescreen/`, below.

## Custom home screen

Bind-mount overlay over the stock Home app's Flutter assets (nothing on the
signed system partition touched, always fully reversible). Full details,
manual enable/disable commands, and what's provably *not* possible this way
(icon labels, focus-zoom animation, wallpaper behind the app row — all
hardcoded in the compiled `libapp.so`) are in `homescreen/README.md`.

Packaged as an actual installable Homebrew Channel app, with the two proven
presets ("Full banner" / "Compact") as pick-and-apply tiles instead of manual
SSH: **[`webos-home-customizer`](../webos-home-customizer/)** — separate
repo, git-committed locally, not yet pushed to GitHub (destined for
`github.com/ArnoldDeRuiter/webos-home-customizer`).

## Home Assistant integration

Already wired up in the `pikvm-playbook` repo, not duplicated here — see
`../pikvm-playbook/docs/ha-dashboard-via-api.md`. Entity:
`media_player.living_room_tvtje`, using HA's core `webostv` integration.
Notably: `webostv.button` already supports the color buttons (`GREEN` etc.)
natively — no custom work needed for that, confirmed live.
