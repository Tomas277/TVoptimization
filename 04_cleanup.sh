#!/usr/bin/env bash
# 04_cleanup.sh - free storage by trimming app caches, then show free space.
#
# Only caches are removed; no app data, logins or settings are touched.
# Safe to run any time.
#
# Usage: ./04_cleanup.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_tv

echo "Before:"; tv df /data | tail -1
# Ask the system to free up to ~999 GB of cache, i.e. all of it.
tv pm trim-caches 999G
echo "After:";  tv df /data | tail -1
