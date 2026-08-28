Follow-up on the delay, with a fix and some real numbers.

**Fix for the `cp -R` overhead:** switched `apply.sh` from copying the whole assets tree into `/tmp` before bind-mounting the copy, to an actual `mount -t overlay` with the real assets dir as `lowerdir` and a small writable dir holding just the changed files (`home.xml`, the 3 banner PNGs, `i18n/`) as `upperdir`. Unmodified files are served straight from the real directory, never copied.

```sh
ASSETS_DIR=/usr/palm/applications/com.webos.app.home/data/flutter_assets/assets
OVERRIDE_DIR=/media/developer/apps/usr/palm/applications/tld.my.customhome/assets
UPPER_DIR=/tmp/weboshome-overlay-upper
WORK_DIR=/tmp/weboshome-overlay-work

umount "$ASSETS_DIR" 2>/dev/null || true
rm -rf "$UPPER_DIR" "$WORK_DIR"
mkdir -p "$UPPER_DIR/images/hd" "$UPPER_DIR/images/2k" "$UPPER_DIR/images/4k" "$UPPER_DIR/i18n" "$WORK_DIR"

cp "$OVERRIDE_DIR/home.xml" "$UPPER_DIR/home.xml"
cp "$OVERRIDE_DIR/images/hd/bg_banner_img.png" "$UPPER_DIR/images/hd/bg_banner_img.png"
cp "$OVERRIDE_DIR/images/2k/bg_banner_img.png" "$UPPER_DIR/images/2k/bg_banner_img.png"
cp "$OVERRIDE_DIR/images/4k/bg_banner_img.png" "$UPPER_DIR/images/4k/bg_banner_img.png"
cp -R "$OVERRIDE_DIR/i18n/." "$UPPER_DIR/i18n/"

mount -t overlay overlay -o lowerdir="$ASSETS_DIR",upperdir="$UPPER_DIR",workdir="$WORK_DIR" "$ASSETS_DIR"
pkill -f com.webos.app.home || true
```

(`i18n` in the real assets dir is a symlink rather than a plain directory — a real directory placed in `upperdir` shadows it by name regardless of type, so no special handling needed there, same as the old approach's `rm`+replace.)

Measured directly on-device, old script vs new, back to back: **0.54s → 0.08s**, about 6.75x faster. Verified correct via a real cold reboot too — `overlay` mount present, `home.xml`/`i18n` content matches, unmodified files (`home_lg.xml`, `mock`, fonts, etc.) confirmed served straight from the real directory rather than copied.

**Where the rest of the delay actually comes from:** logged kernel uptime at the moment the hook fires across several real reboots — consistently 26.5-27.3s. To find out how much of that is inside `startup.sh`'s own sequence vs. before it even starts, I checked when `telnetd`/`dropbear` (both spawned by `startup.sh`, well before it gets to `run-parts`) actually start — since they're long-running daemons, their process start time stays checkable via `/proc/<pid>/stat` any time after boot, no editing of `startup.sh` required.

Both started at ~27.1s — essentially the same moment as the home-screen hook itself. That means everything in `startup.sh` from spawning those daemons onward (motd setup, root-password check, the telemetry-blocking mounts, HBChannel's own service elevation, then `run-parts`) completes in well under half a second. Accounting for the script's own `sleep 2` near the top, `startup.sh` itself must actually start running around ~24-25s post-boot.

So the ~26-29s delay isn't really inside `apply.sh`, `startup.sh`, or even `jumpstart.sh` — it's almost entirely *before* `jumpstart.sh` ever fires, i.e. generic webOS/LG boot sequencing before HBChannel's own root service even starts. That's outside this project's control (and outside anything I'd want to touch — `jumpstart.sh` explicitly warns it's part of the exploit chain and shouldn't be modified).

Given that, I think the fix above is the right scope: it's a real, verified win (script overhead down ~85%), and the remaining delay is a platform characteristic worth a line in the README so people don't think the hook is broken, rather than something worth chasing further.
