#!/bin/bash
# q6a-audiofix: self-heal the HDMI audio port start failure of the Radxa Dragon Q6A.
# Symptom: the DSP fails to start the DisplayPort audio port (kernel: "Failed to start APM port 104 ... DISPLAY_PORT_RX_0",
# ASoC error -22). PulseAudio still reports the sink RUNNING, nothing consumes the audio and the application
# (RetroArch, EmulationStation) blocks forever waiting for it: the game "freezes" on its first frame.
# Cycling the sink (suspend/resume) makes the kernel start the port again and the application resumes.
export PULSE_SERVER=unix:/run/user/0/pulse/native XDG_RUNTIME_DIR=/run/user/0
LOG=/recalbox/share/system/logs/q6a-audiofix.log
mkdir -p "$(dirname "$LOG")"
log() { echo "$(date '+%m-%d %H:%M:%S') $*" >> "$LOG"; }

heal() {
  local sink
  sink=$(pactl list short sinks 2>/dev/null | awk '/HDMI/{print $2; exit}')
  [ -n "$sink" ] || { log "no HDMI sink found"; return 1; }
  pactl suspend-sink "$sink" 1 2>/dev/null
  sleep 1
  pactl suspend-sink "$sink" 0 2>/dev/null
  log "cycled $sink"
}

start_us=$(awk '{printf "%d", $1 * 1000000}' /proc/uptime)
last=0; win_start=0; tries=0
log "watcher started (kernel time ${start_us} us)"
cat /dev/kmsg 2>/dev/null | while IFS= read -r line; do
  case "$line" in *"Failed to start APM port"*) ;; *) continue ;; esac
  IFS=, read -r _ _ ts _ <<< "$line"
  [ "${ts:-0}" -lt "$start_us" ] && continue            # message from before the watcher started
  now=$(date +%s)
  [ $((now - last)) -lt 3 ] && continue                  # one attempt at a time
  [ $((now - win_start)) -gt 60 ] && { win_start=$now; tries=0; }
  tries=$((tries + 1))
  [ "$tries" -gt 5 ] && { log "giving up for this minute (kernel keeps failing)"; continue; }
  last=$now
  log "audio port start failed (kernel ts ${ts}); attempt $tries"
  heal
  last=$(date +%s)
done
