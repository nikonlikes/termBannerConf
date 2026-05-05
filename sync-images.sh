#!/bin/sh
# Pull banner images from a remote source (rsync over ssh) into the local cache.
#
# Set BANNER_SRC to a valid rsync source spec, e.g.:
#   BANNER_SRC=user@host:path/to/images/   ./sync-images.sh
#   BANNER_SRC=/Volumes/some-mount/images/  ./sync-images.sh
#
# Destination: $TERM_BANNER_DIR (default ~/.cache/term-banner/images/)
#
# Idempotent. --delete-after keeps the local cache aligned with the source.
# Skips macOS AppleDouble sidecars and .DS_Store droppings.
# Uses only flags that round-trip on macOS's bundled openrsync (-aH safe;
# avoid -A/-X/-E).

set -eu

# BANNER_SRC must be set explicitly. No baked-in default — keeps the public
# repo free of any specific user's host/IP.
: "${BANNER_SRC:?BANNER_SRC must be set, e.g.:  BANNER_SRC=user@host:path/to/images/ $0}"

DEST=${TERM_BANNER_DIR:-${SHAI_BANNER_DIR:-$HOME/.cache/term-banner/images}}

mkdir -p "$DEST"

rsync -aH --delete-after \
    --exclude '.DS_Store' --exclude '._*' \
    "$BANNER_SRC" "$DEST"

n=$(find "$DEST" -maxdepth 1 -type f ! -name '._*' \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        2>/dev/null | wc -l | tr -d ' ')
printf 'synced %s -> %s (%s images)\n' "$BANNER_SRC" "$DEST" "$n"
