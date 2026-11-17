#!/usr/bin/env bash
# Studio Display XDR auto-brightness from its light sensor. SLOPE and STEP come from the
# unit (peripherals.nix).
set -euo pipefail

last=-1
while sleep 5; do
  als=$(grep -l '^als$' /sys/bus/iio/devices/iio:device*/name 2>/dev/null | head -1) || continue
  [[ -n $als && $(readlink -f "${als%/name}") == *05AC:1116* ]] || continue
  d=${als%/name}
  # raw reads ~1000x lux on this display (305000 in a lit room)
  pct=$(awk -v r="$(cat "$d/in_illuminance_raw")" -v s="$(cat "$d/in_illuminance_scale")" -v k="$SLOPE" \
    'BEGIN { l = r * s / 1000; p = l > 1 ? k * log(l) / log(10) : 0; if (p < 5) p = 5; if (p > 100) p = 100; printf "%d", p }')
  if ((last < 0 || pct - last >= STEP || last - pct >= STEP)); then
    asdbctl set "$pct" && last=$pct
  fi
done
