#!/usr/bin/env bash
# lib.sh - shared helpers for the TV optimization scripts.
# Source this file; do not run it directly.
#
# Environment:
#   TV_ADDR   Optional "ip[:port]" of the TV. If set, we `adb connect` to it.
#             If unset, we use whichever single device adb already sees.
#   PROFILE   Optional vendor profile name (file in profiles/, without .conf).
#             If unset, it is auto-detected from ro.product.manufacturer.

set -euo pipefail

# Directory the scripts live in, so output paths work from any cwd.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Print an error to stderr and exit.
die() { echo "error: $*" >&2; exit 1; }

# adb joins its arguments into ONE string that the TV's shell parses again, so
# anything taken from a file or the environment must be checked before use or
# a line like "foo; rm -rf /sdcard" would run on the TV. Both return 0 if safe.
valid_pkg()  { [[ "$1" =~ ^[A-Za-z0-9_.]+$ ]]; }   # Android package name
valid_host() { [[ "$1" =~ ^[A-Za-z0-9.-]+$ ]]; }   # DNS hostname

# read_pkg_line <line>: sets $pkg to the package on a list-file line, with
# comments and whitespace stripped. Returns 1 for blank/comment-only lines and
# for invalid names (after printing a warning).
read_pkg_line() {
  pkg="${1%%#*}"
  pkg="${pkg#"${pkg%%[![:space:]]*}"}"   # trim leading whitespace
  pkg="${pkg%"${pkg##*[![:space:]]}"}"   # trim trailing whitespace
  [[ -z "$pkg" ]] && return 1
  if ! valid_pkg "$pkg"; then echo "SKIP (invalid name) $pkg" >&2; return 1; fi
  return 0
}

# Run a command on the TV. Strips the carriage returns adb shell adds.
# stdin is detached: otherwise `adb shell` swallows the input of any enclosing
# `while read` loop (e.g. the package list in 02_debloat.sh) after one iteration.
tv() { adb shell "$@" </dev/null | tr -d '\r'; }

# Package-name prefixes that must never be removed or disabled.
# Filled by load_profile() from profiles/generic.conf plus the vendor profile.
NEVER_TOUCH=()

# load_profile <name>: read "protect <prefix>" lines from profiles/<name>.conf.
# Blank lines and text after '#' are ignored.
load_profile() {
  local file="$ROOT/profiles/$1.conf" kind value
  [[ -f "$file" ]] || return 1
  while read -r kind value _; do
    if [[ "$kind" == "protect" && -n "$value" ]]; then NEVER_TOUCH+=("$value"); fi
  done < <(sed 's/#.*//' "$file")
  return 0
}

# Load generic protections plus the profile for this TV's manufacturer.
# Unknown vendors get generic protections only, with a warning.
select_profile() {
  load_profile generic || die "profiles/generic.conf missing"
  local name="${PROFILE:-}"
  if [[ -z "$name" ]]; then
    name="$(tv getprop ro.product.manufacturer | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
  fi
  # The name becomes a file path (profiles/<name>.conf): no slashes or dots.
  [[ "$name" =~ ^[a-z0-9]+$ ]] || die "invalid profile name '$name' (letters and digits only)"
  if load_profile "$name"; then
    echo "profile: $name" >&2
  else
    echo "warning: no profile for '$name'; only generic protections apply." >&2
    echo "         Review the report from 00_detect.sh and consider adding profiles/$name.conf." >&2
  fi
}

# Make sure adb exists and exactly one device is reachable and authorized,
# then load the matching protection profile.
require_tv() {
  command -v adb >/dev/null || die "adb not found. Install it (Arch: 'pacman -S android-tools', Debian/Ubuntu: 'apt install adb')."
  if [[ -n "${TV_ADDR:-}" ]]; then
    adb connect "$TV_ADDR" >/dev/null || die "could not connect to $TV_ADDR"
  fi
  local state
  state="$(adb get-state 2>&1 || true)"
  [[ "$state" == "device" ]] || die "no authorized device (adb said: '$state'). Accept the debugging prompt on the TV, or set TV_ADDR=ip:5555."
  select_profile
}

# Return 0 if the package is protected (starts with a NEVER_TOUCH prefix).
is_protected() {
  local pkg="$1" p
  for p in "${NEVER_TOUCH[@]}"; do
    [[ "$pkg" == "$p"* ]] && return 0
  done
  return 1
}
