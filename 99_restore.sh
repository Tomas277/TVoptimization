#!/usr/bin/env bash
# 99_restore.sh - undo debloating and settings changes using the newest backup.
#
# Restores:
#   * packages removed with `pm uninstall -k --user 0`  -> cmd package install-existing
#   * packages disabled with `pm disable-user`          -> pm enable
#   * the animation/DNS/ad-tracking settings changed by 03_tweaks.sh
#
# Usage: ./99_restore.sh [backup-dir]     (default: newest in backup/)
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tv

dir="${1:-$(ls -d "$ROOT"/backup/*/ 2>/dev/null | sort | tail -1)}"
[[ -d "$dir" ]] || die "no backup found. Nothing to restore from."
echo "Restoring from $dir"

[[ -f "$dir/packages_installed.txt" ]] || die "$dir has no packages_installed.txt (made by an older 01_backup.sh).
Restoring from packages_all.txt would also reinstall apps you removed BEFORE the backup.
Create packages_installed.txt from your 00_detect report (packages_user + packages_system) or re-run backups."

now="$(tv pm list packages)"
installed_then="$(grep -o 'package:[A-Za-z0-9_.]*' "$dir/packages_installed.txt")"
disabled_then="$(grep -o 'package:[A-Za-z0-9_.]*' "$dir/packages_disabled.txt" || true)"

# Reinstall anything that was installed at backup time but is missing now.
while read -r p; do
  [[ -z "$p" ]] && continue
  grep -Fxq "$p" <<<"$now" && continue
  pkg="${p#package:}"
  echo "reinstall $pkg"; tv cmd package install-existing --user 0 "$pkg" >/dev/null || echo "  failed: $pkg"
done <<<"$installed_then"

# Re-enable anything that is disabled now but was not disabled at backup time.
while read -r p; do
  [[ -z "$p" ]] && continue
  grep -Fxq "$p" <<<"$disabled_then" && continue
  pkg="${p#package:}"
  echo "enable    $pkg"; tv pm enable "$pkg" >/dev/null
done < <(tv pm list packages -d)

# Restore the few settings 03_tweaks.sh touches. A missing key is deleted.
restore() { # <namespace> <key>
  local v; v="$(grep -F "$2=" "$dir/settings_$1.txt" | grep "^$2=" | cut -d= -f2- || true)"
  # Values go through the TV's shell, so refuse anything but plain characters.
  if [[ -n "$v" && ! "$v" =~ ^[A-Za-z0-9._:-]+$ ]]; then echo "skipped $1 $2 (unexpected value)"; return; fi
  if [[ -n "$v" ]]; then tv settings put "$1" "$2" "$v"; else tv settings delete "$1" "$2" >/dev/null; fi
  echo "restored $1 $2=${v:-<unset>}"
}
for k in window_animation_scale transition_animation_scale animator_duration_scale \
         wifi_scan_always_enabled ble_scan_always_enabled private_dns_mode private_dns_specifier; do
  restore global "$k"
done
restore secure limit_ad_tracking
echo "Done. Reboot the TV to be safe."
