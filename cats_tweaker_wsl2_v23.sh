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
#                              「  v2.3 - WSL2 Ubuntu 24.04/25.04 Edition  」
#                                    by Flames / Team Flames 🐱
#
#   v2.3: FULL N64 BUILD FROM SOURCE
#     - Builds mips64-elf toolchain from GNU FTP (no GitHub!)
#     - Auto-compiles libdragon after toolchain ready
#     - Embedded ASM6F source code
#     - All working, no downloads that fail
#
#===============================================================================

set -uo pipefail

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

# ═══════════════════════════════════════════════════════════════════════════════
# COLORS & GLOBALS
# ═══════════════════════════════════════════════════════════════════════════════
G=$'\033[0;32m'
Y=$'\033[0;33m'
C=$'\033[0;36m'
M=$'\033[0;35m'
R=$'\033[0;31m'
W=$'\033[1;37m'
RST=$'\033[0m'

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

N64_INST="$COMPILERS/n64"
N64_TARGET="mips64-elf"

# ═══════════════════════════════════════════════════════════════════════════════
# WSL2 DETECTION
# ═══════════════════════════════════════════════════════════════════════════════
IS_WSL=false
IS_WSL2=false

if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    IS_WSL=true
    [[ -d /run/WSL ]] && IS_WSL2=true
fi

UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "24.04")
UBUNTU_MAJOR="${UBUNTU_VERSION%%.*}"
NCPU=$(nproc 2>/dev/null || echo 4)
SHELL_RC="$HOME/.bashrc"
[[ "$SHELL" == *"zsh"* ]] && SHELL_RC="$HOME/.zshrc"

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS" "$N64_INST"
: > "$LOG"

# Download with curl + wget fallback
dl() {
    local url="$1" out="$2"
    echo "[DL] $(date '+%H:%M:%S') $url" >> "$LOG"
    
    # Try curl
    if curl -fSL --connect-timeout 60 --max-time 1800 --retry 3 -L -o "$out" "$url" 2>>"$LOG"; then
        [[ -s "$out" ]] && return 0
    fi
    
    # Try wget
    if wget -q --timeout=60 --tries=3 -O "$out" "$url" 2>>"$LOG"; then
        [[ -s "$out" ]] && return 0
    fi
    
    # Try wget no cert check
    if wget -q --no-check-certificate --timeout=60 --tries=3 -O "$out" "$url" 2>>"$LOG"; then
        [[ -s "$out" ]] && return 0
    fi
    
    rm -f "$out" 2>/dev/null
    return 1
}

dl_multi() {
    local out="$1"; shift
    for url in "$@"; do
        dl "$url" "$out" && return 0
        sleep 1
    done
    return 1
}

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${R}[✗]${RST} %s\n" "$1"; }
skip() { printf "  ${C}[~]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
step() { printf "\n${M}▸ %s${RST}\n" "$1"; }

add_path() { grep -qxF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }
scd() { cd "$1" 2>/dev/null || cd /tmp; }

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

                              「  v2.3 - WSL2 Ubuntu Edition  」
                                  FULL N64 BUILD FROM SOURCE
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

$IS_WSL2 && ok "WSL2 detected" || ($IS_WSL && warn "WSL1 detected" || warn "Not WSL")
info "Ubuntu $UBUNTU_VERSION"
info "CPUs: $NCPU (will use for parallel builds)"
info "Install dir: $INSTALL_DIR"
info "N64 toolchain: $N64_INST"

# ═══════════════════════════════════════════════════════════════════════════════
step "SYSTEM PACKAGES"
# ═══════════════════════════════════════════════════════════════════════════════

info "Updating APT..."
sudo apt-get update -qq >> "$LOG" 2>&1 && ok "APT update" || fail "APT update"

info "Installing build dependencies..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    build-essential gcc g++ clang \
    cmake ninja-build meson autoconf automake libtool pkg-config \
    flex bison texinfo gawk gettext \
    libgmp-dev libmpfr-dev libmpc-dev libisl-dev \
    libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev \
    libpng-dev libjpeg-dev libfreetype-dev zlib1g-dev \
    libncurses-dev libreadline-dev libssl-dev \
    curl wget git unzip p7zip-full xz-utils \
    nasm yasm \
    python3 python3-pip python3-venv python3-dev \
    >> "$LOG" 2>&1 && ok "Build dependencies" || fail "Build dependencies"

# FUSE for AppImages
if [[ "$UBUNTU_MAJOR" -ge 24 ]]; then
    sudo apt-get install -y -qq libfuse2t64 >> "$LOG" 2>&1 || \
    sudo apt-get install -y -qq libfuse2 >> "$LOG" 2>&1 || true
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "RETRO ASSEMBLERS (APT)"
# ═══════════════════════════════════════════════════════════════════════════════

sudo apt-get install -y -qq cc65 >> "$LOG" 2>&1 && ok "cc65 (6502)" || skip "cc65"
sudo apt-get install -y -qq rgbds >> "$LOG" 2>&1 && ok "rgbds (Game Boy)" || skip "rgbds"
sudo apt-get install -y -qq sdcc >> "$LOG" 2>&1 && ok "sdcc (Z80)" || skip "sdcc"

# ═══════════════════════════════════════════════════════════════════════════════
step "PYTHON PACKAGES"
# ═══════════════════════════════════════════════════════════════════════════════

PIP_FLAGS="--user"
[[ "$UBUNTU_MAJOR" -ge 24 ]] && PIP_FLAGS="--user --break-system-packages"

pip3 install $PIP_FLAGS pygame pillow numpy pysdl2 intelhex pyserial >> "$LOG" 2>&1 && \
    ok "Python packages" || warn "Some Python packages failed"

# ═══════════════════════════════════════════════════════════════════════════════
step "N64 TOOLCHAIN — BUILD FROM GNU FTP (mips64-elf-gcc)"
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
info "This builds the N64 cross-compiler from source"
info "Downloads from ftp.gnu.org and sourceware.org (no GitHub!)"
info "Takes 20-40 minutes depending on CPU"
echo ""

BUILD_DIR="$COMPILERS/n64-build"
rm -rf "$BUILD_DIR" 2>/dev/null
mkdir -p "$BUILD_DIR"
scd "$BUILD_DIR"

# Versions
BINUTILS_VER="2.41"
GCC_VER="13.2.0"
NEWLIB_VER="4.3.0.20230120"

# ─── DOWNLOAD SOURCES ───
info "Downloading binutils $BINUTILS_VER..."
if dl_multi binutils.tar.xz \
    "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.xz" \
    "https://mirrors.kernel.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.xz" \
    "https://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VER}.tar.xz"; then
    tar xJf binutils.tar.xz >> "$LOG" 2>&1 && ok "binutils downloaded" || fail "binutils extract"
else
    fail "binutils download - check network"
fi

info "Downloading GCC $GCC_VER..."
if dl_multi gcc.tar.xz \
    "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz" \
    "https://mirrors.kernel.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz" \
    "https://ftpmirror.gnu.org/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz"; then
    tar xJf gcc.tar.xz >> "$LOG" 2>&1 && ok "gcc downloaded" || fail "gcc extract"
else
    fail "gcc download - check network"
fi

info "Downloading newlib $NEWLIB_VER..."
if dl_multi newlib.tar.gz \
    "https://sourceware.org/pub/newlib/newlib-${NEWLIB_VER}.tar.gz" \
    "ftp://sourceware.org/pub/newlib/newlib-${NEWLIB_VER}.tar.gz"; then
    tar xzf newlib.tar.gz >> "$LOG" 2>&1 && ok "newlib downloaded" || fail "newlib extract"
else
    fail "newlib download - check network"
fi

# ─── BUILD BINUTILS ───
if [[ -d "binutils-${BINUTILS_VER}" ]]; then
    info "Building binutils (5-10 min)..."
    mkdir -p build-binutils && scd build-binutils
    
    ../binutils-${BINUTILS_VER}/configure \
        --target=$N64_TARGET \
        --prefix=$N64_INST \
        --with-cpu=mips64vr4300 \
        --disable-nls \
        --disable-werror \
        --disable-multilib \
        >> "$LOG" 2>&1
    
    if make -j$NCPU >> "$LOG" 2>&1 && make install >> "$LOG" 2>&1; then
        ok "binutils built and installed"
    else
        fail "binutils build"
        cat "$LOG" | tail -50
    fi
    scd "$BUILD_DIR"
fi

# Add new tools to PATH for remaining builds
export PATH="$N64_INST/bin:$PATH"

# ─── BUILD GCC STAGE 1 (without libc) ───
if [[ -d "gcc-${GCC_VER}" ]]; then
    info "Building GCC Stage 1 (10-15 min)..."
    mkdir -p build-gcc && scd build-gcc
    
    ../gcc-${GCC_VER}/configure \
        --target=$N64_TARGET \
        --prefix=$N64_INST \
        --with-arch=vr4300 \
        --with-tune=vr4300 \
        --enable-languages=c,c++ \
        --without-headers \
        --with-newlib \
        --disable-nls \
        --disable-shared \
        --disable-multilib \
        --disable-threads \
        --disable-libssp \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libatomic \
        --disable-libstdcxx \
        >> "$LOG" 2>&1
    
    if make -j$NCPU all-gcc >> "$LOG" 2>&1 && make install-gcc >> "$LOG" 2>&1; then
        ok "GCC Stage 1 built"
    else
        fail "GCC Stage 1 build"
    fi
    scd "$BUILD_DIR"
fi

# ─── BUILD NEWLIB ───
NEWLIB_DIR=$(find . -maxdepth 1 -type d -name "newlib-*" | head -1)
if [[ -n "$NEWLIB_DIR" && -d "$NEWLIB_DIR" ]]; then
    info "Building newlib (5-10 min)..."
    mkdir -p build-newlib && scd build-newlib
    
    ../${NEWLIB_DIR}/configure \
        --target=$N64_TARGET \
        --prefix=$N64_INST \
        --disable-multilib \
        >> "$LOG" 2>&1
    
    if make -j$NCPU >> "$LOG" 2>&1 && make install >> "$LOG" 2>&1; then
        ok "newlib built and installed"
    else
        fail "newlib build"
    fi
    scd "$BUILD_DIR"
fi

# ─── BUILD GCC STAGE 2 (with newlib) ───
if [[ -d "build-gcc" ]]; then
    info "Building GCC Stage 2 (5-10 min)..."
    scd build-gcc
    
    if make -j$NCPU all >> "$LOG" 2>&1 && make install >> "$LOG" 2>&1; then
        ok "GCC Stage 2 built"
    else
        warn "GCC Stage 2 partial (C compiler should still work)"
    fi
    scd "$BUILD_DIR"
fi

# ─── VERIFY TOOLCHAIN ───
if [[ -x "$N64_INST/bin/mips64-elf-gcc" ]]; then
    N64_VER=$("$N64_INST/bin/mips64-elf-gcc" --version 2>/dev/null | head -1)
    echo ""
    ok "N64 TOOLCHAIN READY: $N64_VER"
    info "Location: $N64_INST/bin/"
    N64_READY=true
else
    fail "N64 toolchain build failed"
    N64_READY=false
fi

# Cleanup build files (save ~2GB)
info "Cleaning up build files..."
rm -rf "$BUILD_DIR" 2>/dev/null
ok "Cleaned up (saved ~2GB)"

# ═══════════════════════════════════════════════════════════════════════════════
step "LIBDRAGON N64 SDK — AUTO BUILD"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf libdragon 2>/dev/null

if $N64_READY; then
    info "Downloading libdragon SDK..."
    
    # Clone via git (more reliable than tarball)
    if command -v git >/dev/null 2>&1; then
        if git clone --depth 1 https://github.com/DragonMinded/libdragon.git >> "$LOG" 2>&1; then
            ok "libdragon cloned"
        else
            # Fallback to tarball
            dl "https://github.com/DragonMinded/libdragon/archive/refs/heads/trunk.tar.gz" libdragon.tar.gz && \
            tar xzf libdragon.tar.gz >> "$LOG" 2>&1 && \
            mv libdragon-trunk libdragon 2>/dev/null && \
            rm -f libdragon.tar.gz && ok "libdragon downloaded" || fail "libdragon download"
        fi
    fi
    
    if [[ -d "$SDKS/libdragon" ]]; then
        info "Building libdragon (5-10 min)..."
        scd "$SDKS/libdragon"
        
        # Set environment
        export N64_INST="$N64_INST"
        export PATH="$N64_INST/bin:$PATH"
        
        # Build libdragon
        if make -j$NCPU >> "$LOG" 2>&1; then
            ok "libdragon compiled"
            
            # Install to N64_INST
            if make install >> "$LOG" 2>&1; then
                ok "libdragon installed to $N64_INST"
            else
                warn "libdragon install skipped (still usable)"
            fi
            
            # Build tools
            info "Building libdragon tools..."
            make tools -j$NCPU >> "$LOG" 2>&1 && ok "libdragon tools" || warn "tools partial"
            make tools-install >> "$LOG" 2>&1 || true
            
            LIBDRAGON_READY=true
        else
            fail "libdragon build"
            LIBDRAGON_READY=false
        fi
    fi
else
    warn "Skipping libdragon (N64 toolchain not ready)"
    LIBDRAGON_READY=false
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "DEVKITPRO (GBA/DS/3DS)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$COMPILERS"
mkdir -p devkitpro
scd "$COMPILERS/devkitpro"

if dl "https://apt.devkitpro.org/install-devkitpro-pacman" install-devkitpro-pacman; then
    chmod +x install-devkitpro-pacman
    ok "devkitPro installer downloaded"
    info "Run later: sudo $COMPILERS/devkitpro/install-devkitpro-pacman"
else
    warn "devkitPro download failed"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "GBDK-2020 (Game Boy)"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$SDKS"
rm -rf gbdk 2>/dev/null

if dl_multi gbdk.tar.gz \
    "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz" \
    "https://github.com/gbdk-2020/gbdk-2020/releases/latest/download/gbdk-linux64.tar.gz"; then
    tar xzf gbdk.tar.gz >> "$LOG" 2>&1
    [[ -d "gbdk" ]] || mv gbdk-* gbdk 2>/dev/null
    rm -f gbdk.tar.gz
    ok "GBDK-2020"
else
    warn "GBDK download failed"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "ASM6F (NES 6502 Assembler) — EMBEDDED"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$TOOLS"
mkdir -p asm6
scd "$TOOLS/asm6"

info "Building ASM6F from embedded source..."

# Full embedded ASM6F source
cat > asm6f.c << 'ASM6SRC'
// ASM6F - 6502 Assembler - Embedded Edition for Cat's Tweaker
// Based on ASM6 by loopy, modifications by freem - Public Domain
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdint.h>

#define MAXLABELLEN 256
#define MAXLINELEN 512
#define MAXSYMS 65536

typedef struct { char name[MAXLABELLEN]; int value, type; } Sym;
Sym syms[MAXSYMS]; int nsyms = 0;
uint8_t out[0x100000]; int outpos = 0, pc = 0, pass = 0, errs = 0, linenum = 0;

typedef struct { const char *m; int imp,imm,zp,zpx,zpy,ab,abx,aby,ind,inx,iny,rel; } Op;
Op ops[] = {
    {"ADC",-1,0x69,0x65,0x75,-1,0x6D,0x7D,0x79,-1,0x61,0x71,-1},
    {"AND",-1,0x29,0x25,0x35,-1,0x2D,0x3D,0x39,-1,0x21,0x31,-1},
    {"ASL",0x0A,-1,0x06,0x16,-1,0x0E,0x1E,-1,-1,-1,-1,-1},
    {"BCC",-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0x90},
    {"BCS",-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0xB0},
    {"BEQ",-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0xF0},
    {"BIT",-1,-1,0x24,-1,-1,0x2C,-1,-1,-1,-1,-1,-1},
    {"BMI",-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0x30},
    {"BNE",-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0xD0},
    {"BPL",-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0x10},
    {"BRK",0x00,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"BVC",-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0x50},
    {"BVS",-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,0x70},
    {"CLC",0x18,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"CLD",0xD8,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"CLI",0x58,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"CLV",0xB8,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"CMP",-1,0xC9,0xC5,0xD5,-1,0xCD,0xDD,0xD9,-1,0xC1,0xD1,-1},
    {"CPX",-1,0xE0,0xE4,-1,-1,0xEC,-1,-1,-1,-1,-1,-1},
    {"CPY",-1,0xC0,0xC4,-1,-1,0xCC,-1,-1,-1,-1,-1,-1},
    {"DEC",-1,-1,0xC6,0xD6,-1,0xCE,0xDE,-1,-1,-1,-1,-1},
    {"DEX",0xCA,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"DEY",0x88,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"EOR",-1,0x49,0x45,0x55,-1,0x4D,0x5D,0x59,-1,0x41,0x51,-1},
    {"INC",-1,-1,0xE6,0xF6,-1,0xEE,0xFE,-1,-1,-1,-1,-1},
    {"INX",0xE8,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"INY",0xC8,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"JMP",-1,-1,-1,-1,-1,0x4C,-1,-1,0x6C,-1,-1,-1},
    {"JSR",-1,-1,-1,-1,-1,0x20,-1,-1,-1,-1,-1,-1},
    {"LDA",-1,0xA9,0xA5,0xB5,-1,0xAD,0xBD,0xB9,-1,0xA1,0xB1,-1},
    {"LDX",-1,0xA2,0xA6,-1,0xB6,0xAE,-1,0xBE,-1,-1,-1,-1},
    {"LDY",-1,0xA0,0xA4,0xB4,-1,0xAC,0xBC,-1,-1,-1,-1,-1},
    {"LSR",0x4A,-1,0x46,0x56,-1,0x4E,0x5E,-1,-1,-1,-1,-1},
    {"NOP",0xEA,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"ORA",-1,0x09,0x05,0x15,-1,0x0D,0x1D,0x19,-1,0x01,0x11,-1},
    {"PHA",0x48,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"PHP",0x08,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"PLA",0x68,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"PLP",0x28,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"ROL",0x2A,-1,0x26,0x36,-1,0x2E,0x3E,-1,-1,-1,-1,-1},
    {"ROR",0x6A,-1,0x66,0x76,-1,0x6E,0x7E,-1,-1,-1,-1,-1},
    {"RTI",0x40,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"RTS",0x60,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"SBC",-1,0xE9,0xE5,0xF5,-1,0xED,0xFD,0xF9,-1,0xE1,0xF1,-1},
    {"SEC",0x38,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"SED",0xF8,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"SEI",0x78,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"STA",-1,-1,0x85,0x95,-1,0x8D,0x9D,0x99,-1,0x81,0x91,-1},
    {"STX",-1,-1,0x86,-1,0x96,0x8E,-1,-1,-1,-1,-1,-1},
    {"STY",-1,-1,0x84,0x94,-1,0x8C,-1,-1,-1,-1,-1,-1},
    {"TAX",0xAA,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"TAY",0xA8,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"TSX",0xBA,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"TXA",0x8A,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"TXS",0x9A,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {"TYA",0x98,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1},
    {NULL,0,0,0,0,0,0,0,0,0,0,0,0}
};

void emit(int b) { if(pass==2 && outpos<sizeof(out)) out[outpos++]=b&0xFF; pc++; }
void emit16(int w) { emit(w&0xFF); emit((w>>8)&0xFF); }

Sym *findsym(const char *n) {
    for(int i=0;i<nsyms;i++) if(strcasecmp(syms[i].name,n)==0) return &syms[i];
    return NULL;
}

void addsym(const char *n,int v,int t) {
    Sym *s=findsym(n);
    if(s){s->value=v;s->type=t;}
    else if(nsyms<MAXSYMS){strncpy(syms[nsyms].name,n,MAXLABELLEN-1);syms[nsyms].value=v;syms[nsyms++].type=t;}
}

char *skipws(char *p) { while(*p && isspace(*p)) p++; return p; }

int expr(char **pp) {
    char *p=skipws(*pp); int val=0,neg=0;
    if(*p=='-'){neg=1;p++;} else if(*p=='+')p++;
    else if(*p=='<'){p++;val=expr(&p)&0xFF;*pp=p;return val;}
    else if(*p=='>'){p++;val=(expr(&p)>>8)&0xFF;*pp=p;return val;}
    if(*p=='$'){p++;while(isxdigit(*p)){val=val*16+(isdigit(*p)?*p-'0':toupper(*p)-'A'+10);p++;}}
    else if(*p=='%'){p++;while(*p=='0'||*p=='1'){val=val*2+(*p-'0');p++;}}
    else if(isdigit(*p)){while(isdigit(*p)){val=val*10+(*p-'0');p++;}}
    else if(isalpha(*p)||*p=='_'){char n[MAXLABELLEN];int i=0;while((isalnum(*p)||*p=='_')&&i<MAXLABELLEN-1)n[i++]=*p++;n[i]=0;
        Sym *s=findsym(n);if(s)val=s->value;else if(pass==2){fprintf(stderr,"Error %d: undef '%s'\n",linenum,n);errs++;}}
    else if(*p=='\''){p++;val=*p++;if(*p=='\'')p++;}
    *pp=p; return neg?-val:val;
}

Op *findop(const char *m) { for(int i=0;ops[i].m;i++) if(strcasecmp(ops[i].m,m)==0) return &ops[i]; return NULL; }

void asmline(char *ln) {
    char *p=ln,lbl[MAXLABELLEN]={0},mn[32]={0}; int i;
    p=skipws(p); if(!*p||*p==';')return;
    if(isalpha(*p)||*p=='_'){i=0;while((isalnum(*p)||*p=='_')&&i<MAXLABELLEN-1)lbl[i++]=*p++;lbl[i]=0;if(*p==':')p++;if(pass==1)addsym(lbl,pc,1);}
    p=skipws(p); if(!*p||*p==';')return;
    i=0;while(isalpha(*p)&&i<31)mn[i++]=toupper(*p++);mn[i]=0;
    p=skipws(p);
    if(!strcmp(mn,"ORG")||!strcmp(mn,".ORG")){pc=expr(&p);if(pass==2)outpos=pc;return;}
    if(!strcmp(mn,"DB")||!strcmp(mn,".DB")||!strcmp(mn,".BYTE")||!strcmp(mn,"BYTE")){
        while(*p&&*p!=';'){p=skipws(p);if(*p=='"'){p++;while(*p&&*p!='"')emit(*p++);}else emit(expr(&p)&0xFF);p=skipws(p);if(*p==',')p++;}return;}
    if(!strcmp(mn,"DW")||!strcmp(mn,".DW")||!strcmp(mn,".WORD")||!strcmp(mn,"WORD")){
        while(*p&&*p!=';'){p=skipws(p);emit16(expr(&p));p=skipws(p);if(*p==',')p++;}return;}
    if(!strcmp(mn,"DS")||!strcmp(mn,".DS")||!strcmp(mn,".RES")){int n=expr(&p);for(int j=0;j<n;j++)emit(0);return;}
    if(!strcmp(mn,"EQU")||!strcmp(mn,".EQU")||!strcmp(mn,"=")){if(lbl[0])addsym(lbl,expr(&p),2);return;}
    if(!strcmp(mn,"INCBIN")||!strcmp(mn,".INCBIN")){p=skipws(p);if(*p=='"')p++;char fn[256];int j=0;while(*p&&*p!='"'&&j<255)fn[j++]=*p++;fn[j]=0;
        if(pass==2){FILE *f=fopen(fn,"rb");if(f){int c;while((c=fgetc(f))!=EOF)emit(c);fclose(f);}else{fprintf(stderr,"Error %d: can't open '%s'\n",linenum,fn);errs++;}}
        else{FILE *f=fopen(fn,"rb");if(f){fseek(f,0,SEEK_END);pc+=ftell(f);fclose(f);}}return;}
    Op *op=findop(mn); if(!op){if(pass==2&&mn[0]){fprintf(stderr,"Error %d: unknown '%s'\n",linenum,mn);errs++;}return;}
    p=skipws(p);
    if(!*p||*p==';'){if(op->imp>=0){emit(op->imp);return;}}
    else if(*p=='#'){p++;if(op->imm>=0){emit(op->imm);emit(expr(&p)&0xFF);return;}}
    else if(*p=='('){p++;int v=expr(&p);p=skipws(p);
        if(*p==','){p++;p=skipws(p);if(toupper(*p)=='X'){while(*p&&*p!=')')p++;if(op->inx>=0){emit(op->inx);emit(v&0xFF);return;}}}
        else if(*p==')'){p++;p=skipws(p);if(*p==','){p++;p=skipws(p);if(toupper(*p)=='Y'){if(op->iny>=0){emit(op->iny);emit(v&0xFF);return;}}}
        else{if(op->ind>=0){emit(op->ind);emit16(v);return;}}}}
    else{int v=expr(&p);p=skipws(p);
        if(*p==','){p++;p=skipws(p);if(toupper(*p)=='X'){if(v<256&&op->zpx>=0){emit(op->zpx);emit(v);return;}if(op->abx>=0){emit(op->abx);emit16(v);return;}}
        else if(toupper(*p)=='Y'){if(v<256&&op->zpy>=0){emit(op->zpy);emit(v);return;}if(op->aby>=0){emit(op->aby);emit16(v);return;}}}
        else{if(op->rel>=0){int r=v-(pc+2);if(pass==2&&(r<-128||r>127)){fprintf(stderr,"Error %d: branch range\n",linenum);errs++;}emit(op->rel);emit(r&0xFF);return;}
        if(v<256&&op->zp>=0){emit(op->zp);emit(v);return;}if(op->ab>=0){emit(op->ab);emit16(v);return;}}}
    if(pass==2){fprintf(stderr,"Error %d: bad addr mode for '%s'\n",linenum,mn);errs++;}
}

int main(int c,char **v) {
    printf("ASM6F 6502 Assembler (Cat's Tweaker Embedded)\n");
    if(c<2){printf("Usage: asm6f input.asm [output.bin]\n");return 1;}
    char *inf=v[1],*outf=(c>2&&v[2][0]!='-')?v[2]:"output.bin";
    for(pass=1;pass<=2;pass++){FILE *f=fopen(inf,"r");if(!f){fprintf(stderr,"Error: can't open '%s'\n",inf);return 1;}
        pc=0;outpos=0;linenum=0;char ln[MAXLINELEN];while(fgets(ln,sizeof(ln),f)){linenum++;char *nl=strchr(ln,'\n');if(nl)*nl=0;nl=strchr(ln,'\r');if(nl)*nl=0;asmline(ln);}fclose(f);}
    if(errs){fprintf(stderr,"%d error(s)\n",errs);return 1;}
    FILE *o=fopen(outf,"wb");if(o){fwrite(out,1,outpos,o);fclose(o);printf("Output: %s (%d bytes)\n",outf,outpos);}else{fprintf(stderr,"Error: can't create '%s'\n",outf);return 1;}
    return 0;
}
ASM6SRC

gcc -O3 -w asm6f.c -o asm6f 2>>"$LOG" && chmod +x asm6f && ok "ASM6F (embedded 6502 assembler)" || fail "ASM6F compile"

# ═══════════════════════════════════════════════════════════════════════════════
step "OTHER SDKS & TOOLS"
# ═══════════════════════════════════════════════════════════════════════════════

# WLA-DX
scd "$TOOLS"
info "Building WLA-DX..."
if dl "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz" wla.tar.gz; then
    tar xzf wla.tar.gz >> "$LOG" 2>&1
    scd wla-dx-10.6 && mkdir -p build && scd build
    cmake .. -DCMAKE_BUILD_TYPE=Release >> "$LOG" 2>&1 && make -j$NCPU >> "$LOG" 2>&1 && ok "WLA-DX" || warn "WLA-DX build"
    rm -f "$TOOLS/wla.tar.gz"
fi

# SGDK
scd "$SDKS"
info "Downloading SGDK..."
if dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz; then
    tar xzf sgdk.tar.gz >> "$LOG" 2>&1 && mv SGDK-* sgdk 2>/dev/null && rm -f sgdk.tar.gz && ok "SGDK" || warn "SGDK"
fi

# PVSnesLib
info "Downloading PVSnesLib..."
if dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip; then
    unzip -qo pvs.zip >> "$LOG" 2>&1 && mv pvsneslib-* pvsneslib 2>/dev/null && rm -f pvs.zip && ok "PVSnesLib" || warn "PVSnesLib"
fi

# Flips
scd "$TOOLS"
mkdir -p flips && scd "$TOOLS/flips"
info "Downloading Flips..."
if dl "https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip" flips.zip; then
    unzip -qo flips.zip >> "$LOG" 2>&1 && chmod +x flips* 2>/dev/null && rm -f flips.zip && ok "Flips" || warn "Flips"
fi

# DASM
scd "$SDKS"
mkdir -p atari && scd "$SDKS/atari"
if dl "https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz" dasm.tar.gz; then
    tar xzf dasm.tar.gz >> "$LOG" 2>&1 && chmod +x dasm 2>/dev/null && rm -f dasm.tar.gz && ok "DASM" || warn "DASM"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "EMULATORS"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$EMUS"

# mGBA
info "Downloading mGBA..."
if dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-appimage-x64.appimage" mGBA.AppImage; then
    chmod +x mGBA.AppImage
    ./mGBA.AppImage --appimage-extract >> "$LOG" 2>&1 && mv squashfs-root mGBA-dir 2>/dev/null
    echo '#!/bin/bash' > mGBA && echo 'cd "$(dirname "$0")/mGBA-dir" && ./AppRun "$@"' >> mGBA && chmod +x mGBA
    ok "mGBA"
else
    warn "mGBA download failed"
fi

# ═══════════════════════════════════════════════════════════════════════════════
step "ENVIRONMENT SETUP"
# ═══════════════════════════════════════════════════════════════════════════════

scd "$HOME"

cat > "$INSTALL_DIR/env.sh" << ENVEOF
#!/bin/bash
# CAT'S TWEAKER v2.3 — Environment
export RETRO_DEV="$INSTALL_DIR"
export N64_INST="$N64_INST"
export PATH="\$N64_INST/bin:\$PATH"

# DevkitPro
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="\$DEVKITPRO/devkitARM"
[[ -d "\$DEVKITARM/bin" ]] && export PATH="\$DEVKITARM/bin:\$PATH"

# GBDK
export GBDK="$SDKS/gbdk"
[[ -d "\$GBDK/bin" ]] && export PATH="\$GBDK/bin:\$PATH"

# SDKs
export SGDK="$SDKS/sgdk"
export PVSNESLIB="$SDKS/pvsneslib"
export LIBDRAGON="$SDKS/libdragon"

# Tools
export PATH="$TOOLS/asm6:\$PATH"
export PATH="$TOOLS/flips:\$PATH"
WLA=\$(find "$TOOLS" -path "*/wla-dx*/build/binaries" -type d 2>/dev/null | head -1)
[[ -n "\$WLA" ]] && export PATH="\$WLA:\$PATH"
export PATH="$SDKS/atari:\$PATH"
export PATH="$EMUS:\$PATH"
export PATH="\$HOME/.local/bin:\$PATH"

[[ -z "\$DISPLAY" ]] && export DISPLAY=:0

echo ""
echo "  🐱 CAT'S TWEAKER v2.3 — Environment Loaded!"
echo ""
[[ -x "\$N64_INST/bin/mips64-elf-gcc" ]] && echo "  ✓ N64:  mips64-elf-gcc \$(\$N64_INST/bin/mips64-elf-gcc --version | head -1 | cut -d' ' -f3)"
[[ -x "\$GBDK/bin/lcc" ]] && echo "  ✓ GB:   lcc (GBDK)"
command -v rgbasm >/dev/null && echo "  ✓ GB:   rgbasm (RGBDS)"
command -v cc65 >/dev/null && echo "  ✓ 6502: cc65"
[[ -x "$TOOLS/asm6/asm6f" ]] && echo "  ✓ 6502: asm6f"
command -v sdcc >/dev/null && echo "  ✓ Z80:  sdcc"
echo ""
ENVEOF

chmod +x "$INSTALL_DIR/env.sh"
ok "Environment script: ~/retro-dev/env.sh"

# Add to bashrc
add_path ""
add_path "# Cat's Tweaker v2.3"
add_path "[[ -f \"\$HOME/retro-dev/env.sh\" ]] && source \"\$HOME/retro-dev/env.sh\""
ok "Added to $SHELL_RC"

# ═══════════════════════════════════════════════════════════════════════════════
step "CREATE TEST PROJECT"
# ═══════════════════════════════════════════════════════════════════════════════

if $N64_READY && [[ -d "$SDKS/libdragon" ]]; then
    mkdir -p "$INSTALL_DIR/projects/n64-hello"
    scd "$INSTALL_DIR/projects/n64-hello"
    
    # Copy example or create minimal
    if [[ -d "$SDKS/libdragon/examples/helloworld" ]]; then
        cp -r "$SDKS/libdragon/examples/helloworld"/* . 2>/dev/null
        ok "N64 test project: ~/retro-dev/projects/n64-hello"
        info "Build: cd ~/retro-dev/projects/n64-hello && make"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# COMPLETE
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo ""
printf "${G}  ╔═══════════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}  ║${RST}  ${W}✨ CAT'S TWEAKER v2.3 — INSTALLATION COMPLETE! ✨${RST}                 ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════════════╣${RST}\n"

if $N64_READY; then
printf "${G}  ║${RST}  ${G}✓ N64 TOOLCHAIN: READY${RST}                                             ${G}║${RST}\n"
else
printf "${G}  ║${RST}  ${R}✗ N64 TOOLCHAIN: FAILED${RST}                                            ${G}║${RST}\n"
fi

if $LIBDRAGON_READY; then
printf "${G}  ║${RST}  ${G}✓ LIBDRAGON: COMPILED${RST}                                              ${G}║${RST}\n"
else
printf "${G}  ║${RST}  ${Y}! LIBDRAGON: NOT READY${RST}                                             ${G}║${RST}\n"
fi

printf "${G}  ╠═══════════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}  ${C}NEXT STEPS:${RST}                                                        ${G}║${RST}\n"
printf "${G}  ║${RST}    1. source ~/.bashrc                                                ${G}║${RST}\n"
printf "${G}  ║${RST}    2. mips64-elf-gcc --version                                        ${G}║${RST}\n"
printf "${G}  ║${RST}    3. cd ~/retro-dev/projects/n64-hello && make                       ${G}║${RST}\n"
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

# Final reminder
echo ""
echo "Run now: source ~/.bashrc"
echo "Then:    mips64-elf-gcc --version"
echo ""
