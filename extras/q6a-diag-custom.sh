#!/bin/bash
# Radxa Dragon Q6A diagnostics (temporary; delete this file to disable).
# Keeps the kernel log and a 5-second heartbeat on the SHARE so that a freeze or a display glitch leaves evidence:
#   /recalbox/share/system/logs/q6a-kernel.log   (current boot)   + .1.log / .2.log (previous boots)
L=/recalbox/share/system/logs
K=$L/q6a-kernel.log
case "$1" in
  start)
    ( bash /recalbox/share/system/q6a-audiofix.sh >/dev/null 2>&1 & )
    mkdir -p "$L"
    rm -f "$L/q6a-kernel.2.log"
    [ -f "$L/q6a-kernel.1.log" ] && mv "$L/q6a-kernel.1.log" "$L/q6a-kernel.2.log"
    [ -f "$K" ] && mv "$K" "$L/q6a-kernel.1.log"
    mountpoint -q /sys/kernel/debug || mount -t debugfs none /sys/kernel/debug 2>/dev/null
    ( cat /dev/kmsg >> "$K" 2>/dev/null & )
    ( while true; do
        [ "$(stat -c %s "$K" 2>/dev/null || echo 0)" -gt 52428800 ] && exit 0
        mode=$(grep -h -m1 'mode:' /sys/kernel/debug/dri/*/state 2>/dev/null | head -1 | cut -c1-48)
        echo "HB $(date '+%m-%d %H:%M:%S') up=$(cut -d' ' -f1 /proc/uptime) load=$(cut -d' ' -f1-3 /proc/loadavg) temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1) js=$(ls /dev/input/js* 2>/dev/null | wc -l) ra=$(pgrep -x retroarch | head -1) es=$(pgrep -x emulationstation | head -1) memkb=$(awk '/MemAvailable/{print $2}' /proc/meminfo) $mode" >> "$K"
        sync
        sleep 5
      done & )
    ;;
esac
exit 0
