#!/usr/bin/env bash
# 05_background.sh - stop chosen apps from running in the background, to free RAM.
#
# Nothing is uninstalled. The apps still launch normally; they just can't stay
# resident (or wake themselves up) while you are watching something else, so
# they may start a little slower. Leave out apps that must keep running, e.g.
# a music app you want to keep playing while you switch apps.
#
# For each package in background.txt it:
#   --apply : sets appops RUN_IN_BACKGROUND and RUN_ANY_IN_BACKGROUND to "deny",
#             then force-stops the app so its RAM is freed now
#   --reset : sets both back to "default" (undoes --apply)
# Without either flag it only prints what it would do.
#
# Usage: ./05_background.sh [--apply | --reset] [background.txt]
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

mode=dry
list="$ROOT/background.txt"
for arg in "$@"; do
  case "$arg" in
    --apply) mode=apply ;;
    --reset) mode=reset ;;
    *) list="$arg" ;;
  esac
done
[[ -f "$list" ]] || die "$list not found. Copy background.example.txt to background.txt and edit it."
require_tv

installed="$(tv pm list packages)"

while read -r line || [[ -n "$line" ]]; do
  read_pkg_line "$line" || continue

  if is_protected "$pkg"; then echo "SKIP (protected)   $pkg"; continue; fi
  if ! grep -Fxq "package:$pkg" <<<"$installed"; then echo "SKIP (not present) $pkg"; continue; fi

  case "$mode" in
    dry)   echo "WOULD restrict    $pkg" ;;
    apply) tv cmd appops set "$pkg" RUN_IN_BACKGROUND deny
           tv cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND deny
           tv am force-stop "$pkg"
           echo "RESTRICTED         $pkg" ;;
    reset) tv cmd appops set "$pkg" RUN_IN_BACKGROUND default
           tv cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND default
           echo "RESET              $pkg" ;;
  esac
done < "$list"

[[ "$mode" == dry ]] && echo $'\nDry run only. Re-run with --apply to make changes, or --reset to undo.'
exit 0
