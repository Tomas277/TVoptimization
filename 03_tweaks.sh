#!/usr/bin/env bash
# 03_tweaks.sh - speed, privacy and network settings.
#
# SAFE BY DEFAULT: prints the commands unless --apply is given.
# Every setting here can be put back with 99_restore.sh (uses 01_backup.sh data)
# or by the "default" values noted below.
#
# What it changes and why:
#   *_animation_scale 0.5  halves UI animation time -> UI feels faster (default 1.0)
#   limit_ad_tracking 1    opts out of personalised ads (default 0)
#   private_dns_*          encrypted DNS with ad/tracker blocking, set DNS_HOST below
#   wifi_scan_always_enabled 0 / ble_scan_always_enabled 0
#                          stop background radio scanning (less CPU/network noise)
#
# Usage: [DNS_HOST=dns.adguard-dns.com] ./03_tweaks.sh [--apply]
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

apply=0; [[ "${1:-}" == "--apply" ]] && apply=1
DNS_HOST="${DNS_HOST-dns.adguard-dns.com}"    # set DNS_HOST="" to skip Private DNS
[[ -z "$DNS_HOST" ]] || valid_host "$DNS_HOST" || die "invalid DNS_HOST '$DNS_HOST'"
require_tv

# put <namespace> <key> <value>
put() {
  if (( apply )); then
    tv settings put "$1" "$2" "$3"
    echo "set $1 $2=$3"
  else
    echo "WOULD set $1 $2=$3"
  fi
}

put global window_animation_scale 0.5
put global transition_animation_scale 0.5
put global animator_duration_scale 0.5

put secure limit_ad_tracking 1
put global wifi_scan_always_enabled 0
put global ble_scan_always_enabled 0

if [[ -n "$DNS_HOST" ]]; then
  put global private_dns_mode hostname
  put global private_dns_specifier "$DNS_HOST"
fi

(( apply )) || echo $'\nDry run only. Re-run with --apply to make changes.'
