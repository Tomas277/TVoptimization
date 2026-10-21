#!/usr/bin/env bash
# 01_backup.sh - snapshot package state and settings so changes can be undone.
#
# Run this BEFORE 02_debloat.sh or 03_tweaks.sh. 99_restore.sh reads the
# newest backup in backup/.
#
# Usage: TV_ADDR=192.168.1.50:5555 ./01_backup.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tv

out="$ROOT/backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"

# What is installed RIGHT NOW. 99_restore.sh restores only these, so apps you had
# already removed before this backup are not brought back.
tv pm list packages > "$out/packages_installed.txt"
# -u also lists packages removed for this user earlier (kept for reference).
tv pm list packages -u > "$out/packages_all.txt"
tv pm list packages -d > "$out/packages_disabled.txt"
for ns in global secure system; do
  tv settings list "$ns" > "$out/settings_$ns.txt"
done

echo "Backup saved to $out"
