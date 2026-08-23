#!/bin/sh
set -e -x

ASSETS_DIR=/usr/palm/applications/com.webos.app.home/data/flutter_assets/assets
OVERRIDE_DIR=/media/developer/apps/usr/palm/applications/tld.my.customhome/assets

umount "$ASSETS_DIR" 2>/dev/null || true
rm -rf /tmp/weboshome-merged
mkdir /tmp/weboshome-merged
cp -R --no-dereference "$ASSETS_DIR"/. /tmp/weboshome-merged/

cp "$OVERRIDE_DIR/home.xml" /tmp/weboshome-merged/home.xml
cp "$OVERRIDE_DIR/images/hd/bg_banner_img.png" /tmp/weboshome-merged/images/hd/bg_banner_img.png
cp "$OVERRIDE_DIR/images/2k/bg_banner_img.png" /tmp/weboshome-merged/images/2k/bg_banner_img.png
cp "$OVERRIDE_DIR/images/4k/bg_banner_img.png" /tmp/weboshome-merged/images/4k/bg_banner_img.png

rm /tmp/weboshome-merged/i18n
cp -R "$OVERRIDE_DIR/i18n" /tmp/weboshome-merged/i18n

mount --bind /tmp/weboshome-merged "$ASSETS_DIR"
pkill -f com.webos.app.home || true
