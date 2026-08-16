#!/usr/bin/env bash

# ============================================================
# BlackArch Setup for Existing Arch Linux
# ============================================================
#
# Official BlackArch:
# https://blackarch.org/
#
# This script adds BlackArch to an existing Arch installation.
#
# It DOES NOT replace Arch Linux.
# It DOES NOT install the BlackArch desktop environment.
#
# Designed to work with:
#   - Arch Linux
#   - i3
#   - HackTheClown dotfiles
#   - User: any normal Arch user
#
# ============================================================

set -Eeuo pipefail

# ============================================================
# VARIABLES
# ============================================================

BLACKARCH_URL="https://blackarch.org/strap.sh"

# Current SHA1 published on the official BlackArch downloads page.
BLACKARCH_SHA1="00688950aaf5e5804d2abebb8d3d3ea1d28525ed"

TEMP_DIR="$(mktemp -d)"

STRAP_FILE="${TEMP_DIR}/strap.sh"

BACKUP_DIR="${HOME}/.blackarch-backup-$(date +%Y%m%d-%H%M%S)"

# ============================================================
# COLORS
# ============================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[ OK ]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

section() {
    echo
    echo "============================================================"
    echo " $1"
    echo "============================================================"
    echo
}

# ============================================================
# CLEANUP
# ============================================================

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

trap 'error "Script failed at line $LINENO."' ERR

# ============================================================
# ROOT CHECK
# ============================================================

if [[ "$EUID" -eq 0 ]]; then
    error "Do not run this script as root."
    echo
    echo "Run:"
    echo
    echo "  ./install-blackarch.sh"
    echo
    exit 1
fi

# ============================================================
# ARCH CHECK
# ============================================================

if ! command -v pacman >/dev/null 2>&1; then
    error "pacman was not found."
    error "This script requires Arch Linux."
    exit 1
fi

# ============================================================
# INTERNET CHECK
# ============================================================

section "NETWORK CHECK"

if ! curl -fsI --max-time 10 https://blackarch.org >/dev/null 2>&1; then
    error "Cannot reach blackarch.org."
    error "Check your Internet connection."
    exit 1
fi

success "Internet connection available."

# ============================================================
# HEADER
# ============================================================

clear

echo
echo "============================================================"
echo "              BLACKARCH SETUP FOR ARCH LINUX"
echo "============================================================"
echo
echo "This will add the official BlackArch repository to your"
echo "existing Arch Linux installation."
echo
echo "Your existing:"
echo
echo "  i3"
echo "  Polybar"
echo "  Rofi"
echo "  Terminator"
echo "  Neovim"
echo "  Zsh"
echo "  HackTheClown dotfiles"
echo
echo "will NOT be replaced."
echo
echo "============================================================"
echo

read -r -p "Continue? [y/N]: " ANSWER

if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
    echo
    echo "Cancelled."
    exit 0
fi

# ============================================================
# INSTALL BASIC DEPENDENCIES
# ============================================================

section "INSTALLING DEPENDENCIES"

sudo pacman -S --needed --noconfirm \
    curl \
    wget \
    git \
    gnupg \
    ca-certificates \
    base-devel

success "Dependencies installed."

# ============================================================
# BACKUP PACMAN CONFIGURATION
# ============================================================

section "BACKING UP PACMAN CONFIGURATION"

mkdir -p "$BACKUP_DIR"

sudo cp /etc/pacman.conf \
    "$BACKUP_DIR/pacman.conf"

if [[ -f /etc/pacman.d/blackarch-mirrorlist ]]; then

    sudo cp \
        /etc/pacman.d/blackarch-mirrorlist \
        "$BACKUP_DIR/blackarch-mirrorlist"

fi

success "Pacman configuration backed up."

echo
echo "Backup:"
echo
echo "  $BACKUP_DIR"

# ============================================================
# DOWNLOAD BLACKARCH STRAP
# ============================================================

section "DOWNLOADING BLACKARCH STRAP"

info "Downloading official BlackArch strap.sh..."

curl -fL \
    "$BLACKARCH_URL" \
    -o "$STRAP_FILE"

success "strap.sh downloaded."

# ============================================================
# VERIFY SHA1
# ============================================================

section "VERIFYING BLACKARCH STRAP"

ACTUAL_SHA1="$(
    sha1sum "$STRAP_FILE" |
    awk '{print $1}'
)"

echo
echo "Expected:"
echo
echo "  $BLACKARCH_SHA1"
echo
echo "Actual:"
echo
echo "  $ACTUAL_SHA1"
echo

if [[ "$ACTUAL_SHA1" != "$BLACKARCH_SHA1" ]]; then

    error "SHA1 verification FAILED."

    echo
    echo "The downloaded file does not match the SHA1 published"
    echo "by BlackArch."
    echo
    echo "The script will NOT execute it."
    echo

    exit 1

fi

success "SHA1 verification passed."

# ============================================================
# EXECUTE STRAP
# ============================================================

section "INSTALLING BLACKARCH REPOSITORY"

chmod +x "$STRAP_FILE"

info "Running official BlackArch strap.sh..."

sudo "$STRAP_FILE"

success "BlackArch repository installed."

# ============================================================
# ENABLE MULTILIB
# ============================================================

section "CONFIGURING MULTILIB"

PACMAN_CONF="/etc/pacman.conf"

if grep -Eq '^[[:space:]]*\[multilib\]' "$PACMAN_CONF"; then

    success "Multilib is already enabled."

else

    info "Enabling multilib..."

    sudo sed -i \
        '/^[[:space:]]*#\[multilib\]/,/^[[:space:]]*#Include = \/etc\/pacman\.d\/mirrorlist/{
            s/^[[:space:]]*#\[multilib\]/[multilib]/
            s/^[[:space:]]*#Include = \/etc\/pacman\.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/
        }' \
        "$PACMAN_CONF"

    if grep -Eq '^[[:space:]]*\[multilib\]' "$PACMAN_CONF"; then

        success "Multilib enabled."

    else

        warning "Could not automatically enable multilib."

        echo
        echo "You can enable it manually later in:"
        echo
        echo "  /etc/pacman.conf"
        echo

    fi

fi

# ============================================================
# UPDATE DATABASE
# ============================================================

section "SYNCHRONIZING REPOSITORIES"

sudo pacman -Syyu --noconfirm

success "Repositories synchronized."

# ============================================================
# BLACKARCH CHECK
# ============================================================

section "CHECKING BLACKARCH"

if pacman -Sl blackarch >/dev/null 2>&1; then

    success "BlackArch repository is available."

else

    error "BlackArch repository was not detected."

    echo
    echo "Check:"
    echo
    echo "  grep -n blackarch /etc/pacman.conf"
    echo

    exit 1

fi

# ============================================================
# DISPLAY BLACKARCH INFO
# ============================================================

echo
info "BlackArch repository information:"

pacman -Sl blackarch 2>/dev/null |
    head -10 ||
    true

# ============================================================
# PACKAGE INSTALL FUNCTION
# ============================================================

install_packages() {

    local packages=("$@")
    local available=()
    local missing=()

    for package in "${packages[@]}"; do

        if pacman -Si "$package" >/dev/null 2>&1; then

            available+=("$package")

        else

            missing+=("$package")

        fi

    done

    if [[ "${#available[@]}" -gt 0 ]]; then

        echo
        info "Installing available packages..."

        sudo pacman -S \
            --needed \
            --noconfirm \
            "${available[@]}"

    fi

    if [[ "${#missing[@]}" -gt 0 ]]; then

        echo
        warning "Packages not found:"

        printf '  %s\n' "${missing[@]}"

        echo

    fi
}

# ============================================================
# ESSENTIAL TOOLKIT
# ============================================================

install_essential() {

    section "ESSENTIAL SECURITY TOOLKIT"

    install_packages \
        nmap \
        masscan \
        netcat \
        socat \
        tcpdump \
        traceroute \
        whois \
        dnsutils \
        bind \
        curl \
        wget \
        openssl \
        jq \
        ripgrep \
        ffuf \
        gobuster \
        nikto \
        sqlmap \
        hydra \
        john \
        hashcat \
        hashcat-utils \
        metasploit \
        exploitdb \
        searchsploit \
        wireshark-qt \
        tshark

    success "Essential toolkit installation finished."

}

# ============================================================
# WEB SECURITY
# ============================================================

install_web() {

    section "WEB APPLICATION SECURITY"

    install_packages \
        ffuf \
        gobuster \
        feroxbuster \
        dirsearch \
        nikto \
        sqlmap \
        wpscan \
        whatweb \
        wafw00f \
        nuclei \
        httpx \
        katana \
        dalfox \
        arjun \
        commix \
        burpsuite \
        mitmproxy \
        zaproxy

    success "Web security tools installation finished."

}

# ============================================================
# RECON
# ============================================================

install_recon() {

    section "RECONNAISSANCE"

    install_packages \
        nmap \
        masscan \
        amass \
        subfinder \
        dnsrecon \
        dnsenum \
        fierce \
        theharvester \
        recon-ng \
        spiderfoot \
        whois \
        whatweb \
        wafw00f \
        httpx \
        nuclei \
        assetfinder

    success "Reconnaissance tools installation finished."

}

# ============================================================
# NETWORK
# ============================================================

install_network() {

    section "NETWORK SECURITY"

    install_packages \
        nmap \
        masscan \
        rustscan \
        netcat \
        socat \
        tcpdump \
        tshark \
        wireshark-qt \
        ettercap \
        bettercap \
        mitmproxy \
        responder \
        arp-scan \
        netdiscover \
        traceroute \
        hping \
        scapy

    success "Network tools installation finished."

}

# ============================================================
# PASSWORD AUDITING
# ============================================================

install_password() {

    section "PASSWORD AUDITING"

    install_packages \
        john \
        hashcat \
        hashcat-utils \
        hydra \
        medusa \
        patator \
        crunch \
        hashid \
        hash-identifier \
        ophcrack

    success "Password auditing tools installation finished."

}

# ============================================================
# WIRELESS
# ============================================================

install_wireless() {

    section "WIRELESS SECURITY"

    install_packages \
        aircrack-ng \
        kismet \
        bettercap \
        reaver \
        bully \
        pixiewps \
        wifite \
        hcxdumptool \
        hcxpcapngtool \
        macchanger \
        iw \
        wireless_tools

    success "Wireless security tools installation finished."

}

# ============================================================
# FORENSICS
# ============================================================

install_forensics() {

    section "DIGITAL FORENSICS"

    install_packages \
        binwalk \
        foremost \
        sleuthkit \
        autopsy \
        volatility3 \
        yara \
        exiftool \
        testdisk \
        photorec \
        strings

    success "Forensics tools installation finished."

}

# ============================================================
# TRAFFIC / SNIFFING
# ============================================================

install_sniffing() {

    section "SNIFFING / TRAFFIC ANALYSIS"

    install_packages \
        wireshark-qt \
        tshark \
        tcpdump \
        ettercap \
        bettercap \
        mitmproxy \
        netsniff-ng \
        ngrep \
        scapy

    success "Traffic analysis tools installation finished."

}

# ============================================================
# EXPLOITATION
# ============================================================

install_exploitation() {

    section "EXPLOITATION / SECURITY TESTING"

    install_packages \
        metasploit \
        exploitdb \
        searchsploit \
        sqlmap \
        commix \
        routersploit \
        beef \
        set

    success "Exploitation/security testing tools installation finished."

}

# ============================================================
# REVERSE ENGINEERING
# ============================================================

install_reverse() {

    section "REVERSE ENGINEERING"

    install_packages \
        radare2 \
        gdb \
        ghidra \
        binwalk \
        strings \
        strace \
        ltrace \
        yara \
        objdump

    success "Reverse engineering tools installation finished."

}

# ============================================================
# OSINT
# ============================================================

install_osint() {

    section "OSINT"

    install_packages \
        theharvester \
        recon-ng \
        spiderfoot \
        sherlock \
        maigret \
        holehe \
        whois \
        dnsrecon \
        dnsenum

    success "OSINT tools installation finished."

}

# ============================================================
# STEGANOGRAPHY
# ============================================================

install_stego() {

    section "STEGANOGRAPHY"

    install_packages \
        steghide \
        stegseek \
        zsteg \
        exiftool \
        binwalk \
        foremost

    success "Steganography tools installation finished."

}

# ============================================================
# LIST CATEGORIES
# ============================================================

show_categories() {

    section "BLACKARCH CATEGORIES"

    pacman -Sg |
        awk '$1 ~ /^blackarch-/ {print $1}' |
        sort -u

}

# ============================================================
# SEARCH
# ============================================================

search_tools() {

    echo
    read -r -p "Enter package/tool name: " QUERY

    if [[ -z "$QUERY" ]]; then
        warning "Search query cannot be empty."
        return
    fi

    echo

    pacman -Ss "$QUERY"

}

# ============================================================
# INSTALL BLACKARCH GROUP
# ============================================================

install_all_blackarch() {

    section "ALL BLACKARCH TOOLS"

    echo
    warning "WARNING"
    echo
    echo "This can install a very large number of packages."
    echo
    echo "BlackArch currently contains roughly 2,800+ tools."
    echo
    echo "This may:"
    echo
    echo "  - consume a lot of disk space"
    echo "  - consume significant download bandwidth"
    echo "  - introduce package conflicts"
    echo "  - take a long time"
    echo
    echo "For most systems, installing selected categories is better."
    echo

    read -r -p "Install the complete blackarch group? [y/N]: " CONFIRM

    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then

        warning "Full installation cancelled."

        return

    fi

    sudo pacman -S \
        --needed \
        blackarch

}

# ============================================================
# UPDATE BLACKARCH
# ============================================================

update_system() {

    section "SYSTEM UPDATE"

    sudo pacman -Syu --noconfirm

    success "System updated."

}

# ============================================================
# INSTALL BASIC PERSONAL TOOLS
# ============================================================

install_cli_tools() {

    section "CLI SECURITY ENVIRONMENT"

    install_packages \
        bat \
        eza \
        fzf \
        ripgrep \
        fd \
        jq \
        tree \
        tmux \
        zoxide \
        python \
        python-pip \
        go \
        rust

    success "CLI environment installed."

}

# ============================================================
# MENU
# ============================================================

while true; do

    clear

    echo
    echo "============================================================"
    echo "              BLACKARCH SECURITY TOOLKIT"
    echo "============================================================"
    echo
    echo "BlackArch repository:"
    echo "  INSTALLED"
    echo
    echo "Choose what you want to install:"
    echo
    echo "  1) Essential security toolkit"
    echo "  2) Web application security"
    echo "  3) Reconnaissance"
    echo "  4) Network security"
    echo "  5) Password auditing"
    echo "  6) Wireless security"
    echo "  7) Digital forensics"
    echo "  8) Sniffing / traffic analysis"
    echo "  9) Exploitation / security testing"
    echo " 10) Reverse engineering"
    echo " 11) OSINT"
    echo " 12) Steganography"
    echo " 13) CLI/security environment"
    echo
    echo " 14) Show BlackArch categories"
    echo " 15) Search BlackArch packages"
    echo " 16) Update system"
    echo
    echo " 17) Install ALL BlackArch tools"
    echo
    echo "  0) Exit"
    echo
    echo "============================================================"
    echo

    read -r -p "Select [0-17]: " OPTION

    case "$OPTION" in

        1)
            install_essential
            read -r -p "Press Enter to continue..."
            ;;

        2)
            install_web
            read -r -p "Press Enter to continue..."
            ;;

        3)
            install_recon
            read -r -p "Press Enter to continue..."
            ;;

        4)
            install_network
            read -r -p "Press Enter to continue..."
            ;;

        5)
            install_password
            read -r -p "Press Enter to continue..."
            ;;

        6)
            install_wireless
            read -r -p "Press Enter to continue..."
            ;;

        7)
            install_forensics
            read -r -p "Press Enter to continue..."
            ;;

        8)
            install_sniffing
            read -r -p "Press Enter to continue..."
            ;;

        9)
            install_exploitation
            read -r -p "Press Enter to continue..."
            ;;

        10)
            install_reverse
            read -r -p "Press Enter to continue..."
            ;;

        11)
            install_osint
            read -r -p "Press Enter to continue..."
            ;;

        12)
            install_stego
            read -r -p "Press Enter to continue..."
            ;;

        13)
            install_cli_tools
            read -r -p "Press Enter to continue..."
            ;;

        14)
            show_categories
            echo
            read -r -p "Press Enter to continue..."
            ;;

        15)
            search_tools
            echo
            read -r -p "Press Enter to continue..."
            ;;

        16)
            update_system
            read -r -p "Press Enter to continue..."
            ;;

        17)
            install_all_blackarch
            echo
            read -r -p "Press Enter to continue..."
            ;;

        0)
            break
            ;;

        *)
            warning "Invalid option."
            sleep 1
            ;;

    esac

done

# ============================================================
# FINAL STATUS
# ============================================================

clear

section "BLACKARCH SETUP COMPLETE"

echo
echo "BlackArch repository:"
echo
echo "  pacman -Sl blackarch"
echo

echo "Search for tools:"
echo
echo "  pacman -Ss <name>"
echo

echo "List BlackArch categories:"
echo
echo "  pacman -Sg | grep blackarch"
echo

echo "List all BlackArch packages:"
echo
echo "  pacman -Sgg | grep blackarch | cut -d' ' -f2 | sort -u"
echo

echo "Install a category:"
echo
echo "  sudo pacman -S blackarch-<category>"
echo

echo "Example:"
echo
echo "  sudo pacman -S blackarch-webapp"
echo

echo "Your existing HackTheClown i3 environment was not replaced."
echo

echo "============================================================"
echo

success "BlackArch is ready."
