#!/usr/bin/env bash
# 00_detect.sh - READ-ONLY inspection of the TV. Changes nothing.
#
# Writes a report to reports/<timestamp>/ with device info, memory, storage,
# installed packages and current animation settings. Review it before
# deciding what to debloat.
#
# Usage: TV_ADDR=192.168.1.50:5555 ./00_detect.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tv

out="$ROOT/reports/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"

{
  echo "model:       $(tv getprop ro.product.model)"
  echo "manufacturer:$(tv getprop ro.product.manufacturer)"
  echo "android:     $(tv getprop ro.build.version.release) (SDK $(tv getprop ro.build.version.sdk))"
  echo "fingerprint: $(tv getprop ro.build.fingerprint)"
  echo "low-ram:     $(tv getprop ro.config.low_ram)"
} | tee "$out/device.txt"

tv cat /proc/meminfo | head -5     > "$out/memory.txt"
tv df /data                        > "$out/storage.txt"
tv pm list packages -f -3          > "$out/packages_user.txt"    # installed by you
tv pm list packages -f -s          > "$out/packages_system.txt"  # shipped with the TV
tv pm list packages -d             > "$out/packages_disabled.txt"
{
  for k in window_animation_scale transition_animation_scale animator_duration_scale; do
    echo "$k=$(tv settings get global $k)"
  done
  echo "private_dns_mode=$(tv settings get global private_dns_mode)"
} > "$out/settings.txt"

echo
echo "Report saved to $out"
echo "Next: review packages_system.txt, then build packages.txt (see packages.example.txt)."
