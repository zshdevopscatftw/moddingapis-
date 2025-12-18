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
#                               「  v2.0 - ATARI → PS5 MEGA SDK PACK  」
#                                     by Flames / Team Flames 🐱
#
#===============================================================================
# Covers: Atari 2600/7800/Jaguar, NES/SNES/N64/GC/Wii/WiiU/Switch,
#         Genesis/Saturn/Dreamcast, PS1/PS2/PSP/PSVita/PS3/PS4/PS5,
#         Xbox/Xbox360, 3DO, PC Engine, Neo Geo, and more
#===============================================================================

[[ -z "$BASH_VERSION" ]] && { echo "Run with: bash $0"; exit 1; }

set -e

# Colors
G=$'\033[0;32m'; Y=$'\033[0;33m'; C=$'\033[0;36m'; M=$'\033[0;35m'
W=$'\033[1;37m'; R=$'\033[0;31m'; B=$'\033[0;34m'; RST=$'\033[0m'

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS" \
         "$SDKS/atari" "$SDKS/nintendo" "$SDKS/sega" "$SDKS/sony" "$SDKS/microsoft" "$SDKS/misc"
: > "$LOG"

IS_MAC=false; [[ "$(uname)" == "Darwin" ]] && IS_MAC=true
IS_ARM=false; [[ "$(uname -m)" =~ ^(arm64|aarch64)$ ]] && IS_ARM=true
NCPU=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
SHELL_RC="$HOME/.zshrc"; $IS_MAC || SHELL_RC="$HOME/.bashrc"

dl() {
    local url="$1" out="$2"
    echo "[DL] $url" >> "$LOG"
    curl -fsSL --connect-timeout 30 --max-time 900 --retry 3 -L -o "$out" "$url" 2>>"$LOG"
    [[ -s "$out" ]] && { echo "[DL] OK: $(ls -lh "$out" 2>/dev/null)" >> "$LOG"; return 0; }
    echo "[DL] FAIL" >> "$LOG"; rm -f "$out" 2>/dev/null; return 1
}

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${R}[✗]${RST} %s ${Y}(see log)${RST}\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
step() { printf "\n${M}══════════════════════════════════════════════════════════════${RST}\n"; printf "${W}▸ %s${RST}\n" "$1"; printf "${M}══════════════════════════════════════════════════════════════${RST}\n"; }
era()  { printf "\n${B}╔══════════════════════════════════════════════════════════════╗${RST}\n"; printf "${B}║${RST} ${W}%-60s${RST} ${B}║${RST}\n" "$1"; printf "${B}╚══════════════════════════════════════════════════════════════╝${RST}\n"; }

add_path() { grep -qF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }

clear
cat << 'BANNER'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                              「  v2.0 - ATARI → PS5 MEGA SDK PACK  」

                                         /\_____/\
                                        /  o   o  \
                                       ( ==  ^  == )    "nya~ installing
                                        )  ~~~~  (       ALL the SDKs!"
                                       (           )
                                      ( (  )   (  ) )
                                     (__(__)___(__)__)

BANNER

# ============================================================================
step "SYSTEM PREREQUISITES"
# ============================================================================

if $IS_MAC; then
    command -v brew >/dev/null 2>&1 && ok "Homebrew" || {
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG" 2>&1 && ok "Homebrew" || fail "Homebrew"
    }
    info "Installing base packages..."
    brew install wget curl gcc llvm cmake ninja meson sdl2 sdl2_image sdl2_mixer sdl2_ttf \
                 libpng jpeg freetype zlib python nasm yasm p7zip glew glfw boost \
                 raylib rgbds cc65 sdcc wla-dx pkg-config autoconf automake libtool >> "$LOG" 2>&1 && ok "Brew packages" || warn "Some brew packages failed"
else
    info "Updating package lists..."
    sudo apt-get update -qq >> "$LOG" 2>&1 && ok "APT update" || fail "APT update"
    
    info "Installing build essentials..."
    sudo apt-get install -y -qq \
        wget curl build-essential gcc g++ clang llvm cmake ninja-build meson \
        autoconf automake libtool pkg-config libsdl2-dev libsdl2-image-dev \
        libsdl2-mixer-dev libsdl2-ttf-dev libpng-dev libjpeg-dev libfreetype6-dev \
        zlib1g-dev python3 python3-pip python3-venv nasm yasm flex bison texinfo \
        libncurses-dev libreadline-dev unzip p7zip-full libelf-dev libusb-1.0-0-dev \
        libgmp-dev libmpfr-dev libmpc-dev libisl-dev libexpat1-dev libssl-dev \
        git subversion mercurial >> "$LOG" 2>&1 && ok "Build tools" || fail "Build tools"
fi

# ============================================================================
step "PYTHON PACKAGES"
# ============================================================================

pip3 install --user --break-system-packages \
    pygame ursina pillow numpy pysdl2 pyyaml toml intelhex pyserial capstone \
    cython mako lxml >> "$LOG" 2>&1 && ok "Python packages" || warn "Some Python packages"

# ============================================================================
era "🕹️  ATARI ERA (1977-1993)"
# ============================================================================

cd "$SDKS/atari"

# --- DASM (Atari 2600/7800, 6502) ---
step "DASM Assembler"
DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz"
$IS_MAC && DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz"
dl "$DASM_URL" dasm.tar.gz && tar xzf dasm.tar.gz >> "$LOG" 2>&1 && rm -f dasm.tar.gz && ok "DASM (Atari 2600/7800)" || fail "DASM"
add_path "export PATH=\"$SDKS/atari:\$PATH\""

# --- CC65 (Atari 8-bit, 2600 batari Basic compatible) ---
step "CC65 (6502 C Compiler)"
$IS_MAC && ok "CC65 (via brew)" || {
    mkdir -p "$SDKS/atari/cc65"
    cd "$SDKS/atari/cc65"
    dl "https://github.com/cc65/cc65/archive/refs/tags/V2.19.tar.gz" cc65.tar.gz && \
    tar xzf cc65.tar.gz >> "$LOG" 2>&1 && cd cc65-2.19 && \
    make -j$NCPU >> "$LOG" 2>&1 && make install PREFIX="$SDKS/atari/cc65" >> "$LOG" 2>&1 && \
    ok "CC65" || fail "CC65"
    rm -f "$SDKS/atari/cc65/cc65.tar.gz"
    add_path "export CC65_HOME=\"$SDKS/atari/cc65\"; export PATH=\"\$CC65_HOME/bin:\$PATH\""
}

# --- batari Basic (Atari 2600) ---
step "batari Basic (Atari 2600)"
cd "$SDKS/atari"
mkdir -p bB
cd bB
dl "https://github.com/batari-Basic/batern/archive/refs/heads/master.tar.gz" bB.tar.gz 2>/dev/null && \
tar xzf bB.tar.gz >> "$LOG" 2>&1 && ok "batari Basic" || warn "batari Basic (manual: atariage.com)"
rm -f bB.tar.gz

# --- Atari Jaguar SDK (Removers Library) ---
step "Atari Jaguar SDK"
cd "$SDKS/atari"
mkdir -p jaguar
cd jaguar
info "Jaguar dev requires custom toolchain"
cat > README.txt << 'JAGSDK'
Atari Jaguar Development:
- Removers Library: https://removers.online.fr/jagware/
- SMAC (Madmac fork): smac assembler
- Official Atari docs: AtariAge forums

Build SMAC:
  git clone https://github.com/cubanismo/jag_utils
  cd jag_utils/smac && make
JAGSDK
ok "Jaguar SDK (docs)"

# ============================================================================
era "🎮 NINTENDO ERA (1983-Present)"
# ============================================================================

# --- NES/Famicom (CC65, ASM6F, NESASM) ---
step "NES Development (ASM6F)"
cd "$TOOLS"
mkdir -p asm6
cd asm6
dl "https://raw.githubusercontent.com/freem/asm6f/main/asm6f.c" asm6f.c 2>/dev/null && \
cc -O3 -w asm6f.c -o asm6f 2>/dev/null && chmod +x asm6f && ok "ASM6F" || {
    cat > asm6f.c << 'ASM6STUB'
#include <stdio.h>
int main(int c, char**v) {
    if(c<2){printf("asm6f stub - get full: github.com/freem/asm6f\n");return 1;}
    return 1;
}
ASM6STUB
    cc -O3 -w asm6f.c -o asm6f && ok "ASM6F (stub)"
}
add_path "export PATH=\"$TOOLS/asm6:\$PATH\""

# --- SNES/Super Famicom (PVSnesLib) ---
step "PVSnesLib (SNES)"
cd "$SDKS/nintendo"
rm -rf pvsneslib 2>/dev/null
dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip && \
unzip -qo pvs.zip >> "$LOG" 2>&1 && mv pvsneslib-master pvsneslib && rm -f pvs.zip && \
ok "PVSnesLib" || fail "PVSnesLib"
add_path "export PVSNESLIB=\"$SDKS/nintendo/pvsneslib\""

# --- Game Boy / GBC (GBDK-2020, RGBDS) ---
step "GBDK-2020 (Game Boy)"
cd "$SDKS/nintendo"
GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz"
$IS_MAC && GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-macos.tar.gz"
dl "$GB_URL" gbdk.tar.gz && tar xzf gbdk.tar.gz >> "$LOG" 2>&1 && rm -f gbdk.tar.gz && \
ok "GBDK-2020" || fail "GBDK-2020"
add_path "export GBDK=\"$SDKS/nintendo/gbdk\"; export PATH=\"\$GBDK/bin:\$PATH\""

step "RGBDS (Game Boy ASM)"
$IS_MAC && ok "RGBDS (via brew)" || {
    mkdir -p "$TOOLS/rgbds"
    cd "$TOOLS/rgbds"
    dl "https://github.com/gbdev/rgbds/releases/download/v0.8.0/rgbds-0.8.0-linux-x86_64.tar.xz" rgbds.tar.xz && \
    tar xJf rgbds.tar.xz >> "$LOG" 2>&1 && rm -f rgbds.tar.xz && ok "RGBDS" || fail "RGBDS"
    add_path "export PATH=\"$TOOLS/rgbds:\$PATH\""
}

# --- N64 (libdragon) ---
step "Nintendo 64 SDK (libdragon)"
cd "$SDKS/nintendo"
if $IS_MAC; then
    info "N64 on macOS uses Docker + libdragon CLI"
    command -v docker >/dev/null 2>&1 && ok "Docker found" || warn "Install Docker Desktop"
    command -v npm >/dev/null 2>&1 && {
        npm install -g libdragon >> "$LOG" 2>&1 && ok "libdragon CLI" || warn "libdragon CLI"
    } || warn "Install Node.js: brew install node"
else
    mkdir -p "$COMPILERS/n64"
    cd "$COMPILERS/n64"
    TC_URL="https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz"
    info "Downloading N64 toolchain (~200MB)..."
    dl "$TC_URL" tc.tar.gz && tar xzf tc.tar.gz >> "$LOG" 2>&1 && rm -f tc.tar.gz && \
    ok "N64 toolchain (mips64-elf-gcc)" || fail "N64 toolchain"
    add_path "export N64_INST=\"$COMPILERS/n64\"; export PATH=\"\$N64_INST/bin:\$PATH\""
    
    cd "$SDKS/nintendo"
    dl "https://github.com/DragonMinded/libdragon/archive/refs/heads/trunk.tar.gz" libdragon.tar.gz && \
    tar xzf libdragon.tar.gz >> "$LOG" 2>&1 && mv libdragon-trunk libdragon && rm -f libdragon.tar.gz && \
    ok "libdragon SDK" || fail "libdragon SDK"
fi

# --- DevkitPro (GBA, NDS, 3DS, GC, Wii, WiiU, Switch) ---
step "DevkitPro Suite"
cd "$COMPILERS"
mkdir -p devkitpro
cd devkitpro

if $IS_MAC; then
    DKP_URL="https://github.com/devkitPro/pacman/releases/latest/download/devkitpro-pacman-installer.pkg"
    dl "$DKP_URL" devkitpro.pkg && ok "DevkitPro installer downloaded" || fail "DevkitPro"
    info "Install: sudo installer -pkg $COMPILERS/devkitpro/devkitpro.pkg -target /"
    info "Then: sudo dkp-pacman -S gba-dev nds-dev 3ds-dev gamecube-dev wii-dev wiiu-dev switch-dev"
else
    info "Installing DevkitPro pacman..."
    dl "https://apt.devkitpro.org/install-devkitpro-pacman" dkp-install.sh && \
    chmod +x dkp-install.sh && sudo ./dkp-install.sh >> "$LOG" 2>&1 && ok "DevkitPro pacman" || fail "DevkitPro pacman"
    
    info "Installing GameCube + Wii dev packages..."
    sudo dkp-pacman -Syu --noconfirm >> "$LOG" 2>&1
    sudo dkp-pacman -S --noconfirm --needed \
        gba-dev nds-dev 3ds-dev gamecube-dev wii-dev wiiu-dev switch-dev \
        devkitARM devkitPPC devkitA64 \
        libogc libfat-ogc libctru citro2d citro3d \
        libnx dkp-toolchain-vars >> "$LOG" 2>&1 && \
    ok "DevkitPro packages (GC/Wii/Switch)" || warn "Some DevkitPro packages"
fi
add_path "export DEVKITPRO=\"/opt/devkitpro\""
add_path "export DEVKITARM=\"\$DEVKITPRO/devkitARM\""
add_path "export DEVKITPPC=\"\$DEVKITPRO/devkitPPC\""
add_path "export DEVKITA64=\"\$DEVKITPRO/devkitA64\""
add_path "export PATH=\"\$DEVKITARM/bin:\$DEVKITPPC/bin:\$DEVKITA64/bin:\$PATH\""

# ============================================================================
era "🎯 SEGA ERA (1985-2001)"
# ============================================================================

# --- Master System / Game Gear (SDCC + devkitSMS) ---
step "devkitSMS (Master System / Game Gear)"
cd "$SDKS/sega"
mkdir -p devkitsms
cd devkitsms
dl "https://github.com/sverx/devkitSMS/archive/refs/heads/master.tar.gz" dksms.tar.gz && \
tar xzf dksms.tar.gz >> "$LOG" 2>&1 && mv devkitSMS-master/* . 2>/dev/null && \
rm -rf devkitSMS-master dksms.tar.gz && ok "devkitSMS" || fail "devkitSMS"

# --- Genesis / Mega Drive (SGDK) ---
step "SGDK (Genesis / Mega Drive)"
cd "$SDKS/sega"
rm -rf sgdk 2>/dev/null
dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz && \
tar xzf sgdk.tar.gz >> "$LOG" 2>&1 && mv SGDK-2.00 sgdk && rm -f sgdk.tar.gz && \
ok "SGDK 2.00" || fail "SGDK"
add_path "export SGDK=\"$SDKS/sega/sgdk\"; export GDK=\"\$SGDK\""

# --- Sega Saturn (SaturnOrbit / libyaul) ---
step "Sega Saturn SDK"
cd "$SDKS/sega"
mkdir -p saturn
cd saturn
cat > README.txt << 'SATURNSDK'
Sega Saturn Development:

1. libyaul (Modern SDK):
   https://github.com/yaul-org/libyaul
   Requires SH2 cross-compiler (sh-elf-gcc)

2. Jo Engine (Easier):
   https://github.com/johannes-fetz/joern

3. Saturn Orbit (Classic):
   Various tools at SegaXtreme forums

Build SH2 toolchain:
   # Uses standard GNU toolchain build
   --target=sh-elf --with-cpu=m2
SATURNSDK
ok "Saturn SDK (docs)"

# --- Dreamcast (KallistiOS) ---
step "Dreamcast SDK (KallistiOS)"
cd "$SDKS/sega"
mkdir -p dreamcast
cd dreamcast
dl "https://github.com/KallistiOS/KallistiOS/archive/refs/heads/master.tar.gz" kos.tar.gz && \
tar xzf kos.tar.gz >> "$LOG" 2>&1 && mv KallistiOS-master kos && rm -f kos.tar.gz && \
ok "KallistiOS source" || fail "KallistiOS"
cat > BUILD.txt << 'KOSBUILD'
KallistiOS Build:
1. Install SH4 toolchain: dc-chain (in kos/utils/dc-chain)
2. cd kos/utils/dc-chain && make
3. source kos/environ.sh
4. cd kos && make

Or use Docker:
  docker pull kallistios/kos
KOSBUILD
info "KOS requires SH4 toolchain build - see BUILD.txt"

# ============================================================================
era "🎮 SONY ERA (1994-Present)"
# ============================================================================

# --- PlayStation 1 (PSn00bSDK, PSXSDK) ---
step "PlayStation 1 SDK (PSn00bSDK)"
cd "$SDKS/sony"
mkdir -p ps1
cd ps1
dl "https://github.com/Lameguy64/PSn00bSDK/archive/refs/heads/master.tar.gz" psn00b.tar.gz && \
tar xzf psn00b.tar.gz >> "$LOG" 2>&1 && mv PSn00bSDK-master psn00bsdk && rm -f psn00b.tar.gz && \
ok "PSn00bSDK" || fail "PSn00bSDK"
cat > BUILD.txt << 'PS1BUILD'
PSn00bSDK Build:
1. Requires mipsel-none-elf toolchain
2. cd psn00bsdk && cmake -B build -G Ninja
3. cmake --build build

Alternative: PCSX-Redux has built-in PSn00bSDK support
PS1BUILD
add_path "export PSN00BSDK=\"$SDKS/sony/ps1/psn00bsdk\""

# --- PlayStation 2 (PS2DEV) ---
step "PlayStation 2 SDK (ps2dev)"
cd "$SDKS/sony"
mkdir -p ps2
cd ps2
cat > INSTALL.txt << 'PS2BUILD'
PS2DEV Toolchain:
Official installer (Docker recommended):
  docker pull ps2dev/ps2dev

Manual build:
  export PS2DEV=/usr/local/ps2dev
  export PS2SDK=$PS2DEV/ps2sdk
  export PATH=$PATH:$PS2DEV/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin

  git clone https://github.com/ps2dev/ps2dev
  cd ps2dev && ./build-all.sh
PS2BUILD
ok "PS2DEV (docs)"
add_path "export PS2DEV=\"/usr/local/ps2dev\""
add_path "export PS2SDK=\"\$PS2DEV/ps2sdk\""

# --- PSP (PSPSDK) ---
step "PlayStation Portable SDK"
cd "$SDKS/sony"
mkdir -p psp
cd psp
cat > INSTALL.txt << 'PSPBUILD'
PSPSDK:
  docker pull pspdev/pspdev

Manual:
  export PSPDEV=/usr/local/pspdev
  git clone https://github.com/pspdev/psptoolchain
  cd psptoolchain && ./toolchain.sh
PSPBUILD
ok "PSPSDK (docs)"
add_path "export PSPDEV=\"/usr/local/pspdev\"; export PATH=\"\$PSPDEV/bin:\$PATH\""

# --- PS Vita (VitaSDK) ---
step "PlayStation Vita SDK"
cd "$SDKS/sony"
mkdir -p vita
cd vita
cat > INSTALL.txt << 'VITABUILD'
VitaSDK:
  export VITASDK=/usr/local/vitasdk
  git clone https://github.com/vitasdk/vdpm
  cd vdpm && ./bootstrap-vitasdk.sh
  ./install-all.sh

Docker:
  docker pull vitasdk/vitasdk
VITABUILD
ok "VitaSDK (docs)"
add_path "export VITASDK=\"/usr/local/vitasdk\"; export PATH=\"\$VITASDK/bin:\$PATH\""

# --- PS3 (PSL1GHT) ---
step "PlayStation 3 SDK (PSL1GHT)"
cd "$SDKS/sony"
mkdir -p ps3
cd ps3
cat > INSTALL.txt << 'PS3BUILD'
PSL1GHT (Homebrew PS3 SDK):
  export PS3DEV=/usr/local/ps3dev
  export PSL1GHT=$PS3DEV/psl1ght
  
  git clone https://github.com/ps3dev/ps3toolchain
  cd ps3toolchain && ./toolchain.sh
  
  git clone https://github.com/ps3dev/PSL1GHT
  cd PSL1GHT && make install
PS3BUILD
ok "PSL1GHT (docs)"
add_path "export PS3DEV=\"/usr/local/ps3dev\"; export PSL1GHT=\"\$PS3DEV/psl1ght\""

# --- PS4 (OpenOrbis) ---
step "PlayStation 4 SDK (OpenOrbis)"
cd "$SDKS/sony"
mkdir -p ps4
cd ps4
dl "https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain/releases/download/v0.5.2/linux.tar.gz" oo.tar.gz 2>/dev/null && \
tar xzf oo.tar.gz >> "$LOG" 2>&1 && rm -f oo.tar.gz && ok "OpenOrbis PS4" || {
    cat > INSTALL.txt << 'PS4BUILD'
OpenOrbis PS4 Toolchain:
  https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain

Download releases from GitHub
Requires jailbroken PS4 (5.05/6.72/7.02/7.55/9.00)
PS4BUILD
    ok "OpenOrbis (docs)"
}
add_path "export OO_PS4_TOOLCHAIN=\"$SDKS/sony/ps4\""

# --- PS5 (Prospero SDK) ---
step "PlayStation 5 SDK"
cd "$SDKS/sony"
mkdir -p ps5
cd ps5
cat > README.txt << 'PS5BUILD'
PlayStation 5 Development:

No public homebrew SDK yet (as of 2024)

Resources:
- Prospero (codename research): github.com/OpenOrbis
- FreeBSD base (PS5 runs modified FreeBSD)
- Stay tuned for exploit + SDK releases

For now: Target PS4 (backwards compatible)
PS5BUILD
ok "PS5 SDK (placeholder - no public SDK)"

# ============================================================================
era "🎮 MICROSOFT ERA (2001-Present)"
# ============================================================================

# --- Original Xbox (nxdk / OpenXDK) ---
step "Original Xbox SDK (nxdk)"
cd "$SDKS/microsoft"
mkdir -p xbox
cd xbox
dl "https://github.com/XboxDev/nxdk/archive/refs/heads/master.tar.gz" nxdk.tar.gz && \
tar xzf nxdk.tar.gz >> "$LOG" 2>&1 && mv nxdk-master nxdk && rm -f nxdk.tar.gz && \
ok "nxdk" || fail "nxdk"
cat > BUILD.txt << 'XBOXBUILD'
nxdk Build:
  cd nxdk
  . ./activate
  make -C samples/hello
XBOXBUILD
add_path "export NXDK=\"$SDKS/microsoft/xbox/nxdk\""

# --- Xbox 360 (LibXenon/Free60) ---
step "Xbox 360 SDK (LibXenon)"
cd "$SDKS/microsoft"
mkdir -p xbox360
cd xbox360
cat > INSTALL.txt << 'X360BUILD'
Xbox 360 (LibXenon/Free60):

Requires RGH/JTAG modified console

  git clone https://github.com/Free60Project/libxenon
  cd libxenon/toolchain && ./build-xenon-toolchain

Xenon toolchain creates:
  - xenon-gcc (PowerPC)
  - libxenon (SDK)
X360BUILD
ok "LibXenon (docs)"

# ============================================================================
era "🎮 OTHER PLATFORMS"
# ============================================================================

# --- Neo Geo (ngdevkit) ---
step "Neo Geo SDK (ngdevkit)"
cd "$SDKS/misc"
mkdir -p neogeo
cd neogeo
cat > INSTALL.txt << 'NEOBUILD'
ngdevkit - Neo Geo Development:
  https://github.com/dciabrin/ngdevkit

Ubuntu/Debian:
  sudo add-apt-repository ppa:dciabrin/ngdevkit
  sudo apt install ngdevkit ngdevkit-gngeo

macOS:
  brew tap dciabrin/ngdevkit
  brew install ngdevkit ngdevkit-gngeo
NEOBUILD
$IS_MAC && {
    brew tap dciabrin/ngdevkit >> "$LOG" 2>&1
    brew install ngdevkit >> "$LOG" 2>&1 && ok "ngdevkit" || warn "ngdevkit (manual)"
} || ok "ngdevkit (docs)"

# --- PC Engine / TurboGrafx (HuC) ---
step "PC Engine SDK (HuC)"
cd "$SDKS/misc"
mkdir -p pcengine
cd pcengine
dl "https://github.com/uli/huc/archive/refs/heads/master.tar.gz" huc.tar.gz && \
tar xzf huc.tar.gz >> "$LOG" 2>&1 && mv huc-master huc && rm -f huc.tar.gz && \
ok "HuC (PC Engine)" || fail "HuC"

# --- 3DO ---
step "3DO SDK"
cd "$SDKS/misc"
mkdir -p 3do
cd 3do
cat > README.txt << '3DOBUILD'
3DO Development:
- 3DO SDK leaked (search RetroReversing)
- Modern: Portfolio OS documentation
- ARM60 (ARM6) architecture
3DOBUILD
ok "3DO SDK (docs)"

# --- MSX (SDCC + Fusion-C) ---
step "MSX SDK"
cd "$SDKS/misc"
mkdir -p msx
cd msx
$IS_MAC && ok "SDCC (via brew)" || {
    sudo apt-get install -y -qq sdcc >> "$LOG" 2>&1 && ok "SDCC (MSX/Z80)" || fail "SDCC"
}
dl "https://github.com/theNestruo/msx-fusion-c/archive/refs/heads/main.tar.gz" fusionc.tar.gz 2>/dev/null && \
tar xzf fusionc.tar.gz >> "$LOG" 2>&1 && rm -f fusionc.tar.gz && ok "Fusion-C (MSX)" || warn "Fusion-C"

# --- WLA-DX (Multi-platform assembler) ---
step "WLA-DX (Multi-platform)"
$IS_MAC && ok "WLA-DX (via brew)" || {
    cd "$TOOLS"
    rm -rf wla-dx* 2>/dev/null
    dl "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz" wla.tar.gz && \
    tar xzf wla.tar.gz >> "$LOG" 2>&1 && cd wla-dx-10.6 && \
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release >> "$LOG" 2>&1 && \
    make -j$NCPU >> "$LOG" 2>&1 && ok "WLA-DX" || fail "WLA-DX"
    rm -f "$TOOLS/wla.tar.gz"
    add_path "export PATH=\"$TOOLS/wla-dx-10.6/build/binaries:\$PATH\""
}

# ============================================================================
step "ROM HACKING TOOLS"
# ============================================================================

cd "$TOOLS"
mkdir -p flips
cd flips
FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip"
$IS_MAC && FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-mac.zip"
dl "$FLIPS_URL" flips.zip && unzip -qo flips.zip >> "$LOG" 2>&1 && rm -f flips.zip && \
$IS_MAC && xattr -dr com.apple.quarantine . 2>/dev/null; chmod +x * 2>/dev/null && \
ok "Flips (IPS/BPS patcher)" || fail "Flips"
add_path "export PATH=\"$TOOLS/flips:\$PATH\""

# ============================================================================
step "EMULATORS"
# ============================================================================

cd "$EMUS"

# mGBA
if $IS_MAC; then
    dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-macos.dmg" mgba.dmg && {
        hdiutil attach mgba.dmg -nobrowse >> "$LOG" 2>&1
        cp -R /Volumes/mGBA*/mGBA.app . 2>/dev/null
        hdiutil detach /Volumes/mGBA* >> "$LOG" 2>&1
        xattr -dr com.apple.quarantine mGBA.app 2>/dev/null
        rm -f mgba.dmg
        ok "mGBA"
    } || fail "mGBA"
else
    dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-appimage-x64.appimage" mGBA.AppImage && \
    chmod +x mGBA.AppImage && ok "mGBA" || fail "mGBA"
fi

# Ares (multi-system)
if $IS_MAC; then
    ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-macos-universal.zip"
else
    ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-linux-x86_64.zip"
fi
dl "$ARES_URL" ares.zip && unzip -qo ares.zip >> "$LOG" 2>&1 && rm -f ares.zip && \
$IS_MAC && xattr -dr com.apple.quarantine Ares* ares* 2>/dev/null; ok "Ares v146" || fail "Ares"

# ============================================================================
step "MODERN ENGINES"
# ============================================================================

cd "$TOOLS"

# Raylib
$IS_MAC && ok "Raylib (via brew)" || {
    dl "https://github.com/raysan5/raylib/archive/refs/tags/5.5.tar.gz" raylib.tar.gz && \
    tar xzf raylib.tar.gz >> "$LOG" 2>&1 && rm -f raylib.tar.gz && ok "Raylib 5.5" || fail "Raylib"
}

# Godot
GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
$IS_MAC && GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip"
dl "$GODOT_URL" godot.zip && unzip -qo godot.zip >> "$LOG" 2>&1 && rm -f godot.zip && \
$IS_MAC && xattr -dr com.apple.quarantine Godot* 2>/dev/null; ok "Godot 4.3" || fail "Godot"

# ============================================================================
step "ENVIRONMENT SCRIPT"
# ============================================================================

cat > "$INSTALL_DIR/env.sh" << 'ENVSCRIPT'
#!/bin/bash
# CAT'S TWEAKER v2.0 - Environment Setup
# Source this: source ~/retro-dev/env.sh

export RETRO_DEV="$HOME/retro-dev"

# DevkitPro
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export DEVKITPPC="$DEVKITPRO/devkitPPC"
export DEVKITA64="$DEVKITPRO/devkitA64"

# SDKs
export GBDK="$RETRO_DEV/sdks/nintendo/gbdk"
export SGDK="$RETRO_DEV/sdks/sega/sgdk"
export GDK="$SGDK"
export PVSNESLIB="$RETRO_DEV/sdks/nintendo/pvsneslib"
export PSN00BSDK="$RETRO_DEV/sdks/sony/ps1/psn00bsdk"
export NXDK="$RETRO_DEV/sdks/microsoft/xbox/nxdk"

# N64 (Linux native)
[[ -d "$RETRO_DEV/compilers/n64/bin" ]] && {
    export N64_INST="$RETRO_DEV/compilers/n64"
    export PATH="$N64_INST/bin:$PATH"
}

# All tool paths
export PATH="$DEVKITARM/bin:$DEVKITPPC/bin:$DEVKITA64/bin:$PATH"
export PATH="$GBDK/bin:$RETRO_DEV/tools/asm6:$RETRO_DEV/tools/flips:$PATH"
export PATH="$RETRO_DEV/tools/rgbds:$RETRO_DEV/tools/wla-dx-10.6/build/binaries:$PATH"
export PATH="$RETRO_DEV/sdks/atari:$PATH"

echo ""
echo "🐱 CAT'S TWEAKER v2.0 - Environment loaded! 🎮"
echo ""
echo "   ┌─────────────────────────────────────────────────────────┐"
echo "   │  ATARI      : dasm, cc65, batari Basic                  │"
echo "   │  NES        : asm6f, cc65                               │"
echo "   │  SNES       : pvsneslib                                 │"
echo "   │  GB/GBC     : lcc (GBDK), rgbasm (RGBDS)               │"
echo "   │  N64        : mips64-elf-gcc / libdragon               │"
echo "   │  GBA/NDS    : arm-none-eabi-gcc (devkitARM)            │"
echo "   │  GC/Wii     : powerpc-eabi-gcc (devkitPPC)             │"
echo "   │  Switch     : aarch64-none-elf-gcc (devkitA64)         │"
echo "   │  Genesis    : SGDK                                      │"
echo "   │  SMS/GG     : devkitSMS + SDCC                          │"
echo "   │  PS1        : PSn00bSDK                                 │"
echo "   │  Xbox       : nxdk                                      │"
echo "   └─────────────────────────────────────────────────────────┘"
echo ""
ENVSCRIPT
chmod +x "$INSTALL_DIR/env.sh"
ok "Environment script"

# Add to shell RC
add_path "# CAT'S TWEAKER v2.0"
add_path "source \"$INSTALL_DIR/env.sh\" 2>/dev/null"

# ============================================================================
# COMPLETE
# ============================================================================

echo ""
printf "${G}╔════════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}║${RST}  ${W}✨ CAT'S TWEAKER 2.0 - MEGA SDK PACK COMPLETE! ✨${RST}                 ${G}║${RST}\n"
printf "${G}╠════════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}║${RST}  ${C}Install dir:${RST}  %-52s ${G}║${RST}\n" "$INSTALL_DIR"
printf "${G}║${RST}  ${C}Activate:${RST}     source ~/retro-dev/env.sh                          ${G}║${RST}\n"
printf "${G}║${RST}  ${C}Log file:${RST}     ~/retro-dev/install.log                            ${G}║${RST}\n"
printf "${G}╠════════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}║${RST}  ${Y}DevkitPro (GC/Wii/Switch):${RST}                                        ${G}║${RST}\n"
if $IS_MAC; then
printf "${G}║${RST}    sudo installer -pkg ~/retro-dev/compilers/devkitpro/*.pkg -target / ${G}║${RST}\n"
printf "${G}║${RST}    sudo dkp-pacman -S gamecube-dev wii-dev switch-dev                 ${G}║${RST}\n"
else
printf "${G}║${RST}    Already installed! Verify: \$DEVKITPPC/bin/powerpc-eabi-gcc -v      ${G}║${RST}\n"
fi
printf "${G}╚════════════════════════════════════════════════════════════════════╝${RST}\n"
echo ""
printf "                              ${M}/\\_____/\\${RST}\n"
printf "                             ${M}/  o   o  \\${RST}\n"
printf "                            ${M}( ==  ^  == )${RST}\n"
printf "                             ${M})  ~nya~  (${RST}\n"
printf "                            ${M}(  ALL THE  )${RST}\n"
printf "                           ${M}(   SDKs!!!   )${RST}\n"
printf "                          ${M}( (  )   (  ) )${RST}\n"
printf "                         ${M}(__(__)___(__)__)${RST}\n"
echo ""
