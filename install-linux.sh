#!/bin/sh
# Install the ASCII login banner on a Debian-derived Linux host
# (Debian, Ubuntu, Linux Mint, Raspberry Pi OS).
#
# - Installs `chafa` via apt (skipped if already present).
# - Copies banner.sh to /etc/profile.d/99-term-banner.sh (mode 644).
# - Creates the local image cache directory (empty).
#
# Re-runnable: each step is idempotent. Backs up any existing
# /etc/profile.d/99-term-banner.sh before overwriting.
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
TARGET=/etc/profile.d/99-term-banner.sh

echo "==> install-linux.sh starting on $(hostname)"

# 1. Install chafa
if command -v chafa >/dev/null 2>&1; then
    echo "  chafa already installed: $(chafa --version | head -1)"
else
    echo "  installing chafa via apt..."
    sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 apt-get install -y chafa
fi

# 2. Cache dir (empty, user populates separately)
mkdir -p "$CACHE_DIR"
echo "  cache dir ready: $CACHE_DIR"

# 3. Install the script as a profile.d entry. Back up if one exists.
if [ -f "$TARGET" ]; then
    backup="${TARGET}.bak-$(date +%Y%m%d-%H%M%S)"
    sudo cp "$TARGET" "$backup"
    echo "  backed up existing $TARGET -> $backup"
fi
sudo install -m 644 "$REPO_DIR/banner.sh" "$TARGET"
echo "  installed $TARGET (mode 644, owned by root)"

echo
echo "Done. To populate images:"
echo "  BANNER_SRC=user@host:path/to/images/ $REPO_DIR/sync-images.sh"
echo "  # or scp images directly into $CACHE_DIR"
echo
echo "Then open a new login shell to see the banner:"
echo "  bash -l   # or just re-ssh into this host"
