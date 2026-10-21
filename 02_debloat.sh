#!/usr/bin/env bash
# 02_debloat.sh - remove/disable unwanted packages listed in packages.txt.
#
# SAFE BY DEFAULT: without --apply it only prints what it would do.
#
# For each package it tries, in order:
#   1. pm uninstall -k --user 0 <pkg>   (removes for the current user, keeps data;
#                                        the system image is untouched, so a
#                                        factory reset brings it back)
#   2. pm disable-user --user 0 <pkg>   (fallback if uninstall is refused)
# Both are reversible with 99_restore.sh. Packages on the NEVER_TOUCH list in
# lib.sh are always skipped.
#
# Usage: ./02_debloat.sh [--apply] [packages.txt]
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

apply=0
list="$ROOT/packages.txt"
for arg in "$@"; do
  case "$arg" in
    --apply) apply=1 ;;
    *) list="$arg" ;;
  esac
done
[[ -f "$list" ]] || die "$list not found. Copy packages.example.txt to packages.txt and edit it."
require_tv

installed="$(tv pm list packages)"

while read -r line || [[ -n "$line" ]]; do
  read_pkg_line "$line" || continue

  if is_protected "$pkg"; then echo "SKIP (protected)   $pkg"; continue; fi
  if ! grep -Fxq "package:$pkg" <<<"$installed"; then echo "SKIP (not present) $pkg"; continue; fi

  if (( ! apply )); then echo "WOULD remove       $pkg"; continue; fi

  # Capture output first: piping straight into `grep -q` can trip pipefail.
  out="$(tv pm uninstall -k --user 0 "$pkg" || true)"
  if grep -q Success <<<"$out"; then
    echo "REMOVED            $pkg"
    continue
  fi
  out="$(tv pm disable-user --user 0 "$pkg" || true)"
  if grep -qi "new state: disabled" <<<"$out"; then
    echo "DISABLED           $pkg"
  else
    echo "FAILED             $pkg"
  fi
done < "$list"

(( apply )) || echo $'\nDry run only. Re-run with --apply to make changes (run 01_backup.sh first).'
