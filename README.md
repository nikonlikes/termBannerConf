# termBannerConf

Random ASCII login banner for any *nix terminal. Drop image files into a local cache; on every fresh login shell, one is picked at random and rendered to the terminal via [chafa](https://hpjansson.org/chafa/). Cyberpunk character portraits, `figlet`-style banners, your dog — any image chafa can read.

## What this looks like

A login shell on a host with chafa installed and at least one image in the cache prints a randomly-picked image rendered as colored Unicode block characters, capped to 100 columns wide and 20 rows tall. No banner if the cache is empty (graceful skip).

Trigger model: **login shells only**. Fires on every fresh `ssh` or new Terminal/iTerm window. Does **not** fire on tmux panes or VS Code integrated terminals (those start non-login shells by default).

## Files

| File | Purpose |
|---|---|
| `banner.sh` | The renderer. POSIX shell. Sourced by login shells. Reads from `${TERM_BANNER_DIR:-$HOME/.cache/term-banner/images/}` and renders one random image. Bails silently if chafa isn't installed, the dir is empty, or the shell isn't interactive. |
| `install-linux.sh` | Debian/Ubuntu/Mint/RPi installer. apt-installs `chafa`, copies `banner.sh` to `/etc/profile.d/99-term-banner.sh`, creates the cache dir. Does **not** auto-sync images. |
| `install-macos.sh` | macOS installer. brew-installs `chafa`, copies `banner.sh` to `~/.config/term-banner/banner.sh`, appends a marked source block to `~/.zprofile`, creates the cache dir. Does **not** auto-sync images. |
| `sync-images.sh` | Optional. rsync from `$BANNER_SRC` (you set it) into the local cache. Use only if you have ssh access to a remote image source. Otherwise just `scp`/`cp` images into the cache dir directly. |

## Install

```bash
git clone https://github.com/nikonlikes/termBannerConf ~/code/termBannerConf
cd ~/code/termBannerConf

# Linux:
./install-linux.sh

# macOS:
./install-macos.sh
```

After install, populate the image cache (default: `~/.cache/term-banner/images/`):

```bash
# Option 1: scp/cp images from any source you can reach
scp my-image.png remote-host:.cache/term-banner/images/

# Option 2: rsync from a remote source
BANNER_SRC=user@host:path/to/images/ ~/code/termBannerConf/sync-images.sh
```

Open a new login shell — the banner appears.

## Updating

```bash
cd ~/code/termBannerConf && git pull
./install-linux.sh    # or install-macos.sh; both are idempotent
```

The installers re-copy `banner.sh` on every run, so a `git pull` + re-install picks up changes.

## Configuration

Two env vars; set in your shell rc *before* the banner script runs (e.g., earlier in `~/.zprofile`):

| Env var | Default | Effect |
|---|---|---|
| `TERM_BANNER_DIR` | `$HOME/.cache/term-banner/images` | Where the renderer looks for images. |
| `BANNER_SRC` | (no default) | rsync source for `sync-images.sh`. Required when running that script. |

## Tuning chafa

Edit the `chafa --size=… --symbols=… --colors=…` line in `banner.sh`:

| Flag | Default | Effect |
|---|---|---|
| `--size=WxH` | `${cols}x20` | output dimensions; `H` ≈ vertical lines |
| `--symbols=block` | block | unicode block chars (denser); use `--symbols=ascii` for plain ASCII feel |
| `--colors=256` | 256 | palette; `--colors=full` for truecolor, `--colors=2` for monochrome |
| `--fg-only` | (off) | suppress background color |
| `--invert` | (off) | flip dark/light |

`chafa --help` for the rest. Test changes by sourcing the script in a current session: `source ~/.config/term-banner/banner.sh` (macOS) or `source /etc/profile.d/99-term-banner.sh` (Linux).

## Uninstall

**Linux**:
```bash
sudo rm /etc/profile.d/99-term-banner.sh
rm -rf ~/.cache/term-banner
sudo apt remove chafa     # optional
```

**macOS** — remove the marked block from `~/.zprofile`:
```bash
sed -i.bak '/# >>> term-banner >>>/,/# <<< term-banner <<</d' ~/.zprofile
rm -rf ~/.config/term-banner ~/.cache/term-banner
brew uninstall chafa      # optional
```

## Security notes

- **No network at shell-init time.** The renderer reads only from the local cache; sync runs separately, when you invoke it.
- **No `eval`, no `exec`.** Filenames are passed to `chafa` as positional args, never reinterpreted by the shell.
- **No sudo at runtime** for the banner itself; sudo is only used during install on Linux (apt + `/etc/profile.d/`). macOS install needs no sudo.
- **No secrets in this repo.** `sync-images.sh` requires `BANNER_SRC` from the environment — no IPs, hostnames, or credentials are baked in.
- **No image is ever executed.** chafa is a renderer; the worst case for a bad input is an unreadable banner or a chafa crash (silenced via `2>/dev/null`).

## Compatibility

- Linux: Debian, Ubuntu, Mint, Raspberry Pi OS (anywhere `apt-get install chafa` works)
- macOS: Sequoia and earlier, Apple Silicon and Intel (anywhere `brew install chafa` works)
- Shells: bash, zsh, dash, ksh — POSIX-compatible

## License

The scripts in this repo are MIT-licensed (see `LICENSE`). Image collections are entirely your responsibility — this repo intentionally ships no images.
