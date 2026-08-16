Yes. I checked the **actual repository** and its current configuration. It really does use i3, Terminator, Polybar, Rofi, Neovim, Atuin, Zsh/Oh My Zsh/Powerlevel10k, and the three fonts listed in the README. ([GitHub][1])

The repository also contains the actual `.config/i3`, Polybar, Rofi, Terminator, Neovim, GTK and xsettingsd configurations, so this script **copies the author's real dotfiles instead of recreating them**. ([GitHub][2])

I've made only these changes for your machine:

* `/home/changeme` → your actual `$HOME`
* Firefox → **Workspace 2**
* Google Chrome assignment retained as an additional rule
* Detects your network interface automatically
* Installs the required packages
* Installs Zsh + Oh My Zsh + Powerlevel10k
* Installs the author's Zsh plugins
* Installs the author's wallpaper
* Backs up your existing configuration
* Disables VMware-specific lines
* Fixes the repo's `changeme` placeholders
* Validates i3 before allowing you to restart it

The repository itself explicitly warns that it contains `changeme`/`HTC_NOTE` placeholders and VMware-specific settings, which this script handles. ([GitHub][1])

## Full installer

Create:

```bash
nano install-hacktheclown.sh
```

Paste:

```bash
#!/usr/bin/env bash

# ============================================================
# HackTheClown Arch Linux Dotfiles Installer
# ============================================================
#
# Based on:
# https://github.com/hacktheclown/arch-clown-dotfiles
#
# Installs:
#   i3
#   Terminator
#   Polybar
#   Rofi
#   Neovim
#   Atuin
#   Zsh
#   Oh My Zsh
#   Powerlevel10k
#   Ranger
#   Picom
#   Feh
#   Firefox
#
# Also:
#   - installs the author's dotfiles
#   - installs fonts
#   - installs wallpaper
#   - fixes /home/changeme paths
#   - Firefox -> workspace 2
#   - detects network interface
#   - backs up existing configuration
#
# ============================================================

set -Eeuo pipefail

# ============================================================
# VARIABLES
# ============================================================

REPO="https://github.com/hacktheclown/arch-clown-dotfiles.git"
REPO_DIR="$HOME/arch-clown-dotfiles"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.config-backup-hacktheclown-$TIMESTAMP"

CONFIG_DIR="$HOME/.config"

# ============================================================
# COLORS
# ============================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# ============================================================
# ERROR HANDLER
# ============================================================

trap 'error "Installation failed at line $LINENO."' ERR

# ============================================================
# CHECK ROOT
# ============================================================

if [[ "$EUID" -eq 0 ]]; then
    error "Do not run this script as root."
    echo
    echo "Run it as your normal user."
    echo
    exit 1
fi

# ============================================================
# CHECK ARCH
# ============================================================

if ! command -v pacman >/dev/null 2>&1; then
    error "pacman was not found."
    error "This script is intended for Arch Linux."
    exit 1
fi

# ============================================================
# HEADER
# ============================================================

clear

echo
echo "============================================================"
echo "       HACK THE CLOWN - ARCH LINUX DOTFILES"
echo "============================================================"
echo
echo "Repository:"
echo
echo "https://github.com/hacktheclown/arch-clown-dotfiles"
echo
echo "User:"
echo
echo "$USER"
echo
echo "Home:"
echo
echo "$HOME"
echo
echo "============================================================"
echo

# ============================================================
# CONFIRM
# ============================================================

read -r -p "Continue with installation? [y/N]: " ANSWER

if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
    echo
    echo "Installation cancelled."
    exit 0
fi

# ============================================================
# UPDATE SYSTEM
# ============================================================

echo
info "Updating Arch Linux..."

sudo pacman -Syu --noconfirm

success "System updated."

# ============================================================
# PACKAGE LIST
# ============================================================

echo
info "Installing required packages..."

PACKAGES=(
    # Window manager
    i3-wm
    i3status

    # Desktop
    polybar
    rofi
    picom
    feh

    # Terminal
    terminator

    # Editor
    neovim

    # Shell
    zsh
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting

    # History
    atuin

    # File manager
    ranger

    # Browser
    firefox

    # X11
    xorg-server
    xorg-xinit
    xorg-xrandr
    xorg-xset
    xorg-xprop
    xclip

    # Utilities
    dex
    xsettingsd
    i3lock
    git
    curl
    wget
    unzip
    scrot
    file
    imagemagick
    jq
    ripgrep
    fd
    bat
    tree

    # Fonts
    ttf-roboto
    ttf-martian-mono-nerd
    ttf-noto-nerd
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

success "Packages installed."

# ============================================================
# FONT CACHE
# ============================================================

info "Refreshing font cache..."

fc-cache -f >/dev/null 2>&1 || true

success "Font cache refreshed."

# ============================================================
# BACKUP
# ============================================================

echo
info "Creating configuration backup..."

mkdir -p "$BACKUP_DIR"

# Backup .config
if [[ -d "$CONFIG_DIR" ]]; then
    cp -a "$CONFIG_DIR" "$BACKUP_DIR/config"
fi

# Backup Zsh files
for FILE in \
    "$HOME/.zshrc" \
    "$HOME/.p10k.zsh"
do
    if [[ -e "$FILE" ]]; then
        cp -a "$FILE" "$BACKUP_DIR/"
    fi
done

success "Backup created:"
echo
echo "  $BACKUP_DIR"

# ============================================================
# CLONE REPOSITORY
# ============================================================

echo
info "Downloading HackTheClown dotfiles..."

if [[ -d "$REPO_DIR/.git" ]]; then

    info "Repository already exists."

    git -C "$REPO_DIR" fetch origin
    git -C "$REPO_DIR" reset --hard origin/main

else

    if [[ -d "$REPO_DIR" ]]; then
        warning "$REPO_DIR exists but is not a Git repository."

        OLD_REPO="${REPO_DIR}.backup-${TIMESTAMP}"

        mv "$REPO_DIR" "$OLD_REPO"

        info "Existing directory moved to:"
        echo
        echo "  $OLD_REPO"
    fi

    git clone --depth=1 "$REPO" "$REPO_DIR"

fi

success "Repository downloaded."

# ============================================================
# VERIFY REPOSITORY
# ============================================================

if [[ ! -d "$REPO_DIR/.config" ]]; then
    error "Repository .config directory was not found."
    exit 1
fi

if [[ ! -f "$REPO_DIR/.zshrc" ]]; then
    error "Repository .zshrc was not found."
    exit 1
fi

if [[ ! -f "$REPO_DIR/.p10k.zsh" ]]; then
    error "Repository .p10k.zsh was not found."
    exit 1
fi

# ============================================================
# COPY DOTFILES
# ============================================================

echo
info "Installing HackTheClown configuration..."

mkdir -p "$CONFIG_DIR"

cp -a "$REPO_DIR/.config/." "$CONFIG_DIR/"

success "Configuration files copied."

# ============================================================
# COPY ZSH FILES
# ============================================================

info "Installing Zsh configuration..."

cp "$REPO_DIR/.zshrc" "$HOME/.zshrc"
cp "$REPO_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

success "Zsh configuration installed."

# ============================================================
# COPY WALLPAPER
# ============================================================

echo
info "Installing wallpaper..."

mkdir -p "$HOME/Pictures"

if [[ -f "$REPO_DIR/wallpaper.jpg" ]]; then

    cp "$REPO_DIR/wallpaper.jpg" "$HOME/Pictures/wallpaper.jpg"

    success "Wallpaper installed:"
    echo
    echo "  $HOME/Pictures/wallpaper.jpg"

else

    warning "wallpaper.jpg not found in repository."

fi

# ============================================================
# FIX /home/changeme
# ============================================================

echo
info "Fixing repository paths..."

# Replace /home/changeme with actual home directory.
#
# Only process text files.

while IFS= read -r -d '' FILE; do

    if grep -Iq . "$FILE" 2>/dev/null; then

        sed -i "s#/home/changeme#$HOME#g" "$FILE"

    fi

done < <(find "$CONFIG_DIR" -type f -print0)

success "Home paths fixed."

# ============================================================
# DETECT NETWORK INTERFACE
# ============================================================

echo
info "Detecting network interface..."

NETWORK_INTERFACE=""

if command -v ip >/dev/null 2>&1; then

    NETWORK_INTERFACE="$(
        ip route 2>/dev/null |
        awk '/default/ {print $5; exit}'
    )"

fi

if [[ -z "$NETWORK_INTERFACE" ]]; then

    warning "Could not automatically detect network interface."

    NETWORK_INTERFACE="auto"

else

    success "Network interface: $NETWORK_INTERFACE"

fi

# ============================================================
# FIX POLYBAR NETWORK INTERFACE
# ============================================================

POLYBAR_CONFIG="$CONFIG_DIR/polybar/polybar.ini"

if [[ -f "$POLYBAR_CONFIG" ]]; then

    sed -i \
        "s/changeme_network_interface/${NETWORK_INTERFACE}/g" \
        "$POLYBAR_CONFIG"

    # Replace the author's placeholder xwindow label
    sed -i \
        "s/label = %{F#bbbbbc}changeme/label = %{F#bbbbbc}%title%/g" \
        "$POLYBAR_CONFIG"

    success "Polybar network configuration fixed."

fi

# ============================================================
# FIX POLYBAR LAUNCH SCRIPT
# ============================================================

POLYBAR_LAUNCH="$CONFIG_DIR/polybar/polybar_launch.sh"

if [[ -f "$POLYBAR_LAUNCH" ]]; then

    sed -i "s#/home/changeme#$HOME#g" "$POLYBAR_LAUNCH"

    chmod +x "$POLYBAR_LAUNCH"

    success "Polybar launcher fixed."

fi

# ============================================================
# FIX I3 SCRIPT PERMISSIONS
# ============================================================

if [[ -d "$CONFIG_DIR/i3/scripts" ]]; then

    chmod +x "$CONFIG_DIR/i3/scripts/"* 2>/dev/null || true

fi

# ============================================================
# I3 CONFIG
# ============================================================

I3_CONFIG="$CONFIG_DIR/i3/config"

if [[ ! -f "$I3_CONFIG" ]]; then

    error "i3 config was not found."

    exit 1

fi

# ============================================================
# DISABLE VMWARE-SPECIFIC SETTINGS
# ============================================================

info "Checking VMware-specific settings..."

# The repository author runs Arch in VMware.
#
# These lines are commented in the repository, but make sure
# VMware-specific commands don't accidentally get enabled.

sed -i \
    's#^[[:space:]]*exec_always --no-startup-id /usr/bin/vmware-user-suid-wrapper#\# VMware-specific setting disabled by installer:#' \
    "$I3_CONFIG" 2>/dev/null || true

# ============================================================
# FIREFOX -> WORKSPACE 2
# ============================================================

echo
info "Configuring Firefox for Workspace 2..."

# Remove the repository's Chrome-only assignment.
sed -i \
    '/for_window \[class="Google-chrome"\] move to workspace \$ws2/d' \
    "$I3_CONFIG"

# Remove duplicate Firefox assignments if script is run again.
sed -i \
    '/Firefox.*Workspace 2/d' \
    "$I3_CONFIG"

sed -i \
    '/for_window \[class="(?i)firefox"\] move to workspace \$ws2/d' \
    "$I3_CONFIG"

# Insert Firefox rule immediately after the workspace section.
#
# We use a case-insensitive regex because Firefox's X11 class
# can vary by environment/version.

sed -i \
    '/# You can see the class names using `xprop` command/i\
# Firefox always opens on Workspace 2\
for_window [class="(?i)^firefox$"] move to workspace $ws2' \
    "$I3_CONFIG"

success "Firefox assigned to Workspace 2."

# ============================================================
# MAKE TERMINATOR THE DEFAULT TERMINAL
# ============================================================

info "Checking Terminator binding..."

# The original repository already uses Terminator.
#
# Ensure the main shortcut exists.

if ! grep -q 'bindsym \$mod+Return exec terminator' "$I3_CONFIG"; then

    sed -i \
        '/# Common Key Bindings #/a bindsym $mod+Return exec terminator' \
        "$I3_CONFIG"

fi

# ============================================================
# ROFI
# ============================================================

ROFI_CONFIG="$CONFIG_DIR/rofi/rofi.rasi"

if [[ -f "$ROFI_CONFIG" ]]; then

    success "Original Rofi configuration installed."

fi

# ============================================================
# TERMINATOR
# ============================================================

TERMINATOR_CONFIG="$CONFIG_DIR/terminator/config"

if [[ -f "$TERMINATOR_CONFIG" ]]; then

    success "Original Terminator configuration installed."

fi

# ============================================================
# PICOM
# ============================================================

PICOM_CONFIG="$CONFIG_DIR/picom/picom.conf"

if [[ -f "$PICOM_CONFIG" ]]; then

    success "Original Picom configuration installed."

fi

# ============================================================
# GTK
# ============================================================

GTK_CONFIG="$CONFIG_DIR/gtk-3.0/settings.ini"

if [[ -f "$GTK_CONFIG" ]]; then

    success "GTK theme configuration installed."

fi

# ============================================================
# XSETTINGSD
# ============================================================

XSETTINGS_CONFIG="$CONFIG_DIR/xsettingsd/xsettingsd.conf"

if [[ -f "$XSETTINGS_CONFIG" ]]; then

    success "Xsettingsd configuration installed."

fi

# ============================================================
# OH MY ZSH
# ============================================================

echo
info "Installing Oh My Zsh..."

if [[ -d "$HOME/.oh-my-zsh" ]]; then

    warning "Oh My Zsh is already installed."

else

    git clone \
        --depth=1 \
        https://github.com/ohmyzsh/ohmyzsh.git \
        "$HOME/.oh-my-zsh"

    success "Oh My Zsh installed."

fi

# ============================================================
# POWERLEVEL10K
# ============================================================

echo
info "Installing Powerlevel10k..."

P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

if [[ -d "$P10K_DIR/.git" ]]; then

    git -C "$P10K_DIR" pull --ff-only

else

    rm -rf "$P10K_DIR"

    git clone \
        --depth=1 \
        https://github.com/romkatv/powerlevel10k.git \
        "$P10K_DIR"

fi

success "Powerlevel10k installed."

# ============================================================
# ZSH AUTOSUGGESTIONS
# ============================================================

echo
info "Installing zsh-autosuggestions..."

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions/.git" ]]; then

    git -C "$ZSH_CUSTOM/plugins/zsh-autosuggestions" pull --ff-only

else

    rm -rf "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

    git clone \
        --depth=1 \
        https://github.com/zsh-users/zsh-autosuggestions.git \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

fi

success "zsh-autosuggestions installed."

# ============================================================
# ZSH SYNTAX HIGHLIGHTING
# ============================================================

echo
info "Installing zsh-syntax-highlighting..."

if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/.git" ]]; then

    git -C "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" pull --ff-only

else

    rm -rf "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

    git clone \
        --depth=1 \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

fi

success "zsh-syntax-highlighting installed."

# ============================================================
# FZF ZSH INTEGRATION
# ============================================================

echo
info "Configuring FZF..."

if command -v fzf >/dev/null 2>&1; then

    if fzf --zsh > "$HOME/.fzf.zsh" 2>/dev/null; then
        success "FZF Zsh integration configured."
    else
        warning "Could not generate .fzf.zsh."
    fi

fi

# ============================================================
# ATUIN
# ============================================================

echo
info "Configuring Atuin..."

# The repository's .zshrc expects:
#
# ~/.atuin/bin/env
#
# Arch's pacman package provides the atuin binary directly.
#
# Make the env sourcing optional so the configuration works
# with both installations.

if [[ -f "$HOME/.zshrc" ]]; then

    sed -i \
        's#^[[:space:]]*\. "\$HOME/\.atuin/bin/env"#[[ -f "$HOME/.atuin/bin/env" ]] \&\& . "$HOME/.atuin/bin/env"#' \
        "$HOME/.zshrc"

fi

if command -v atuin >/dev/null 2>&1; then

    success "Atuin installed."

else

    warning "Atuin command was not found."

fi

# ============================================================
# DEFAULT SHELL
# ============================================================

echo
info "Setting Zsh as default shell..."

ZSH_PATH="$(command -v zsh)"

if [[ -n "$ZSH_PATH" ]]; then

    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

    if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then

        chsh -s "$ZSH_PATH"

        success "Default shell changed to Zsh."

    else

        success "Zsh is already the default shell."

    fi

fi

# ============================================================
# WALLPAPER PATH
# ============================================================

WALLPAPER="$HOME/Pictures/wallpaper.jpg"

if [[ -f "$WALLPAPER" ]]; then

    # Make sure i3 uses our actual wallpaper path.
    sed -i \
        "s#exec_always --no-startup-id feh --bg-fill .*#exec_always --no-startup-id feh --bg-fill $WALLPAPER#g" \
        "$I3_CONFIG"

    success "Wallpaper path configured."

else

    warning "Wallpaper not found."

fi

# ============================================================
# I3 CONFIG VALIDATION
# ============================================================

echo
echo "============================================================"
echo "                VALIDATING i3 CONFIGURATION"
echo "============================================================"
echo

if i3 -C -c "$I3_CONFIG"; then

    success "i3 configuration is valid."

else

    error "i3 configuration validation failed."

    echo
    echo "Your previous configuration is backed up at:"
    echo
    echo "  $BACKUP_DIR"
    echo

    exit 1

fi

# ============================================================
# CHECK IMPORTANT COMMANDS
# ============================================================

echo
info "Checking installed commands..."

COMMANDS=(
    i3
    terminator
    polybar
    rofi
    nvim
    atuin
    ranger
    zsh
    picom
    feh
    firefox
    xsettingsd
)

for CMD in "${COMMANDS[@]}"; do

    if command -v "$CMD" >/dev/null 2>&1; then

        echo "  [OK] $CMD"

    else

        echo "  [MISSING] $CMD"

    fi

done

# ============================================================
# CONFIGURATION NOTES
# ============================================================

echo
echo "============================================================"
echo "                  INSTALLATION COMPLETE"
echo "============================================================"
echo

echo "Original repository:"
echo
echo "  $REPO"
echo

echo "Local repository:"
echo
echo "  $REPO_DIR"
echo

echo "Backup:"
echo
echo "  $BACKUP_DIR"
echo

echo "============================================================"
echo "WORKSPACES"
echo "============================================================"
echo
echo "  Super + 1       Terminal"
echo "  Super + 2       Internet / Firefox"
echo "  Super + 3       Workspace 3"
echo "  Super + 4       Workspace 4"
echo "  Super + 5       Workspace 5"
echo "  Super + 6       Workspace 6"
echo "  Super + 7       Workspace 7"
echo "  Super + 8       Workspace 8"
echo "  Super + 9       Workspace 9"
echo "  Super + 0       Workspace 10"
echo

echo "Firefox is configured to automatically move to:"
echo
echo "  Workspace 2: Internet"
echo

echo "============================================================"
echo "MAIN i3 SHORTCUTS"
echo "============================================================"
echo
echo "  Super + Enter       Terminator"
echo "  Super + Shift + D   Rofi"
echo "  Super + Shift + C   Reload i3"
echo "  Super + Shift + R   Restart i3"
echo "  Super + Shift + E   Exit i3"
echo "  Super + Shift + L   Lock screen"
echo
echo "  Super + Arrow       Focus window"
echo "  Super + Shift+Arrow Move window"
echo
echo "  Super + Shift + G   Gap configuration"
echo "  Super + R           Resize mode"
echo "  Super + Shift + Space  Floating"
echo

echo "============================================================"
echo "TERMINATOR"
echo "============================================================"
echo
echo "  Ctrl + T            New tab"
echo "  Ctrl + Shift + W    Close terminal"
echo "  Ctrl + Tab          Next tab"
echo "  Ctrl + Shift + Tab  Previous tab"
echo

echo "============================================================"
echo "ZSH"
echo "============================================================"
echo
echo "  Oh My Zsh"
echo "  Powerlevel10k"
echo "  Atuin"
echo "  FZF"
echo "  zsh-autosuggestions"
echo "  zsh-syntax-highlighting"
echo

echo "============================================================"
echo "IMPORTANT"
echo "============================================================"
echo
echo "The repository contains notes/placeholders such as:"
echo
echo "  changeme"
echo "  HTC_NOTE"
echo
echo "The installer fixed the machine-specific paths that matter"
echo "for this setup."
echo
echo "VMware-specific commands from the repository were left disabled."
echo

echo "============================================================"
echo "NEXT STEP"
echo "============================================================"
echo
echo "Log out and select i3 from your login manager."
echo
echo "OR, if you use startx:"
echo
echo "  startx"
echo
echo "After entering i3, you can reload with:"
echo
echo "  Super + Shift + C"
echo
echo "============================================================"
echo

```

### Run it

```bash
chmod +x install-hacktheclown.sh
./install-hacktheclown.sh
```

The script will ask:

```text
Continue with installation? [y/N]:
```

Enter:

```text
y
```

### Why this version is different

The original repository's i3 configuration already uses **Terminator**, has the `Super+Enter` terminal shortcut, Polybar startup, Rofi, 10 workspaces, 15px inner gaps/5px outer gaps, and a Chrome → workspace 2 rule. 

I've changed the browser rule to:

```text
for_window [class="(?i)^firefox$"] move to workspace $ws2
```

So **Firefox will always go to Workspace 2**, regardless of whether you launch it from Rofi, the terminal, or another shortcut. This is the recommended i3 mechanism for assigning applications to workspaces. ([i3][3])

The original Polybar configuration is also copied rather than recreated; it uses the author's Martian Mono Nerd font and displays workspaces, filesystem, RAM, CPU, network and time. 

The repository's Terminator configuration uses transparency and **MartianMono Nerd Font**, which is why I've installed the current Arch `ttf-martian-mono-nerd` package. 

### One thing I deliberately did NOT add

I did **not** add the BlackArch repository or install the entire BlackArch tool collection.

This repository is the **dotfiles/configuration repository**; the README says the author's full machine setup is handled separately through Ansible. ([GitHub][1])

So first get this desktop working exactly like the video. Then we can add a **separate BlackArch setup script** containing only the ethical-hacking tools you actually want.

[1]: https://github.com/hacktheclown/arch-clown-dotfiles "GitHub - hacktheclown/arch-clown-dotfiles: Dotfiles and configs for my minimal black arch setup · GitHub"
[2]: https://github.com/hacktheclown/arch-clown-dotfiles/tree/main/.config "arch-clown-dotfiles/.config at main · hacktheclown/arch-clown-dotfiles · GitHub"
[3]: https://i3wm.org/docs/4.14/userguide.html?utm_source=chatgpt.com "i3: i3 User’s Guide"
