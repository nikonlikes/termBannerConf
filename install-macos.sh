#!/bin/sh
# Install the ASCII login banner on macOS.
#
# - Installs `chafa` via Homebrew (skipped if already present).
# - Copies banner.sh to ~/.config/term-banner/banner.sh.
# - Adds a single source line to ~/.zprofile (idempotent — checks for marker).
# - Creates the local image cache directory (empty).
#
# No sudo required. Backs up ~/.zprofile before any append.
#
# Image sync is deliberately NOT run from this installer — it's a separate
# step (see sync-images.sh) so this works on hosts that have no path to
# the image source. After install, populate the cache by either:
#   - running ./sync-images.sh with BANNER_SRC set, or
#   - copying images manually (e.g., scp from another device into
#     ~/.cache/term-banner/images/)

set -eu

REPO_DIR=$(cd "$(dirname "$0")" && pwd)
CACHE_DIR=${TERM_BANNER_DIR:-$HOME/.cache/term-banner/images}
DEST_DIR=$HOME/.config/term-banner
DEST=$DEST_DIR/banner.sh
ZPROFILE=$HOME/.zprofile
MARKER='# >>> term-banner >>>'

echo "==> install-macos.sh starting on $(hostname -s)"

# 1. Install chafa via brew
if command -v chafa >/dev/null 2>&1; then
    echo "  chafa already installed: $(chafa --version | head -1)"
else
    if ! command -v brew >/dev/null 2>&1; then
        echo "ERROR: Homebrew not found. Install from https://brew.sh first." >&2
        exit 1
    fi
    echo "  installing chafa via brew..."
    brew install chafa
fi

# 2. Cache dir (empty, user populates separately)
mkdir -p "$CACHE_DIR"
echo "  cache dir ready: $CACHE_DIR"

# 3. Install the script under user-owned config dir (no sudo).
mkdir -p "$DEST_DIR"
cp "$REPO_DIR/banner.sh" "$DEST"
chmod 644 "$DEST"
echo "  installed $DEST"

# 4. Wire it into login shells via ~/.zprofile (zsh login startup file).
#    Idempotent: re-running won't add a second copy.
if [ -f "$ZPROFILE" ] && grep -Fq "$MARKER" "$ZPROFILE"; then
    echo "  $ZPROFILE already wired; skipping."
else
    if [ -f "$ZPROFILE" ]; then
        cp "$ZPROFILE" "${ZPROFILE}.bak-$(date +%Y%m%d-%H%M%S)"
    fi
    {
        printf '\n%s\n' "$MARKER"
        printf '# Login banner managed by term-banner/install-macos.sh.\n'
        printf '# To remove: delete this block (between markers) and rm -rf %s.\n' "$DEST_DIR"
        printf '[ -f "%s" ] && . "%s"\n' "$DEST" "$DEST"
        printf '# <<< term-banner <<<\n'
    } >> "$ZPROFILE"
    echo "  appended source block to $ZPROFILE (backup if pre-existing)"
fi

echo
echo "Done. To populate images:"
echo "  BANNER_SRC=user@host:path/to/images/ $REPO_DIR/sync-images.sh"
echo "  # or scp images directly into $CACHE_DIR"
echo
echo "Then open a new Terminal/iTerm window to see the banner:"
echo "  zsh -l   # or just open a new tab"
