# Random ASCII login banner — picks one image from a local cache and renders
# via chafa. Sourced by login shells.
#
# Cache path defaults to ~/.cache/term-banner/images/. Override with the
# SHAI_BANNER_DIR env var (legacy name) or TERM_BANNER_DIR (preferred).
#
# Local-only: no network at shell-init. No exec, no eval.
# POSIX shell — works under bash, zsh, dash, ksh.

# Interactive shells only — guards against being sourced by scp, rsync, etc.
case $- in *i*) ;; *) return 2>/dev/null || exit ;; esac

# Bail silently if chafa isn't installed.
command -v chafa >/dev/null 2>&1 || return 2>/dev/null

# Pick image directory. TERM_BANNER_DIR wins; SHAI_BANNER_DIR is the legacy
# alias so older shai-side configs keep working.
DIR=${TERM_BANNER_DIR:-${SHAI_BANNER_DIR:-$HOME/.cache/term-banner/images}}
[ -d "$DIR" ] || return 2>/dev/null

# Pick one image at random. POSIX awk is portable across Linux + macOS
# (macOS lacks GNU `shuf` by default). Excludes macOS AppleDouble sidecars
# (`._*`) that SMB clients leave behind.
img=$(find "$DIR" -maxdepth 1 -type f ! -name '._*' \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        2>/dev/null \
    | awk 'BEGIN { srand() } { a[NR] = $0 } END { if (NR > 0) print a[int(rand() * NR) + 1] }')

[ -n "$img" ] && [ -r "$img" ] || return 2>/dev/null

# Cap render width so banners stay readable on wide terminals.
cols=$(tput cols 2>/dev/null || echo 80)
[ "$cols" -gt 100 ] && cols=100

printf '\n'
chafa --size="${cols}x20" --symbols=block --colors=256 "$img" 2>/dev/null
printf '\n'
