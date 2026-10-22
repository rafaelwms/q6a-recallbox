#!/bin/sh
# Take a screenshot of whatever is on the HDMI output right now (EmulationStation menus included), as a 1080p PNG.
# Reads the DRM scanout plane with ffmpeg's kmsgrab (the framebuffer is linear, so it can be read directly).
# Run it on the board over SSH:   ssh root@<board-ip> 'sh -s' < q6a-screenshot.sh     or copy it to the board and run it there.
# The PNG goes to /recalbox/share/screenshots/ (the "screenshots" network share); the path is printed.
OUT=/recalbox/share/screenshots/frontend-$(date +%Y%m%d-%H%M%S).png
mkdir -p /recalbox/share/screenshots
# the scanout buffer alternates between ARGB8888 (bgra) and XRGB8888 (bgr0): try both
for fmt in bgra bgr0; do
  if ffmpeg -hide_banner -loglevel error -y -device /dev/dri/card1 -f kmsgrab -i - -vf "hwdownload,format=$fmt" -frames:v 1 "$OUT" 2>/dev/null; then
    echo "$OUT"; exit 0
  fi
done
echo "screenshot failed" >&2; exit 1
