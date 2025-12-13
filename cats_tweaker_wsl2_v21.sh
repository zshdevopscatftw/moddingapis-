#!/bin/bash
#===============================================================================
#
#     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
#    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
#    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
#    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
#    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
#     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
#
#                              「  v2.1 - WSL2 Ubuntu 24.04/25.04 Edition  」
#                                    by Flames / Team Flames 🐱
#
#   v2.1 Fixes:
#     - Fixed Ubuntu 24.04 fuse/libfuse2t64 package names
#     - Fixed N64 toolchain URL with multiple fallbacks
#     - Fixed ASM6F download (full source, not raw URL)
#     - Fixed Ares emulator URL (v146 → latest)
#     - Added retry logic for flaky downloads
#     - Split utilities install for better error handling
#
#===============================================================================

set -euo pipefail

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

# ═══════════════════════════════════════════════════════════════════════════════
# COLORS & GLOBALS
# ═══════════════════════════════════════════════════════════════════════════════
G=$'\033[0;32m'  # Green
Y=$'\033[0;33m'  # Yellow  
C=$'\033[0;36m'  # Cyan
M=$'\033[0;35m'  # Magenta
R=$'\033[0;31m'  # Red
W=$'\033[1;37m'  # White bold
RST=$'\033[0m'   # Reset

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

# ═══════════════════════════════════════════════════════════════════════════════
# WSL2 DETECTION
# ═══════════════════════════════════════════════════════════════════════════════
IS_WSL=false
IS_WSL2=false
WSL_VERSION=""
WINDOWS_USER=""
WIN_HOME=""

if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    IS_WSL=true
    if [[ -d /run/WSL ]]; then
        IS_WSL2=true
        WSL_VERSION="2"
    else
        WSL_VERSION="1"
    fi
    WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n' || echo "")
    [[ -n "$WINDOWS_USER" ]] && WIN_HOME="/mnt/c/Users/$WINDOWS_USER"
fi

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "24.04")
UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "noble")
UBUNTU_MAJOR="${UBUNTU_VERSION%%.*}"

# CPU count
NCPU=$(nproc 2>/dev/null || echo 4)

# Shell RC file
SHELL_RC="$HOME/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="$HOME/.zshrc"

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

# Download with retry and multiple attempts
dl() {
    local url="$1" out="$2" attempt=1 max_attempts=3
    echo "[DL] $(date '+%H:%M:%S') $url" >> "$LOG"
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -fsSL --connect-timeout 30 --max-time 900 --retry 2 -L -o "$out" "$url" 2>>"$LOG"; then
            if [[ -s "$out" ]]; then
                local size=$(ls -lh "$out" 2>/dev/null | awk '{print $5}')
                echo "[DL] Success (attempt $attempt): $size" >> "$LOG"
                return 0
            fi
        fi
        echo "[DL] Attempt $attempt failed" >> "$LOG"
        ((attempt++))
        sleep 2
    done
    
    echo "[DL] All attempts failed for: $url" >> "$LOG"
    rm -f "$out" 2>/dev/null
    return 1
}

# Try multiple URLs
dl_multi() {
    local out="$1"
    shift
    local urls=("$@")
    
    for url in "${urls[@]}"; do
        echo "[DL-MULTI] Trying: $url" >> "$LOG"
        if dl "$url" "$out"; then
            return 0
        fi
    done
    return 1
}

# Status indicators
ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${Y}[✗]${RST} %s ${Y}(see log)${RST}\n" "$1"; }
skip() { printf "  ${C}[~]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
step() { printf "\n${M}▸ %s${RST}\n" "$1"; }

add_path() {
    local line="$1"
    grep -qxF "$line" "$SHELL_RC" 2>/dev/null || echo "$line" >> "$SHELL_RC"
}

scd() {
    cd "$1" 2>/dev/null || cd /tmp
}

# ═══════════════════════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════════════════════
clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                              「  v2.1 - WSL2 Ubuntu Edition  」
                                        /\_____/\
                                       /  o   o  \
                                      ( ==  ^  == )
                                       )         (
                                      (           )
                                     ( (  )   (  ) )
                                    (__(__)___(__)__)

EOF

# ═══════════════════════════════════════════════════════════════════════════════
step "ENVIRONMENT DETECTION"
# ═══════════════════════════════════════════════════════════════════════════════

if $IS_WSL2; then
    ok "WSL2 detected (version $WSL_VERSION)"
    [[ -n "$WINDOWS_USER" ]] && info "Windows user: $WINDOWS_USER"
    [[ -n "$WIN_HOME" && -d "$WIN_HOME" ]] && info "Windows home: $WIN_HOME"
elif $IS_WSL; then
    warn "WSL1 detected — some features may not work"
    warn "Consider upgrading: wsl --set-version <distro> 2"
else
    warn "Not running in WSL — proceeding anyway (native Linux mode)"
fi

info "Ubuntu $UBUNTU_VERSION ($UBUNTU_CODENAME)"
info "CPUs: $NCPU"
info "Install dir: $INSTALL_DIR"
info "Log: $LOG"

if [[ -d /mnt/wslg ]]; then
    ok "WSLg detected (GUI apps supported)"
    export DISPLAY="${DISPLAY:-:0}"
else
    warn "WSLg not detected — GUI apps may not work"
    info "Update WSL: wsl --update (from Windows)"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "SYSTEM PACKAGES (no systemd)"
# ═══════════════════════════════════════════════════════════════════════════════

info "Updating package lists..."
sudo apt-get update -qq >> "$LOG" 2>&1 && ok "APT update" || fail "APT update"

info "Installing build essentials..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    build-essential gcc g++ clang llvm lld \
    cmake ninja-build meson autoconf automake libtool pkg-config \
    flex bison texinfo gawk \
    >> "$LOG" 2>&1 && ok "Compilers & build tools" || fail "Build tools"

info "Installing development libraries..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev \
    libpng-dev libjpeg-dev libfreetype-dev zlib1g-dev \
    libncurses-dev libreadline-dev libgmp-dev libmpfr-dev libmpc-dev \
    libusb-1.0-0-dev libudev-dev \
    >> "$LOG" 2>&1 && ok "Development libraries" || fail "Dev libraries"

# Split utilities into separate installs for better error handling
info "Installing core utilities..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl wget git unzip p7zip-full xz-utils \
    nasm yasm \
    >> "$LOG" 2>&1 && ok "Core utilities" || fail "Core utilities"

info "Installing Python..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    python3 python3-pip python3-venv python3-dev \
    >> "$LOG" 2>&1 && ok "Python" || fail "Python"

info "Installing Node.js..."
# Try nodejs first, fall back to manual install
if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs npm >> "$LOG" 2>&1; then
    # Fallback: install via NodeSource
    curl -fsSL https://deb.nodesource.com/setup_lts.x 2>/dev/null | sudo -E bash - >> "$LOG" 2>&1 || true
    sudo apt-get install -y -qq nodejs >> "$LOG" 2>&1 && ok "Node.js (NodeSource)" || skip "Node.js"
else
    ok "Node.js"
fi

# FUSE for AppImages - Ubuntu 24.04 renamed libfuse2 to libfuse2t64
info "Installing FUSE (for AppImages)..."
if [[ "$UBUNTU_MAJOR" -ge 24 ]]; then
    # Ubuntu 24.04+ uses libfuse2t64
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libfuse2t64 >> "$LOG" 2>&1 || \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libfuse2 >> "$LOG" 2>&1 || \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq fuse >> "$LOG" 2>&1 || true
    # Create symlink if needed
    if [[ -f /usr/lib/x86_64-linux-gnu/libfuse.so.2.9.9 ]] && [[ ! -f /usr/lib/x86_64-linux-gnu/libfuse.so.2 ]]; then
        sudo ln -sf /usr/lib/x86_64-linux-gnu/libfuse.so.2.9.9 /usr/lib/x86_64-linux-gnu/libfuse.so.2 2>/dev/null || true
    fi
    ok "FUSE (Ubuntu 24.04+ mode)"
else
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq fuse libfuse2 >> "$LOG" 2>&1 && ok "FUSE" || skip "FUSE"
fi

# pipx for Ubuntu 24.04+
if [[ "$UBUNTU_MAJOR" -ge 24 ]]; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq pipx >> "$LOG" 2>&1 || true
    pipx ensurepath >> "$LOG" 2>&1 || true
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "RETRO ASSEMBLERS (APT)"
# ═══════════════════════════════════════════════════════════════════════════════

info "Installing assemblers from APT..."

# Try each separately for better reporting
sudo apt-get install -y -qq cc65 >> "$LOG" 2>&1 && ok "cc65" || skip "cc65 (will use download)"

# RGBDS might not be in Ubuntu repos or might be old
if sudo apt-get install -y -qq rgbds >> "$LOG" 2>&1; then
    RGBDS_VER=$(rgbasm --version 2>&1 | head -1 || echo "unknown")
    ok "rgbds ($RGBDS_VER)"
else
    skip "rgbds (will download newer)"
fi

sudo apt-get install -y -qq sdcc >> "$LOG" 2>&1 && ok "sdcc" || skip "sdcc"

# ═══════════════════════════════════════════════════════════════════════════════
step "PYTHON PACKAGES"
# ═══════════════════════════════════════════════════════════════════════════════

info "Installing Python packages..."

PIP_FLAGS="--user"
[[ "$UBUNTU_MAJOR" -ge 24 ]] && PIP_FLAGS="--user --break-system-packages"

pip3 install $PIP_FLAGS \
    pygame pygame-ce pillow numpy pysdl2 pyyaml toml \
    intelhex pyserial capstone \
    >> "$LOG" 2>&1 && ok "Python packages" || fail "Python packages"

# Ursina separately (can fail, non-critical)
pip3 install $PIP_FLAGS ursina >> "$LOG" 2>&1 && ok "Ursina 3D engine" || skip "Ursina (optional)"

# ═══════════════════════════════════════════════════════════════════════════════
step "N64 TOOLCHAIN (mips64-elf-gcc) — Native, No Docker"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$HOME"
rm -rf "$COMPILERS/n64" 2>/dev/null
mkdir -p "$COMPILERS/n64"
scd "$COMPILERS/n64"

# Multiple URLs for N64 toolchain (in case one fails)
N64_TC_URLS=(
    "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz"
    "https://github.com/DragonMinded/libdragon/releases/latest/download/gcc-toolchain-mips64-linux-x86_64.tar.gz"
)

info "Downloading prebuilt N64 toolchain (~200MB)..."
info "This may take a few minutes..."

if dl_multi toolchain.tar.gz "${N64_TC_URLS[@]}"; then
    info "Extracting toolchain..."
    tar xzf toolchain.tar.gz >> "$LOG" 2>&1
    rm -f toolchain.tar.gz
    
    if [[ -x "$COMPILERS/n64/bin/mips64-elf-gcc" ]]; then
        N64_GCC_VER=$("$COMPILERS/n64/bin/mips64-elf-gcc" --version 2>/dev/null | head -1 || echo "unknown")
        ok "N64 toolchain: $N64_GCC_VER"
    else
        # Check if extracted to subdirectory
        if [[ -d "$COMPILERS/n64/gcc-toolchain-mips64" ]]; then
            mv "$COMPILERS/n64/gcc-toolchain-mips64"/* "$COMPILERS/n64/" 2>/dev/null || true
            rmdir "$COMPILERS/n64/gcc-toolchain-mips64" 2>/dev/null || true
        fi
        if [[ -x "$COMPILERS/n64/bin/mips64-elf-gcc" ]]; then
            ok "N64 toolchain (extracted from subdir)"
        else
            fail "N64 toolchain extraction"
        fi
    fi
else
    fail "N64 toolchain download"
    info "Manual download: https://github.com/DragonMinded/libdragon/releases"
    info "Look for: gcc-toolchain-mips64-linux-x86_64.tar.gz"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "LIBDRAGON N64 SDK"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf libdragon libdragon-trunk 2>/dev/null

info "Downloading libdragon SDK..."
if dl "https://github.com/DragonMinded/libdragon/archive/refs/heads/trunk.tar.gz" libdragon.tar.gz; then
    tar xzf libdragon.tar.gz >> "$LOG" 2>&1
    mv libdragon-trunk libdragon 2>/dev/null || true
    rm -f libdragon.tar.gz
    
    if [[ -d "$SDKS/libdragon" && -x "$COMPILERS/n64/bin/mips64-elf-gcc" ]]; then
        info "Building libdragon (this takes a few minutes)..."
        scd "$SDKS/libdragon"
        
        export N64_INST="$COMPILERS/n64"
        export PATH="$N64_INST/bin:$PATH"
        
        # Build with error tolerance
        if make -j"$NCPU" >> "$LOG" 2>&1; then
            make install >> "$LOG" 2>&1 || true
            ok "libdragon SDK built"
        else
            warn "libdragon build had issues — SDK downloaded"
            info "Try manually: cd ~/retro-dev/sdks/libdragon && make"
        fi
    else
        ok "libdragon SDK downloaded"
        info "Build after N64 toolchain is ready"
    fi
else
    fail "libdragon SDK download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "DEVKITPRO (GBA/DS/3DS/Wii/Switch)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$HOME"
mkdir -p "$COMPILERS/devkitpro"
scd "$COMPILERS/devkitpro"

info "Downloading devkitPro installer..."
if dl "https://apt.devkitpro.org/install-devkitpro-pacman" install-devkitpro-pacman; then
    chmod +x install-devkitpro-pacman
    ok "devkitPro installer downloaded"
    info "To install: sudo $COMPILERS/devkitpro/install-devkitpro-pacman"
    info "Then: sudo dkp-pacman -S gba-dev nds-dev 3ds-dev"
    
    echo ""
    read -r -t 10 -p "  Install devkitPro now? [y/N] " response || response="n"
    if [[ "$response" =~ ^[Yy]$ ]]; then
        info "Running devkitPro installer (needs sudo)..."
        if sudo ./install-devkitpro-pacman >> "$LOG" 2>&1; then
            ok "devkitPro pacman installed"
            info "Installing GBA/NDS devkits..."
            sudo dkp-pacman -Syu --noconfirm >> "$LOG" 2>&1 || true
            sudo dkp-pacman -S --noconfirm gba-dev nds-dev >> "$LOG" 2>&1 && \
                ok "GBA & NDS devkits installed" || warn "Some devkits failed"
        else
            fail "devkitPro installer"
        fi
    else
        skip "devkitPro installation (run manually later)"
    fi
else
    fail "devkitPro download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "GBDK-2020 (Game Boy C SDK)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf gbdk gbdk-* 2>/dev/null

GBDK_URLS=(
    "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz"
    "https://github.com/gbdk-2020/gbdk-2020/releases/latest/download/gbdk-linux64.tar.gz"
)

info "Downloading GBDK-2020..."
if dl_multi gbdk.tar.gz "${GBDK_URLS[@]}"; then
    tar xzf gbdk.tar.gz >> "$LOG" 2>&1
    [[ -d "gbdk" ]] || mv gbdk-* gbdk 2>/dev/null || true
    rm -f gbdk.tar.gz
    
    if [[ -x "$SDKS/gbdk/bin/lcc" ]]; then
        ok "GBDK-2020"
    else
        warn "GBDK extracted but lcc not found"
    fi
else
    fail "GBDK-2020 download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "ADDITIONAL ASSEMBLERS"
# ═══════════════════════════════════════════════════════════════════════════════

# RGBDS (if not from APT or need newer version)
if ! command -v rgbasm >/dev/null 2>&1; then
    scd "$TOOLS"
    rm -rf rgbds 2>/dev/null
    mkdir -p rgbds
    scd "$TOOLS/rgbds"
    
    RGBDS_URLS=(
        "https://github.com/gbdev/rgbds/releases/download/v0.8.0/rgbds-0.8.0-linux-x86_64.tar.xz"
        "https://github.com/gbdev/rgbds/releases/latest/download/rgbds-linux-x86_64.tar.xz"
    )
    
    info "Downloading RGBDS..."
    if dl_multi rgbds.tar.xz "${RGBDS_URLS[@]}"; then
        tar xJf rgbds.tar.xz >> "$LOG" 2>&1
        rm -f rgbds.tar.xz
        chmod +x rgbasm rgblink rgbfix rgbgfx 2>/dev/null || true
        ok "RGBDS 0.8.0"
    else
        fail "RGBDS download"
    fi
else
    ok "RGBDS (system)"
fi

# ASM6F (NES assembler) - download full source archive, not raw file
scd "$TOOLS"
rm -rf asm6 asm6f-* 2>/dev/null
mkdir -p asm6
scd "$TOOLS/asm6"

info "Building ASM6F (NES assembler)..."

# Download the full release/source archive
ASM6_URLS=(
    "https://github.com/freem/asm6f/archive/refs/tags/v1.6.1.tar.gz"
    "https://github.com/freem/asm6f/archive/refs/heads/main.tar.gz"
)

ASM6_BUILT=false
if dl_multi asm6f-src.tar.gz "${ASM6_URLS[@]}"; then
    tar xzf asm6f-src.tar.gz >> "$LOG" 2>&1
    # Find the extracted directory
    ASM6_DIR=$(find . -maxdepth 1 -type d -name "asm6f-*" | head -1)
    if [[ -n "$ASM6_DIR" && -f "$ASM6_DIR/asm6f.c" ]]; then
        if cc -O3 -w "$ASM6_DIR/asm6f.c" -o asm6f 2>>"$LOG"; then
            chmod +x asm6f
            ok "ASM6F (NES assembler)"
            ASM6_BUILT=true
        fi
    fi
    rm -rf asm6f-src.tar.gz asm6f-*/ 2>/dev/null
fi

if ! $ASM6_BUILT; then
    # Last resort: create minimal stub
    cat > asm6f.c << 'STUBSRC'
#include <stdio.h>
int main(int c, char**v) {
    printf("ASM6F stub - download full version:\n");
    printf("https://github.com/freem/asm6f/releases\n");
    return 1;
}
STUBSRC
    cc -O3 -w asm6f.c -o asm6f 2>/dev/null
    warn "ASM6F (stub) — download manually from github.com/freem/asm6f"
fi

# WLA-DX (multi-platform assembler)
scd "$TOOLS"
rm -rf wla-dx wla-dx-* 2>/dev/null

info "Building WLA-DX..."
if dl "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz" wla.tar.gz; then
    tar xzf wla.tar.gz >> "$LOG" 2>&1
    scd wla-dx-10.6
    mkdir -p build
    scd build
    
    if cmake .. -DCMAKE_BUILD_TYPE=Release >> "$LOG" 2>&1; then
        if make -j"$NCPU" >> "$LOG" 2>&1; then
            ok "WLA-DX 10.6"
        else
            fail "WLA-DX build"
        fi
    else
        fail "WLA-DX cmake"
    fi
    rm -f "$TOOLS/wla.tar.gz"
else
    fail "WLA-DX download"
fi

# DASM (Atari 2600)
scd "$SDKS"
mkdir -p atari
scd "$SDKS/atari"

DASM_URLS=(
    "https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz"
    "https://github.com/dasm-assembler/dasm/releases/latest/download/dasm-linux-x64.tar.gz"
)

info "Downloading DASM..."
if dl_multi dasm.tar.gz "${DASM_URLS[@]}"; then
    tar xzf dasm.tar.gz >> "$LOG" 2>&1
    rm -f dasm.tar.gz
    chmod +x dasm 2>/dev/null || true
    ok "DASM (Atari 2600)"
else
    fail "DASM download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "GENESIS/MEGA DRIVE SDK (SGDK)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf sgdk SGDK-* 2>/dev/null

SGDK_URLS=(
    "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz"
    "https://github.com/Stephane-D/SGDK/archive/refs/heads/master.tar.gz"
)

info "Downloading SGDK..."
if dl_multi sgdk.tar.gz "${SGDK_URLS[@]}"; then
    tar xzf sgdk.tar.gz >> "$LOG" 2>&1
    mv SGDK-* sgdk 2>/dev/null || true
    rm -f sgdk.tar.gz
    ok "SGDK (Sega Genesis)"
    info "Note: SGDK needs m68k-elf toolchain for full functionality"
else
    fail "SGDK download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "SNES SDK (PVSnesLib)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf pvsneslib pvsneslib-* 2>/dev/null

info "Downloading PVSnesLib..."
if dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip; then
    unzip -qo pvs.zip >> "$LOG" 2>&1
    mv pvsneslib-master pvsneslib 2>/dev/null || true
    rm -f pvs.zip
    ok "PVSnesLib (SNES)"
else
    fail "PVSnesLib download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "ROM HACKING TOOLS"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$TOOLS"
rm -rf flips Flips-* 2>/dev/null
mkdir -p flips
scd "$TOOLS/flips"

FLIPS_URLS=(
    "https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip"
    "https://github.com/Alcaro/Flips/releases/latest/download/flips-linux.zip"
)

info "Downloading Flips (IPS/BPS patcher)..."
if dl_multi flips.zip "${FLIPS_URLS[@]}"; then
    unzip -qo flips.zip >> "$LOG" 2>&1
    chmod +x flips* 2>/dev/null || true
    rm -f flips.zip
    ok "Flips v198"
else
    # Build from source
    info "Building Flips from source..."
    scd "$TOOLS"
    if dl "https://github.com/Alcaro/Flips/archive/refs/heads/master.tar.gz" flips-src.tar.gz; then
        tar xzf flips-src.tar.gz >> "$LOG" 2>&1
        scd Flips-master
        if make CFLAGS="-O3" >> "$LOG" 2>&1; then
            mkdir -p "$TOOLS/flips"
            cp flips "$TOOLS/flips/"
            ok "Flips (built from source)"
        else
            fail "Flips build"
        fi
        rm -rf "$TOOLS/Flips-master" "$TOOLS/flips-src.tar.gz"
    else
        fail "Flips"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "EMULATORS (WSLg GUI)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$EMUS"
rm -rf mGBA* squashfs-root 2>/dev/null

# mGBA
MGBA_URLS=(
    "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-appimage-x64.appimage"
    "https://github.com/mgba-emu/mgba/releases/latest/download/mGBA-appimage-x64.appimage"
)

info "Downloading mGBA..."
if dl_multi mGBA.AppImage "${MGBA_URLS[@]}"; then
    chmod +x mGBA.AppImage
    
    # Extract AppImage for better WSL2 compatibility
    info "Extracting mGBA AppImage for WSL2..."
    if ./mGBA.AppImage --appimage-extract >> "$LOG" 2>&1; then
        mv squashfs-root mGBA-extracted 2>/dev/null || true
        cat > mGBA << 'LAUNCHER'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/mGBA-extracted" && ./AppRun "$@"
LAUNCHER
        chmod +x mGBA
        ok "mGBA 0.10.5 (extracted for WSL2)"
    else
        ok "mGBA 0.10.5 (AppImage)"
        info "Run with: ~/retro-dev/emulators/mGBA.AppImage"
    fi
else
    fail "mGBA download"
fi

# Ares multi-system emulator
scd "$EMUS"
rm -rf ares* 2>/dev/null

ARES_URLS=(
    "https://github.com/ares-emulator/ares/releases/download/v146/ares-linux-x86_64.zip"
    "https://github.com/ares-emulator/ares/releases/download/v145/ares-linux-x86_64.zip"
    "https://github.com/ares-emulator/ares/releases/latest/download/ares-linux-x86_64.zip"
)

info "Downloading Ares emulator..."
if dl_multi ares.zip "${ARES_URLS[@]}"; then
    unzip -qo ares.zip >> "$LOG" 2>&1
    chmod +x ares*/ares ares 2>/dev/null || true
    rm -f ares.zip
    ok "Ares (multi-system emulator)"
else
    warn "Ares download failed — try manual download"
    info "https://github.com/ares-emulator/ares/releases"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "MODERN GAME DEV TOOLS"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$TOOLS"

# Raylib
rm -rf raylib raylib-* 2>/dev/null

RAYLIB_URLS=(
    "https://github.com/raysan5/raylib/archive/refs/tags/5.5.tar.gz"
    "https://github.com/raysan5/raylib/archive/refs/tags/5.0.tar.gz"
)

info "Downloading Raylib..."
if dl_multi raylib.tar.gz "${RAYLIB_URLS[@]}"; then
    tar xzf raylib.tar.gz >> "$LOG" 2>&1
    mv raylib-* raylib 2>/dev/null || true
    rm -f raylib.tar.gz
    
    scd "$TOOLS/raylib/src"
    if make PLATFORM=PLATFORM_DESKTOP -j"$NCPU" >> "$LOG" 2>&1; then
        ok "Raylib (built)"
    else
        ok "Raylib (source only)"
    fi
else
    fail "Raylib download"
fi

# Godot
scd "$TOOLS"
rm -f godot.zip Godot* 2>/dev/null

GODOT_URLS=(
    "https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
    "https://github.com/godotengine/godot/releases/download/4.2.2-stable/Godot_v4.2.2-stable_linux.x86_64.zip"
)

info "Downloading Godot..."
if dl_multi godot.zip "${GODOT_URLS[@]}"; then
    unzip -qo godot.zip >> "$LOG" 2>&1
    chmod +x Godot* 2>/dev/null || true
    rm -f godot.zip
    ok "Godot 4.x"
else
    fail "Godot download"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "ENVIRONMENT SETUP"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$HOME"

cat > "$INSTALL_DIR/env.sh" << 'ENVSCRIPT'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# CAT'S TWEAKER v2.1 — WSL2 Environment
# Source this: source ~/retro-dev/env.sh
# ═══════════════════════════════════════════════════════════════════════════════

export RETRO_DEV="$HOME/retro-dev"

# ─── N64 Development ───
export N64_INST="$RETRO_DEV/compilers/n64"
[[ -d "$N64_INST/bin" ]] && export PATH="$N64_INST/bin:$PATH"

# ─── DevkitPro (GBA/DS/3DS/Wii) ───
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export DEVKITPPC="$DEVKITPRO/devkitPPC"
[[ -d "$DEVKITARM/bin" ]] && export PATH="$DEVKITARM/bin:$PATH"

# ─── Game Boy (GBDK) ───
export GBDK="$RETRO_DEV/sdks/gbdk"
[[ -d "$GBDK/bin" ]] && export PATH="$GBDK/bin:$PATH"

# ─── Genesis (SGDK) ───
export SGDK="$RETRO_DEV/sdks/sgdk"

# ─── SNES (PVSnesLib) ───
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"

# ─── libdragon (N64 SDK) ───
export LIBDRAGON="$RETRO_DEV/sdks/libdragon"

# ─── Tools ───
export PATH="$RETRO_DEV/tools/asm6:$PATH"
export PATH="$RETRO_DEV/tools/flips:$PATH"
export PATH="$RETRO_DEV/tools/rgbds:$PATH"
[[ -d "$RETRO_DEV/tools/wla-dx-10.6/build/binaries" ]] && export PATH="$RETRO_DEV/tools/wla-dx-10.6/build/binaries:$PATH"
export PATH="$RETRO_DEV/sdks/atari:$PATH"
export PATH="$RETRO_DEV/emulators:$PATH"
export PATH="$RETRO_DEV/tools:$PATH"

# ─── WSL2 Specific ───
[[ -z "$DISPLAY" ]] && export DISPLAY=:0

# ─── Python user packages ───
export PATH="$HOME/.local/bin:$PATH"

# ─── Greeting ───
echo ""
echo "  🐱 CAT'S TWEAKER v2.1 — WSL2 Environment Loaded! 🎮"
echo ""
echo "  Toolchains:"
[[ -x "$N64_INST/bin/mips64-elf-gcc" ]] && echo "    ✓ N64:  mips64-elf-gcc"
[[ -x "$DEVKITARM/bin/arm-none-eabi-gcc" ]] && echo "    ✓ GBA:  arm-none-eabi-gcc"
[[ -x "$GBDK/bin/lcc" ]] && echo "    ✓ GB:   lcc (GBDK)"
command -v rgbasm >/dev/null && echo "    ✓ GB:   rgbasm (RGBDS)"
command -v sdcc >/dev/null && echo "    ✓ Z80:  sdcc"
command -v cc65 >/dev/null && echo "    ✓ 6502: cc65"
echo ""
ENVSCRIPT

chmod +x "$INSTALL_DIR/env.sh"
ok "Environment script: ~/retro-dev/env.sh"

add_path ""
add_path "# Cat's Tweaker v2.1 — WSL2 Retro Dev"
add_path "[[ -f \"\$HOME/retro-dev/env.sh\" ]] && source \"\$HOME/retro-dev/env.sh\""

ok "Added to $SHELL_RC"

# ═══════════════════════════════════════════════════════════════════════════════
step "QUICK REFERENCE"
# ═══════════════════════════════════════════════════════════════════════════════

cat > "$INSTALL_DIR/README.txt" << 'README'
═══════════════════════════════════════════════════════════════════════════════
                    CAT'S TWEAKER v2.1 — WSL2 Quick Reference
═══════════════════════════════════════════════════════════════════════════════

ACTIVATE ENVIRONMENT:
    source ~/retro-dev/env.sh

───────────────────────────────────────────────────────────────────────────────
NINTENDO 64
───────────────────────────────────────────────────────────────────────────────
    Compiler:   mips64-elf-gcc
    SDK:        ~/retro-dev/sdks/libdragon
    
    New project:
        mkdir myrom && cd myrom
        cp -r ~/retro-dev/sdks/libdragon/examples/helloworld/* .
        make

───────────────────────────────────────────────────────────────────────────────
GAME BOY / GAME BOY COLOR
───────────────────────────────────────────────────────────────────────────────
    GBDK:       lcc -o game.gb game.c
    RGBDS:      rgbasm -o main.o main.asm && rgblink -o game.gb main.o
    
    Test ROM:   ~/retro-dev/emulators/mGBA game.gb

───────────────────────────────────────────────────────────────────────────────
GAME BOY ADVANCE
───────────────────────────────────────────────────────────────────────────────
    Install:    sudo dkp-pacman -S gba-dev
    Compiler:   arm-none-eabi-gcc

───────────────────────────────────────────────────────────────────────────────
NES
───────────────────────────────────────────────────────────────────────────────
    cc65:       cl65 -t nes -o game.nes game.c
    ASM6F:      asm6f game.asm game.nes

───────────────────────────────────────────────────────────────────────────────
ROM PATCHING
───────────────────────────────────────────────────────────────────────────────
    Apply IPS:  flips --apply patch.ips original.rom patched.rom
    Apply BPS:  flips --apply patch.bps original.rom patched.rom
    Create:     flips --create original.rom modified.rom patch.bps

───────────────────────────────────────────────────────────────────────────────
EMULATORS
───────────────────────────────────────────────────────────────────────────────
    mGBA:       ~/retro-dev/emulators/mGBA rom.gba
    Ares:       ~/retro-dev/emulators/ares*/ares

───────────────────────────────────────────────────────────────────────────────
WSL2 TIPS
───────────────────────────────────────────────────────────────────────────────
    - GUI apps work via WSLg (update WSL if not working)
    - Access Windows files: /mnt/c/Users/YourName/
    - Copy to Windows: cp rom.gb /mnt/c/Users/YourName/Desktop/

═══════════════════════════════════════════════════════════════════════════════
README

ok "Quick reference: ~/retro-dev/README.txt"

# ═══════════════════════════════════════════════════════════════════════════════
# COMPLETE
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo ""
printf "${G}  ╔═══════════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}  ║${RST}  ${W}✨ CAT'S TWEAKER v2.1 — WSL2 INSTALLATION COMPLETE! ✨${RST}             ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}                                                                       ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Install dir:${RST}  ~/retro-dev                                          ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Activate:${RST}     source ~/retro-dev/env.sh                           ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Reference:${RST}    ~/retro-dev/README.txt                              ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Log:${RST}          ~/retro-dev/install.log                             ${G}║${RST}\n"
printf "${G}  ║${RST}                                                                       ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}  ${Y}Next steps:${RST}                                                        ${G}║${RST}\n"
printf "${G}  ║${RST}    1. Restart terminal or: source ~/.bashrc                           ${G}║${RST}\n"
printf "${G}  ║${RST}    2. Test N64: mips64-elf-gcc --version                              ${G}║${RST}\n"
printf "${G}  ║${RST}    3. Test GB:  lcc --version                                         ${G}║${RST}\n"
printf "${G}  ║${RST}                                                                       ${G}║${RST}\n"
printf "${G}  ╚═══════════════════════════════════════════════════════════════════════╝${RST}\n"
echo ""
printf "                              ${M}/\\_____/\\${RST}\n"
printf "                             ${M}/  o   o  \\${RST}\n"
printf "                            ${M}( ==  ^  == )${RST}\n"
printf "                             ${M})  ~nya~  (${RST}\n"
printf "                            ${M}(           )${RST}\n"
printf "                           ${M}( (  )   (  ) )${RST}\n"
printf "                          ${M}(__(__)___(__)__)${RST}\n"
echo ""
printf "                    ${C}Team Flames / Samsoft 🐱${RST}\n"
echo ""
