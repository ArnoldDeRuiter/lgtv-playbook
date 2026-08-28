#!/bin/sh
set -e -x

ASSETS_DIR=/usr/palm/applications/com.webos.app.home/data/flutter_assets/assets
OVERRIDE_DIR=/media/developer/apps/usr/palm/applications/tld.my.customhome/assets
UPPER_DIR=/tmp/weboshome-overlay-upper
WORK_DIR=/tmp/weboshome-overlay-work

# Boot-time timing investigation (see the mareklarek/webos10-homescreen-customization
# issue): appends this run's kernel uptime to a persistent log (survives reboots,
# unlike /tmp) so several boots' worth of "how late does this hook actually fire"
# data can be compared later. Safe/read-only from the system's perspective --
# just one append to a file nothing else reads.
echo "$(date -Iseconds 2>/dev/null || date) uptime=$(cat /proc/uptime)" >> /var/lib/webosbrew/homescreen-boot-timing.log

# Overlay the real assets dir with just the handful of files we actually
# change, instead of copying the whole ~500-file/28MB tree into /tmp on
# every boot before bind-mounting the copy over the original. Only the
# files placed in upperdir need to exist there; everything else is served
# straight from the real assets dir (lowerdir) with no copying at all.
umount "$ASSETS_DIR" 2>/dev/null || true
rm -rf "$UPPER_DIR" "$WORK_DIR"
mkdir -p "$UPPER_DIR/images/hd" "$UPPER_DIR/images/2k" "$UPPER_DIR/images/4k" "$UPPER_DIR/i18n" "$WORK_DIR"

cp "$OVERRIDE_DIR/home.xml" "$UPPER_DIR/home.xml"
cp "$OVERRIDE_DIR/images/hd/bg_banner_img.png" "$UPPER_DIR/images/hd/bg_banner_img.png"
cp "$OVERRIDE_DIR/images/2k/bg_banner_img.png" "$UPPER_DIR/images/2k/bg_banner_img.png"
cp "$OVERRIDE_DIR/images/4k/bg_banner_img.png" "$UPPER_DIR/images/4k/bg_banner_img.png"

# i18n in the real assets dir is a symlink, not a plain directory -- a real
# directory placed in upperdir shadows it by name regardless of type, same
# as the old approach's rm+replace, so this doesn't need special handling.
cp -R "$OVERRIDE_DIR/i18n/." "$UPPER_DIR/i18n/"

mount -t overlay overlay -o lowerdir="$ASSETS_DIR",upperdir="$UPPER_DIR",workdir="$WORK_DIR" "$ASSETS_DIR"
pkill -f com.webos.app.home || true
