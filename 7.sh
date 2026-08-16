#!/usr/bin/env bash
#
# install-arch-clown-dotfiles.sh
#
# Clones hacktheclown/arch-clown-dotfiles and applies it to your system:
# i3, polybar, rofi, terminator, neovim, zsh + oh-my-zsh + powerlevel10k + atuin.
#
# This mirrors what the repo's README tells you to do by hand:
#   1. Install the required packages
#   2. Copy .config/*, .zshrc, .p10k.zsh, wallpaper.jpg into your home dir
#   3. Set zsh as your default shell
#   4. Search the copied files for "changeme" / "HTC_NOTE" and edit them
#      to match your machine (hostname, monitor names, VM-specific bits, etc.)
#
# Safe to re-run: existing configs are backed up, not overwritten silently.

set -euo pipefail

REPO_URL="https://github.com/hacktheclown/arch-clown-dotfiles.git"
CLONE_DIR="${HOME}/.cache/arch-clown-dotfiles"
BACKUP_DIR="${HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"

RED=$(tput setaf 1 2>/dev/null || true)
GREEN=$(tput setaf 2 2>/dev/null || true)
YELLOW=$(tput setaf 3 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)

info()  { echo "${GREEN}::${RESET} $*"; }
warn()  { echo "${YELLOW}::${RESET} $*"; }
error() { echo "${RED}::${RESET} $*" >&2; }

# --- 0. Sanity checks -------------------------------------------------------

if [[ ! -f /etc/arch-release ]]; then
    warn "This doesn't look like Arch Linux. Continuing anyway, but pacman"
    warn "commands below may fail."
fi

if ! command -v git >/dev/null 2>&1; then
    error "git is required. Install it first: sudo pacman -S git"
    exit 1
fi

# --- 1. Install packages ----------------------------------------------------

PACMAN_PKGS=(
    i3-wm
    polybar
    rofi
    terminator
    neovim
    zsh
    git
    ttf-roboto
    curl
)

# AUR packages (need yay/paru). We only attempt these if an AUR helper exists.
AUR_PKGS=(
    ttf-nerd-fonts-noto-sans-mono
    martian-mono-nerd-font
)

info "Installing official packages via pacman..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

AUR_HELPER=""
if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
fi

if [[ -n "$AUR_HELPER" ]]; then
    info "Installing Nerd Fonts via ${AUR_HELPER}..."
    "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}" || \
        warn "Some AUR fonts failed to install — install manually if needed."
else
    warn "No AUR helper (yay/paru) found. Skipping Nerd Font packages."
    warn "Install 'NotoSansM Nerd Font Mono Condensed Bold' and"
    warn "'MartianMono Nerd Font Propo Condensed Medium' manually, e.g. via"
    warn "https://www.nerdfonts.com/font-downloads"
fi

# oh-my-zsh
if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    info "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    info "oh-my-zsh already installed, skipping."
fi

# powerlevel10k theme
P10K_DIR="${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    info "Installing powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    info "powerlevel10k already installed, skipping."
fi

# atuin
if ! command -v atuin >/dev/null 2>&1; then
    info "Installing atuin..."
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh || \
        warn "atuin install script failed — install manually from https://atuin.sh"
else
    info "atuin already installed, skipping."
fi

# --- 2. Clone the dotfiles repo ---------------------------------------------

if [[ -d "$CLONE_DIR" ]]; then
    info "Repo already cloned, pulling latest..."
    git -C "$CLONE_DIR" pull --ff-only
else
    info "Cloning ${REPO_URL}..."
    git clone --depth=1 "$REPO_URL" "$CLONE_DIR"
fi

# --- 3. Back up anything we're about to overwrite ---------------------------

mkdir -p "$BACKUP_DIR"
info "Backing up existing configs to ${BACKUP_DIR} (only what exists)..."

backup_and_copy() {
    local src="$1" dest="$2"
    if [[ -e "$dest" ]]; then
        mkdir -p "$(dirname "${BACKUP_DIR}/${dest#$HOME/}")"
        cp -a "$dest" "${BACKUP_DIR}/$(basename "$dest")"
    fi
    cp -a "$src" "$dest"
}

# --- 4. Copy dotfiles into place --------------------------------------------

mkdir -p "${HOME}/.config"

if [[ -d "${CLONE_DIR}/.config" ]]; then
    info "Copying .config/* into ${HOME}/.config ..."
    for item in "${CLONE_DIR}"/.config/*; do
        name="$(basename "$item")"
        backup_and_copy "$item" "${HOME}/.config/${name}"
    done
fi

for f in .zshrc .p10k.zsh; do
    if [[ -f "${CLONE_DIR}/${f}" ]]; then
        backup_and_copy "${CLONE_DIR}/${f}" "${HOME}/${f}"
    fi
done

if [[ -f "${CLONE_DIR}/wallpaper.jpg" ]]; then
    mkdir -p "${HOME}/Pictures"
    cp -a "${CLONE_DIR}/wallpaper.jpg" "${HOME}/Pictures/arch-clown-wallpaper.jpg"
    info "Wallpaper copied to ~/Pictures/arch-clown-wallpaper.jpg"
    info "Point your i3/polybar/feh config at this path if it isn't already."
fi

# --- 5. Set zsh as default shell --------------------------------------------

if [[ "$SHELL" != *zsh ]]; then
    info "Setting zsh as your default shell (you may be prompted for your password)..."
    chsh -s "$(command -v zsh)" || warn "Could not chsh automatically — run 'chsh -s \$(which zsh)' yourself."
fi

# --- 6. Point out what needs manual attention -------------------------------

echo
info "Done. A few things to check before you log out/in to i3:"
echo
echo "  1. Search the copied files for machine-specific placeholders:"
echo "       grep -rn 'changeme' ${HOME}/.config ${HOME}/.zshrc ${HOME}/.p10k.zsh 2>/dev/null"
echo "       grep -rn 'HTC_NOTE' ${HOME}/.config ${HOME}/.zshrc ${HOME}/.p10k.zsh 2>/dev/null"
echo "     Edit those spots (monitor names, paths, hostnames, etc.)."
echo
echo "  2. The original author runs Arch inside VMware Fusion — ignore any"
echo "     vmware-related lines in the configs if you're on bare metal."
echo
echo "  3. Your previous configs (if any) were backed up to:"
echo "       ${BACKUP_DIR}"
echo
echo "  4. Log out and select i3 at your display manager (or run 'startx' /"
echo "     'exec i3' depending on your setup) to see the new environment."
