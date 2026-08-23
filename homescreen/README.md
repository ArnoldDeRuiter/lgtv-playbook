# LG webOS 10 custom home screen — enable / disable

> Everything below can also be reapplied in one shot with
> `ansible-playbook ../ansible/site.yml` — idempotent, safe to rerun any
> time (e.g. after a factory reset + re-root). See `../ansible/site.yml`
> for what it covers.

TV: `tvtje` (192.168.1.210), webOS TV 10.3.1, rooted via [SlopBro](https://github.com/throwaway96/slopbro).
Method: [mareklarek/webos10-homescreen-customization](https://github.com/mareklarek/webos10-homescreen-customization)
(bind-mount overlay over the Home app's read-only Flutter assets — nothing on the
signed system partition is ever touched, so this is always fully reversible).

## How it's wired up

- Override files live on the TV at:
  `/media/developer/apps/usr/palm/applications/tld.my.customhome/`
  (`apply.sh` + `assets/home.xml` + `assets/images/{hd,2k,4k}/bg_banner_img.png` +
  `assets/i18n/*.json`)
- A symlink in webosbrew's boot-hook folder makes it run on every boot:
  `/var/lib/webosbrew/init.d/01-custom-homescreen -> .../tld.my.customhome/apply.sh`
- `apply.sh` copies the real Home-app assets to `/tmp`, overlays our modified
  `home.xml` / images / i18n on top, then `mount --bind`s that over the real
  (read-only) assets directory and kills `com.webos.app.home` so it relaunches
  with the new files.
- The bind mount lives in `/tmp`, which is wiped every reboot — that's *why* the
  boot-hook symlink is needed for this to persist at all. Delete the symlink and
  the very next reboot goes back to 100% stock, no other cleanup required.

A local copy of the current override files is kept in this folder
(`apply.sh`, `assets/`) so you can inspect/edit them without SSHing in first.

## Disable (revert to stock)

Two ways, pick based on whether you want it back instantly or after next reboot:

**Instant revert (no reboot):**
```sh
ssh tvtje 'umount /usr/palm/applications/com.webos.app.home/data/flutter_assets/assets; pkill -f com.webos.app.home'
```

**Revert on next reboot** (also stops it coming back after future reboots):
```sh
ssh tvtje 'rm /var/lib/webosbrew/init.d/01-custom-homescreen'
```
Run both together if you want it gone immediately *and* permanently.

Nothing about `tld.my.customhome/` needs deleting to disable it — it's just an
inert folder of scripts/assets once the boot-hook symlink is gone. It won't show
up as an "app" in Homebrew Channel either; it was never installed as one, just a
folder + a boot hook.

## Re-enable

If you only ran the "instant revert" command above (boot-hook symlink still
there), just reboot the TV, or reapply live without rebooting:
```sh
ssh tvtje 'sh /media/developer/apps/usr/palm/applications/tld.my.customhome/apply.sh'
```

If you deleted the boot-hook symlink too, recreate it first:
```sh
ssh tvtje 'ln -sf /media/developer/apps/usr/palm/applications/tld.my.customhome/apply.sh /var/lib/webosbrew/init.d/01-custom-homescreen'
ssh tvtje 'sh /media/developer/apps/usr/palm/applications/tld.my.customhome/apply.sh'
```

## Fully remove (delete the override files too)

```sh
ssh tvtje 'rm -f /var/lib/webosbrew/init.d/01-custom-homescreen; umount /usr/palm/applications/com.webos.app.home/data/flutter_assets/assets 2>/dev/null; pkill -f com.webos.app.home; rm -rf /media/developer/apps/usr/palm/applications/tld.my.customhome'
```

## Making further edits

- `assets/home.xml` controls layout: banner size, nav column, app-row position,
  margins. Edit the copy in this folder, `scp` it to
  `.../tld.my.customhome/assets/home.xml` on the TV, then rerun `apply.sh`
  (no reboot needed to preview).
- To change the wallpaper: source image needs to be cropped to whatever aspect
  ratio the `herobanner` item in `home.xml` currently uses
  (`itemWidth`/`itemHeight` — as of this writing `3540x1727`), then rendered to
  three sizes (`4k` = exact box size, `2k` = ~0.5x, `hd` = ~0.362x) as PNG into
  `assets/images/{hd,2k,4k}/bg_banner_img.png`. Ask Claude to redo this step if
  you change the banner box size — the numbers only line up if the source image
  is cropped to match.
- To change/hide overlay text (the headline + button LG draws on top of the
  banner): edit the matching key in `assets/i18n/nl.json` (and `en.json` for
  safety) — set the value to `""` to hide it, or to custom text to replace it.
  Active TV language is `nl-NL`.
- What's **not** possible via this method (confirmed, not just untested):
  per-icon text labels on the app row, the icon focus-zoom animation, and a
  wallpaper behind the app row itself — all hardcoded in the compiled
  `libapp.so`, not exposed through any file this overlay technique can reach.

## Other boot hooks currently on this TV (unrelated to the above)

```sh
ssh tvtje 'ls -la /var/lib/webosbrew/init.d/'
```
Currently: `50-custom-amazoff` (AmazOff Prime Video ad-patcher — separate
feature, its own toggle lives in the AmazOff app itself), plus
`appupdateblocker` / `inputhook` (unrelated homebrew apps' own hooks).
