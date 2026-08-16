#!/usr/bin/env bash

# ============================================================
# ARCH LINUX - DARK GREEN MINIMAL i3 DESKTOP
# ============================================================
#
# Theme inspired by the supplied screenshot:
#
#   Dark green / black background
#   Muted sage terminal colors
#   Minimal i3
#   Thin Polybar
#   Terminator
#   Ranger
#   Neovim
#   Rofi
#   Atuin
#
# ============================================================

set -Eeuo pipefail

# ============================================================
# COLORS FOR INSTALLER
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
# BASIC CHECKS
# ============================================================

if [[ "${EUID}" -eq 0 ]]; then
    error "Do not run this script as root."
    echo
    echo "Run it as your normal user:"
    echo
    echo "  ./setup-arch-darkgreen.sh"
    echo
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    error "This script is designed for Arch Linux."
    exit 1
fi

USER_NAME="${USER}"
HOME_DIR="${HOME}"

echo
echo "============================================================"
echo "      ARCH LINUX DARK GREEN i3 DESKTOP"
echo "============================================================"
echo
echo "User : ${USER_NAME}"
echo "Home : ${HOME_DIR}"
echo

# ============================================================
# UPDATE SYSTEM
# ============================================================

info "Updating Arch Linux..."

sudo pacman -Syu --noconfirm

success "System updated."

# ============================================================
# INSTALL PACKAGES
# ============================================================

info "Installing required packages..."

PACKAGES=(
    i3-wm
    i3status
    polybar
    rofi
    ranger
    neovim
    atuin
    terminator
    picom
    feh
    xclip
    xorg-server
    xorg-xinit
    xorg-xrandr
    git
    curl
    wget
    unzip
    base-devel
    scrot
    file
    imagemagick
    ffmpegthumbnailer
    poppler
    atool
    highlight
    bat
    tree
    jq
    ripgrep
    fd
    ttf-jetbrains-mono
    ttf-font-awesome
    noto-fonts
    noto-fonts-emoji
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

success "Required packages installed."

# ============================================================
# BACKUP EXISTING CONFIGURATION
# ============================================================

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${HOME_DIR}/.config-backup-${TIMESTAMP}"

info "Creating configuration backup..."

mkdir -p "${BACKUP_DIR}"

CONFIGS=(
    i3
    polybar
    rofi
    terminator
    nvim
    picom
    ranger
    atuin
)

for CONFIG in "${CONFIGS[@]}"; do
    if [[ -e "${HOME_DIR}/.config/${CONFIG}" ]]; then
        cp -a "${HOME_DIR}/.config/${CONFIG}" "${BACKUP_DIR}/"
    fi
done

success "Backup created:"
echo
echo "  ${BACKUP_DIR}"
echo

# ============================================================
# CREATE DIRECTORIES
# ============================================================

info "Creating configuration directories..."

mkdir -p \
    "${HOME_DIR}/.config/i3" \
    "${HOME_DIR}/.config/polybar" \
    "${HOME_DIR}/.config/rofi" \
    "${HOME_DIR}/.config/terminator" \
    "${HOME_DIR}/.config/nvim/lua" \
    "${HOME_DIR}/.config/picom" \
    "${HOME_DIR}/.config/ranger" \
    "${HOME_DIR}/.config/atuin" \
    "${HOME_DIR}/Pictures" \
    "${HOME_DIR}/Pictures/wallpapers"

# ============================================================
# DARK GREEN COLOR PALETTE
# ============================================================
#
# Background       #101817
# Background Alt   #17201F
# Foreground       #AAB8A8
# Dim              #65736A
# Green            #8FAF8F
# Bright Green     #A8C3A0
# Border           #34423D
# Yellow           #B5A36A
# Red              #A66A6A
#
# ============================================================

# ============================================================
# i3 CONFIGURATION
# ============================================================

info "Creating i3 configuration..."

cat > "${HOME_DIR}/.config/i3/config" <<'EOF'
# ============================================================
# i3 - DARK GREEN MINIMAL THEME
# ============================================================

set $mod Mod4

# ============================================================
# FONT
# ============================================================

font pango:JetBrains Mono 10

# ============================================================
# COLORS
# ============================================================

set $bg        #101817
set $bg2       #17201F
set $fg        #AAB8A8

set $green     #8FAF8F
set $bright    #A8C3A0
set $dim       #65736A

set $border    #34423D

set $yellow    #B5A36A
set $red       #A66A6A

# ============================================================
# WINDOW BORDERS
# ============================================================

default_border pixel 1
default_floating_border pixel 1

client.focused          $green  $bg2 $fg $bright
client.focused_inactive $border $bg2 $dim $border
client.unfocused        $border $bg  $dim $border
client.urgent           $red    $bg2 $fg $red

# ============================================================
# GAPS
# ============================================================

gaps inner 3
gaps outer 2

# ============================================================
# TERMINAL
# ============================================================

set $term terminator

bindsym $mod+Return exec --no-startup-id $term

# ============================================================
# ROFI
# ============================================================

bindsym $mod+Shift+d exec --no-startup-id rofi -show drun

# ============================================================
# CLOSE WINDOW
# ============================================================

bindsym $mod+Shift+q kill

# ============================================================
# RELOAD / RESTART
# ============================================================

bindsym $mod+Shift+c reload

bindsym $mod+Shift+r restart

# ============================================================
# FOCUS
# ============================================================

bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Vim-style focus

bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# ============================================================
# MOVE WINDOWS
# ============================================================

bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Vim-style move

bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# ============================================================
# SPLIT
# ============================================================

bindsym $mod+v split vertical
bindsym $mod+b split horizontal

# ============================================================
# LAYOUT
# ============================================================

bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# ============================================================
# FULLSCREEN
# ============================================================

bindsym $mod+f fullscreen toggle

# ============================================================
# FLOATING
# ============================================================

bindsym $mod+Shift+space floating toggle

# ============================================================
# WORKSPACES
# ============================================================

set $ws1 "1:term"
set $ws2 "2:web"
set $ws3 "3:code"
set $ws4 "4:recon"
set $ws5 "5:tools"
set $ws6 "6:misc"

bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6

# ============================================================
# MOVE WINDOW TO WORKSPACE
# ============================================================

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6

# ============================================================
# RESIZE
# ============================================================

mode "resize" {

    bindsym Left resize shrink width 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt

    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt

    bindsym Return mode "default"
    bindsym Escape mode "default"
}

bindsym $mod+r mode "resize"

# ============================================================
# APPLICATION SHORTCUTS
# ============================================================

# Neovim
bindsym $mod+Shift+n exec --no-startup-id terminator -e nvim

# Ranger
bindsym $mod+Shift+e exec --no-startup-id terminator -e ranger

# ============================================================
# SCREENSHOT
# ============================================================

bindsym Print exec --no-startup-id scrot "${HOME}/Pictures/screenshot-%Y%m%d-%H%M%S.png"

# ============================================================
# STARTUP
# ============================================================

exec --no-startup-id "${HOME}/.config/i3/startup.sh"

exec_always --no-startup-id "${HOME}/.config/polybar/launch.sh"

# ============================================================
# END
# ============================================================
EOF

success "i3 configuration created."

# ============================================================
# i3 STARTUP SCRIPT
# ============================================================

info "Creating i3 startup script..."

cat > "${HOME_DIR}/.config/i3/startup.sh" <<'EOF'
#!/usr/bin/env bash

# ============================================================
# i3 STARTUP
# ============================================================

# ------------------------------------------------------------
# Wallpaper
# ------------------------------------------------------------

WALLPAPER="${HOME}/Pictures/wallpaper.jpg"

if [[ -f "${WALLPAPER}" ]]; then
    feh --no-fehbg --bg-fill "${WALLPAPER}"
fi

# ------------------------------------------------------------
# Disable screen blanking
# ------------------------------------------------------------

xset s off
xset -dpms
xset s noblank

# ------------------------------------------------------------
# Keyboard
# ------------------------------------------------------------

setxkbmap us

# ------------------------------------------------------------
# Picom
# ------------------------------------------------------------

if ! pgrep -x picom >/dev/null 2>&1; then
    picom --config "${HOME}/.config/picom/picom.conf" &
fi
EOF

chmod +x "${HOME_DIR}/.config/i3/startup.sh"

success "i3 startup configured."

# ============================================================
# POLYBAR
# ============================================================

info "Creating Polybar configuration..."

cat > "${HOME_DIR}/.config/polybar/config.ini" <<'EOF'
; ============================================================
; POLYBAR - DARK GREEN MINIMAL
; ============================================================

[colors]

background = #101817
background-alt = #17201F

foreground = #AAB8A8
foreground-alt = #65736A

green = #8FAF8F
bright = #A8C3A0

border = #34423D

yellow = #B5A36A
red = #A66A6A

; ============================================================
; BAR
; ============================================================

[bar/main]

width = 100%
height = 24

background = ${colors.background}
foreground = ${colors.foreground}

border-size = 0

padding-left = 1
padding-right = 1

module-margin = 1

font-0 = JetBrains Mono:size=9;2

modules-left = i3
modules-center = date
modules-right = filesystem memory cpu network

separator = "  "

wm-restack = i3

enable-ipc = true

tray-position = right
tray-padding = 1

cursor-click = pointer

; ============================================================
; WORKSPACES
; ============================================================

[module/i3]

type = internal/i3

index-sort = true

pin-workspaces = true

strip-wsnumbers = false

label-focused = %name%
label-focused-foreground = ${colors.bright}
label-focused-background = ${colors.background-alt}
label-focused-padding = 1

label-unfocused = %name%
label-unfocused-foreground = ${colors.dim}
label-unfocused-padding = 1

label-visible = %name%
label-visible-foreground = ${colors.green}
label-visible-padding = 1

label-urgent = %name%
label-urgent-foreground = ${colors.red}
label-urgent-padding = 1

; ============================================================
; CPU
; ============================================================

[module/cpu]

type = internal/cpu

interval = 2

format-prefix = "CPU "
format-prefix-foreground = ${colors.green}

label = %percentage:2%%

; ============================================================
; MEMORY
; ============================================================

[module/memory]

type = internal/memory

interval = 2

format-prefix = "RAM "
format-prefix-foreground = ${colors.green}

label = %percentage_used:2%%

; ============================================================
; FILESYSTEM
; ============================================================

[module/filesystem]

type = internal/fs

mount-0 = /

interval = 30

format-mounted-prefix = "DISK "
format-mounted-prefix-foreground = ${colors.green}

label-mounted = %percentage_used%%

; ============================================================
; NETWORK
; ============================================================

[module/network]

type = internal/network

interface = auto

interval = 2

format-connected-prefix = "NET "
format-connected-prefix-foreground = ${colors.green}

label-connected = %local_ip% ↓%downspeed% ↑%upspeed%

label-disconnected = OFFLINE
label-disconnected-foreground = ${colors.red}

; ============================================================
; DATE / TIME
; ============================================================

[module/date]

type = internal/date

interval = 1

date = %Y-%m-%d

time = %H:%M

label = %date%  %time%

label-foreground = ${colors.dim}
EOF

cat > "${HOME_DIR}/.config/polybar/launch.sh" <<'EOF'
#!/usr/bin/env bash

# Kill existing Polybar

killall -q polybar 2>/dev/null || true

# Wait until old Polybar processes disappear

while pgrep -u "${UID}" -x polybar >/dev/null 2>&1; do
    sleep 1
done

# Start Polybar

polybar main &
EOF

chmod +x "${HOME_DIR}/.config/polybar/launch.sh"

success "Polybar configured."

# ============================================================
# ROFI
# ============================================================

info "Creating Rofi theme..."

cat > "${HOME_DIR}/.config/rofi/config.rasi" <<'EOF'
configuration {
    modi: "drun,run,window";
    show-icons: true;

    display-drun: " Apps ";
    display-run: " Run ";
    display-window: " Windows ";

    drun-display-format: "{name}";

    font: "JetBrains Mono 10";
}

* {
    background: #101817;
    background-alt: #17201F;

    foreground: #AAB8A8;
    foreground-alt: #65736A;

    green: #8FAF8F;
    bright: #A8C3A0;

    border: #34423D;
}

window {
    width: 650px;

    border: 1px;
    border-color: #34423D;

    border-radius: 4px;

    background-color: #101817;
}

mainbox {
    padding: 15px;
}

inputbar {
    padding: 8px;

    background-color: #17201F;
}

prompt {
    text-color: #8FAF8F;
}

entry {
    text-color: #AAB8A8;
}

listview {
    lines: 8;
    columns: 1;

    spacing: 3px;

    padding: 10px 0px;
}

element {
    padding: 7px;
}

element normal {
    background-color: transparent;
    text-color: #AAB8A8;
}

element selected {
    background-color: #17201F;
    text-color: #A8C3A0;
}
EOF

success "Rofi configured."

# ============================================================
# TERMINATOR
# ============================================================

info "Creating Terminator configuration..."

cat > "${HOME_DIR}/.config/terminator/config" <<'EOF'
[global_config]
  enabled_plugins = LaunchpadCodeURLHandler, LaunchpadBugURLHandler, LaunchpadSystemURLHandler, APTURLHandler

[keybindings]
  split_horiz = <Primary><Shift>o
  split_vert = <Primary><Shift>e
  close_term = <Primary><Shift>w
  new_tab = <Primary><Shift>t
  next_tab = <Primary>Page_Down
  prev_tab = <Primary>Page_Up

[profiles]
  [[default]]

    # --------------------------------------------------------
    # Appearance
    # --------------------------------------------------------

    background_color = "#101817"
    foreground_color = "#AAB8A8"

    cursor_color = "#8FAF8F"

    font = JetBrains Mono 10
    use_system_font = False

    scrollbar_position = hidden

    scrollback_lines = 10000

    show_titlebar = False

    cursor_blink = False

    allow_bold = True

    background_darkness = 0.98

    # --------------------------------------------------------
    # Dark Green Palette
    # --------------------------------------------------------

    palette = "#101817:#A66A6A:#8FAF8F:#B5A36A:#7FA39A:#9A8FAF:#79A89F:#AAB8A8:#65736A:#C08080:#A8C3A0:#C0B080:#91B5AA:#B0A0C0:#8AB8AE:#D0D8D0"

    # --------------------------------------------------------
    # Terminal behavior
    # --------------------------------------------------------

    use_custom_command = False

[layouts]

  [[default]]

    [[[child1]]]

      type = Terminal
      parent = window0

    [[[window0]]]

      type = Window
      parent = ""

[plugins]
EOF

success "Terminator configured."

# ============================================================
# PICOM
# ============================================================

info "Creating Picom configuration..."

cat > "${HOME_DIR}/.config/picom/picom.conf" <<'EOF'
# ============================================================
# PICOM - SUBTLE EFFECTS
# ============================================================

backend = "glx";

vsync = true;

shadow = true;

shadow-radius = 6;

shadow-opacity = 0.20;

fading = true;

fade-in-step = 0.03;

fade-out-step = 0.03;

inactive-opacity = 0.98;

active-opacity = 1.0;

detect-rounded-corners = true;

wintypes:
{
    tooltip = {
        fade = true;
        shadow = true;
        opacity = 0.95;
    };

    dock = {
        shadow = false;
    };

    dnd = {
        shadow = false;
    };

    popup_menu = {
        opacity = 0.96;
    };

    dropdown_menu = {
        opacity = 0.96;
    };
};
EOF

success "Picom configured."

# ============================================================
# RANGER
# ============================================================

info "Creating Ranger configuration..."

cat > "${HOME_DIR}/.config/ranger/rc.conf" <<'EOF'
# ============================================================
# RANGER
# ============================================================

set show_hidden true

set draw_borders both

set column_ratios 1,3,4

set preview_files true

set preview_directories true

set vcs_aware true

# ============================================================
# Shortcuts
# ============================================================

map gh cd ~

map gd cd ~/Downloads

map gp cd ~/Pictures

map gc cd ~/.config

# ============================================================
# Useful commands
# ============================================================

map e edit
EOF

# Ranger rifle
cat > "${HOME_DIR}/.config/ranger/rifle.conf" <<'EOF'
# ============================================================
# RANGER RIFLE
# ============================================================

# Text files
mime ^text,  label editor = nvim -- "$@"

# Python
ext py = nvim -- "$@"

# Shell
ext sh = nvim -- "$@"

# JavaScript
ext js = nvim -- "$@"

# JSON
ext json = nvim -- "$@"

# Images
mime ^image, has feh = feh -- "$@"

# PDF
ext pdf, has zathura = zathura "$@"

# Videos
mime ^video, has mpv = mpv -- "$@"
EOF

success "Ranger configured."

# ============================================================
# RANGER IMAGE PREVIEW
# ============================================================

info "Checking Ranger image preview support..."

if command -v ueberzugpp >/dev/null 2>&1; then

    success "ueberzugpp already installed."

elif command -v paru >/dev/null 2>&1; then

    info "Installing ueberzugpp using paru..."

    paru -S --needed --noconfirm ueberzugpp

elif command -v yay >/dev/null 2>&1; then

    info "Installing ueberzugpp using yay..."

    yay -S --needed --noconfirm ueberzugpp

else

    warning "ueberzugpp is not installed."

    echo
    echo "Ranger itself is installed, but image previews may not"
    echo "work until ueberzugpp is installed."
    echo
    echo "If you use an AUR helper later, install:"
    echo
    echo "  paru -S ueberzugpp"
    echo
    echo "or:"
    echo
    echo "  yay -S ueberzugpp"
    echo
fi

# ============================================================
# ATUIN
# ============================================================

info "Configuring Atuin..."

CURRENT_SHELL="$(basename "${SHELL}")"

if [[ "${CURRENT_SHELL}" == "bash" ]]; then

    if [[ ! -f "${HOME_DIR}/.bashrc" ]]; then
        touch "${HOME_DIR}/.bashrc"
    fi

    if ! grep -q "atuin init bash" "${HOME_DIR}/.bashrc"; then

        cat >> "${HOME_DIR}/.bashrc" <<'EOF'

# ============================================================
# ATUIN
# ============================================================

eval "$(atuin init bash)"
EOF

    fi

elif [[ "${CURRENT_SHELL}" == "zsh" ]]; then

    if [[ ! -f "${HOME_DIR}/.zshrc" ]]; then
        touch "${HOME_DIR}/.zshrc"
    fi

    if ! grep -q "atuin init zsh" "${HOME_DIR}/.zshrc"; then

        cat >> "${HOME_DIR}/.zshrc" <<'EOF'

# ============================================================
# ATUIN
# ============================================================

eval "$(atuin init zsh)"
EOF

    fi

else

    warning "Shell ${CURRENT_SHELL} detected."

    echo "Atuin was installed but shell integration was not modified."

fi

success "Atuin configured."

# ============================================================
# NEOVIM
# ============================================================

info "Creating Neovim configuration..."

cat > "${HOME_DIR}/.config/nvim/init.lua" <<'EOF'
-- ============================================================
-- NEOVIM - DARK GREEN MINIMAL
-- ============================================================

vim.opt.number = true

vim.opt.relativenumber = true

vim.opt.termguicolors = true

vim.opt.expandtab = true

vim.opt.shiftwidth = 4

vim.opt.tabstop = 4

vim.opt.smartindent = true

vim.opt.cursorline = true

vim.opt.signcolumn = "yes"

vim.opt.showmode = false

vim.opt.scrolloff = 6

vim.opt.wrap = false

vim.g.mapleader = " "

-- ============================================================
-- DARK GREEN COLORS
-- ============================================================

vim.cmd([[
    highlight Normal
        \ guibg=#101817
        \ guifg=#AAB8A8

    highlight NormalFloat
        \ guibg=#17201F
        \ guifg=#AAB8A8

    highlight Comment
        \ guifg=#65736A
        \ gui=italic

    highlight String
        \ guifg=#8FAF8F

    highlight Function
        \ guifg=#A8C3A0

    highlight Keyword
        \ guifg=#91B5AA

    highlight Type
        \ guifg=#9FAF9F

    highlight Constant
        \ guifg=#B5A36A

    highlight Number
        \ guifg=#B5A36A

    highlight Boolean
        \ guifg=#B5A36A

    highlight Identifier
        \ guifg=#AAB8A8

    highlight Statement
        \ guifg=#8FAF8F

    highlight LineNr
        \ guifg=#34423D

    highlight CursorLineNr
        \ guifg=#8FAF8F

    highlight CursorLine
        \ guibg=#17201F

    highlight Visual
        \ guibg=#34423D

    highlight Search
        \ guibg=#34423D
        \ guifg=#A8C3A0

    highlight IncSearch
        \ guibg=#8FAF8F
        \ guifg=#101817
]])

-- ============================================================
-- LAZY.NVIM
-- ============================================================

local lazypath =
    vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then

    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })

end

vim.opt.rtp:prepend(lazypath)

-- ============================================================
-- PLUGINS
-- ============================================================

require("lazy").setup({

    {
        "folke/twilight.nvim",

        opts = {
            dimming = {
                alpha = 0.25,
            },
        },
    },

})

-- ============================================================
-- TWILIGHT
-- ============================================================

vim.keymap.set(
    "n",
    "<leader>t",
    ":Twilight<CR>",
    {
        silent = true,
    }
)

-- ============================================================
-- SAVE
-- ============================================================

vim.keymap.set(
    "n",
    "<C-s>",
    ":w<CR>",
    {
        silent = true,
    }
)

-- ============================================================
-- QUIT
-- ============================================================

vim.keymap.set(
    "n",
    "<C-q>",
    ":q<CR>",
    {
        silent = true,
    }
)
EOF

success "Neovim configured."

# ============================================================
# XINITRC
# ============================================================

info "Configuring .xinitrc..."

if [[ ! -f "${HOME_DIR}/.xinitrc" ]]; then

    cat > "${HOME_DIR}/.xinitrc" <<'EOF'
#!/bin/sh

exec i3
EOF

    chmod +x "${HOME_DIR}/.xinitrc"

else

    if ! grep -q "exec i3" "${HOME_DIR}/.xinitrc"; then

        warning ".xinitrc already exists."

        echo
        echo "It was NOT modified."
        echo
        echo "If you use startx, make sure it starts i3."
        echo

    fi
fi

# ============================================================
# WALLPAPER
# ============================================================

info "Checking wallpaper..."

if [[ ! -f "${HOME_DIR}/Pictures/wallpaper.jpg" ]]; then

    warning "No wallpaper found."

    echo
    echo "Put your wallpaper here:"
    echo
    echo "  ${HOME_DIR}/Pictures/wallpaper.jpg"
    echo
    echo "The screenshot's dark moon/island style wallpaper"
    echo "will work particularly well with this theme."
    echo

else

    success "Wallpaper found."

fi

# ============================================================
# PERMISSIONS
# ============================================================

chmod +x "${HOME_DIR}/.config/i3/startup.sh"
chmod +x "${HOME_DIR}/.config/polybar/launch.sh"

# ============================================================
# VALIDATE I3
# ============================================================

echo
echo "============================================================"
echo "              VALIDATING i3 CONFIGURATION"
echo "============================================================"
echo

if i3 -C; then

    success "i3 configuration is valid."

else

    error "i3 configuration contains an error."

    echo
    echo "Run this command to see the problem:"
    echo
    echo "  i3 -C"
    echo

    exit 1

fi

# ============================================================
# FINAL INFORMATION
# ============================================================

echo
echo
echo "============================================================"
echo "             INSTALLATION COMPLETE"
echo "============================================================"
echo
echo "Theme:"
echo
echo "  Dark Green / Sage / Minimal Unix"
echo
echo "============================================================"
echo "Installed"
echo "============================================================"
echo
echo "  i3             Window manager"
echo "  Terminator     Terminal"
echo "  Polybar        Status bar"
echo "  Rofi           Application launcher"
echo "  Ranger         Terminal file manager"
echo "  Neovim         Editor"
echo "  Twilight       Neovim focus mode"
echo "  Atuin          Shell history"
echo "  Picom          Compositor"
echo "  Feh            Wallpaper"
echo
echo "============================================================"
echo "Keyboard Shortcuts"
echo "============================================================"
echo
echo "  Super + Enter"
echo "      Open Terminator"
echo
echo "  Super + Shift + D"
echo "      Rofi application launcher"
echo
echo "  Super + 1"
echo "      Workspace 1"
echo
echo "  Super + 2"
echo "      Workspace 2"
echo
echo "  Super + 3"
echo "      Workspace 3"
echo
echo "  Super + 4"
echo "      Workspace 4"
echo
echo "  Super + 5"
echo "      Workspace 5"
echo
echo "  Super + 6"
echo "      Workspace 6"
echo
echo "  Super + Arrow"
echo "      Change window focus"
echo
echo "  Super + H/J/K/L"
echo "      Change window focus"
echo
echo "  Super + Shift + Arrow"
echo "      Move window"
echo
echo "  Super + F"
echo "      Fullscreen"
echo
echo "  Super + Shift + Q"
echo "      Close window"
echo
echo "  Super + Shift + C"
echo "      Reload i3"
echo
echo "  Super + Shift + R"
echo "      Restart i3"
echo
echo "  Super + Shift + N"
echo "      Terminator + Neovim"
echo
echo "  Super + Shift + E"
echo "      Terminator + Ranger"
echo
echo "============================================================"
echo "Terminator Shortcuts"
echo "============================================================"
echo
echo "  Ctrl + Shift + O"
echo "      Split horizontally"
echo
echo "  Ctrl + Shift + E"
echo "      Split vertically"
echo
echo "  Ctrl + Shift + W"
echo "      Close terminal"
echo
echo "  Ctrl + Shift + T"
echo "      New tab"
echo
echo "============================================================"
echo "Wallpaper"
echo "============================================================"
echo
echo "  ${HOME_DIR}/Pictures/wallpaper.jpg"
echo
echo "============================================================"
echo "Configuration Backup"
echo "============================================================"
echo
echo "  ${BACKUP_DIR}"
echo
echo "============================================================"
echo
echo "To restart i3 now:"
echo
echo "  i3-msg restart"
echo
echo "============================================================"
echo
