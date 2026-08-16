#!/usr/bin/env bash
#
# install-arch-clown-dotfiles.sh
#
# Installs ALL dotfiles from https://github.com/hacktheclown/arch-clown-dotfiles
# (i3, neovim, polybar, rofi, terminator, atuin, zsh/oh-my-zsh, powerlevel10k, etc.)
#
# What it does:
#   1. Clones the repo (or pulls latest if already cloned) into ~/.dotfiles-src
#   2. Backs up any existing config it would overwrite into ~/.dotfiles-backup/<timestamp>
#   3. Symlinks every folder/file under the repo's .config/ into ~/.config/
#   4. Symlinks .zshrc and .p10k.zsh into $HOME
#
# Symlinks (not copies) are used so that `git pull` inside ~/.dotfiles-src later
# updates your live config automatically.
#
# IMPORTANT (per upstream README):
#   - Grep the resulting files for `changeme` and `HTC_NOTE` and edit those
#     spots manually — the repo has personal/machine-specific values baked in.
#   - This script does NOT install the applications themselves (i3, neovim,
#     polybar, rofi, terminator, zsh, oh-my-zsh, powerlevel10k, atuin). Install
#     those separately via pacman/AUR first, or answer "y" to the optional
#     prompt below.
#
set -euo pipefail

REPO_URL="https://github.com/hacktheclown/arch-clown-dotfiles.git"
SRC_DIR="$HOME/.dotfiles-src"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
CONFIG_DIR="$HOME/.config"

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31m[x]\033[0m %s\n' "$1" >&2; }

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || { err "Required command '$1' not found. Install it first."; exit 1; }
}

require_cmd git

# --- 1. Clone or update the source repo -------------------------------------
if [ -d "$SRC_DIR/.git" ]; then
    log "Repo already present at $SRC_DIR, pulling latest..."
    git -C "$SRC_DIR" pull --ff-only
else
    log "Cloning $REPO_URL into $SRC_DIR..."
    git clone "$REPO_URL" "$SRC_DIR"
fi

# --- 2. Optional: install the applications the dotfiles are for -------------
read -rp "Install the associated apps via pacman/AUR too? [y/N] " INSTALL_APPS
if [[ "${INSTALL_APPS,,}" == "y" ]]; then
    require_cmd pacman
    PACMAN_PKGS=(i3-wm zsh neovim polybar rofi terminator atuin git)
    log "Installing: ${PACMAN_PKGS[*]}"
    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

    if ! command -v yay >/dev/null 2>&1; then
        warn "yay (AUR helper) not found — skipping powerlevel10k AUR install."
        warn "Install manually later with: yay -S zsh-theme-powerlevel10k-git"
    else
        yay -S --needed --noconfirm zsh-theme-powerlevel10k-git || warn "powerlevel10k AUR install failed, continuing."
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "Installing oh-my-zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
fi

# --- 3. Backup + link helper -------------------------------------------------
mkdir -p "$BACKUP_DIR"
BACKED_UP_ANYTHING=false

link_item() {
    local src="$1" dest="$2"

    if [ -L "$dest" ]; then
        # Already a symlink — remove it (whether it points here or elsewhere)
        rm "$dest"
    elif [ -e "$dest" ]; then
        # Real file/dir — back it up before replacing
        mkdir -p "$(dirname "$BACKUP_DIR/${dest#$HOME/}")"
        mv "$dest" "$BACKUP_DIR/${dest#$HOME/}"
        BACKED_UP_ANYTHING=true
        warn "Backed up existing $dest -> $BACKUP_DIR/${dest#$HOME/}"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    log "Linked $dest -> $src"
}

# --- 4. Link everything under .config/ ---------------------------------------
if [ -d "$SRC_DIR/.config" ]; then
    for item in "$SRC_DIR"/.config/*; do
        name="$(basename "$item")"
        link_item "$item" "$CONFIG_DIR/$name"
    done
else
    warn "No .config directory found in the repo — skipping."
fi

# --- 5. Link root dotfiles (.zshrc, .p10k.zsh) --------------------------------
for f in .zshrc .p10k.zsh; do
    if [ -f "$SRC_DIR/$f" ]; then
        link_item "$SRC_DIR/$f" "$HOME/$f"
    fi
done

# --- 6. Wrap up ----------------------------------------------------------------
if [ "$BACKED_UP_ANYTHING" = true ]; then
    log "Old configs backed up to: $BACKUP_DIR"
else
    rmdir "$BACKUP_DIR" 2>/dev/null || true
fi

echo
log "Done. A few things to do before you log in to i3:"
echo "    1. grep -rn 'changeme\\|HTC_NOTE' \"$SRC_DIR\"   # find personal values to edit"
echo "    2. Edit those files in $SRC_DIR (edits will show up live via the symlinks)."
echo "    3. If you skipped app installation, install i3/neovim/polybar/rofi/terminator/zsh/atuin yourself."
echo "    4. Set zsh as default shell if desired: chsh -s \$(which zsh)"
echo "    5. Log out and select i3 at your display manager, or add 'exec i3' to ~/.xinitrc."
