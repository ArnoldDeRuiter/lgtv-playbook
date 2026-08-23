Draft issue for https://github.com/mareklarek/webos10-homescreen-customization

Status: written, not confirmed posted.

---

**Title:** Works wonders, but is slow to take effect after boot (LG G5 Evo, webOS 26)

**Body:**

Great writeup, got this working exactly as documented — background swap, shelf/qcard removal, nav toggle, all working on an LG G5 (2025 OLED), webOS TV 10.3.1 (marketing name webOS 26). Thanks for putting this together.

One thing worth documenting/investigating: there's a noticeable delay between TV power-on and the customized home screen actually appearing — long enough that it initially looks like the boot hook didn't fire at all.

**What I checked:** confirmed via SSH that `home.xml` was already correctly overlaid and the bind-mount was in place well before the Home app's process had been running very long — comparing `/proc/uptime` to the Home app process's `etime` showed it launched about 29s after boot, already carrying the custom `home.xml` (no double-launch/flash-of-stock-then-switch happening). So the delay isn't the script failing or re-running — it's that the whole boot chain (root elevation → webosbrew's `init.d` run-parts → `apply.sh` → Home app relaunch) has to complete before anything shows, and that chain doesn't start until fairly late in the TV's own boot sequence.

**Possible contributor:** `apply.sh` does a full recursive `cp -R` of the entire Home app's `flutter_assets/assets` directory into `/tmp` on every single boot before it can bind-mount over it — on my TV that's **28.7MB across 525 files**, copied in full even though only `home.xml` (and optionally a couple of images/i18n files) actually change. That's pure overhead on top of whatever the baseline webOS boot time already is.

**Possible fix:** the kernel here does support a real overlay filesystem (`overlay` shows up in `/proc/filesystems`), so instead of manually copying the whole tree and bind-mounting the copy, `apply.sh` could use an actual `mount -t overlay` with the real assets dir as `lowerdir` and a small writable dir (holding only the modified files) as `upperdir`/`workdir`. That would avoid duplicating the ~500 unmodified files on every boot and should cut the script's own contribution to the delay, even if most of the total wait turns out to be generic webOS boot sequencing that's outside this project's control either way.

Might also be worth a line in the README setting expectations that there's an inherent delay here regardless (root services have to come up before any `init.d` hook can even run), so people don't assume it's broken when it just hasn't shown up yet.
