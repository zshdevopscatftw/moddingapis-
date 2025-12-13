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
#                                        「  v1.7 - retro dev toolkit  」
#                                         by Flames / Team Flames 🐱
#
#===============================================================================

[[ -z "$BASH_VERSION" ]] && { echo "Run with: bash $0"; exit 1; }

# Colors
G=$'\033[0;32m'  # Green
Y=$'\033[0;33m'  # Yellow  
C=$'\033[0;36m'  # Cyan
M=$'\033[0;35m'  # Magenta
W=$'\033[1;37m'  # White bold
RST=$'\033[0m'   # Reset

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

IS_MAC=false; [[ "$(uname)" == "Darwin" ]] && IS_MAC=true
IS_ARM=false; [[ "$(uname -m)" == "arm64" ]] && IS_ARM=true
NCPU=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
SHELL_RC="$HOME/.zshrc"; $IS_MAC || SHELL_RC="$HOME/.bashrc"

# Download with retry
dl() {
    local url="$1" out="$2"
    echo "[DL] $url" >> "$LOG"
    curl -fsSL --connect-timeout 30 --max-time 600 --retry 3 -L -o "$out" "$url" 2>>"$LOG"
    if [[ -s "$out" ]]; then
        echo "[DL] Success: $(ls -lh "$out" 2>/dev/null)" >> "$LOG"
        return 0
    fi
    echo "[DL] Failed or empty" >> "$LOG"
    rm -f "$out" 2>/dev/null
    return 1
}

# Status indicators
ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${Y}[✗]${RST} %s ${Y}(see log)${RST}\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
step() { printf "\n${M}▸ %s${RST}\n" "$1"; }

add_path() { grep -qF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }

clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                                       「  v1.7 - retro dev toolkit  」
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )         (
                                          (           )
                                         ( (  )   (  ) )
                                        (__(__)___(__)__)

EOF

# ============================================================================
step "SYSTEM SETUP"
# ============================================================================

if $IS_MAC; then
    if command -v brew >/dev/null 2>&1; then
        ok "Homebrew found"
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG" 2>&1 && ok "Homebrew installed" || fail "Homebrew"
    fi
    
    info "Installing brew packages..."
    brew install gcc llvm cmake ninja meson sdl2 sdl2_image sdl2_mixer sdl2_ttf \
                 libpng jpeg freetype zlib python nasm yasm wget curl p7zip \
                 glew glfw boost raylib rgbds cc65 sdcc wla-dx >> "$LOG" 2>&1 && ok "Brew packages" || fail "Some brew packages"
else
    sudo apt-get update -qq >> "$LOG" 2>&1 && ok "APT update" || fail "APT update"
    sudo apt-get install -y -qq build-essential gcc g++ clang llvm cmake ninja-build meson \
        autoconf automake libtool libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev \
        libpng-dev libjpeg-dev libfreetype6-dev zlib1g-dev python3 python3-pip nasm yasm flex bison \
        texinfo libncurses-dev libreadline-dev curl wget unzip p7zip-full >> "$LOG" 2>&1 && ok "Build tools" || fail "Build tools"
fi

# ============================================================================
step "PYTHON PACKAGES"
# ============================================================================

pip3 install --user --break-system-packages pygame ursina pillow numpy pysdl2 pyyaml toml intelhex pyserial capstone >> "$LOG" 2>&1 && ok "Python packages" || fail "Python packages"

# ============================================================================
step "LIBDRAGON N64 SDK"
# ============================================================================

# Note: libdragon source is downloaded during toolchain build
# This section just verifies it exists
if [[ -d "$COMPILERS/n64/libdragon" ]]; then
    ok "libdragon SDK (included with toolchain)"
else
    cd "$HOME" || cd /tmp
    rm -rf "$SDKS/libdragon" 2>/dev/null
    mkdir -p "$SDKS"
    cd "$SDKS"
    if dl "https://github.com/DragonMinded/libdragon/archive/refs/heads/trunk.tar.gz" libdragon.tar.gz; then
        tar xzf libdragon.tar.gz >> "$LOG" 2>&1
        mv libdragon-trunk libdragon 2>/dev/null
        rm -f libdragon.tar.gz
        ok "libdragon SDK"
    else
        fail "libdragon SDK"
    fi
fi

# ============================================================================
step "N64 TOOLCHAIN (mips64-elf-gcc)"
# ============================================================================

# Always cd to safe location first to avoid getcwd errors
cd "$HOME" || cd /tmp

rm -rf "$COMPILERS/n64" 2>/dev/null
mkdir -p "$COMPILERS/n64"
cd "$COMPILERS/n64"

info "Building N64 toolchain from source..."
info "This builds: mips64-elf-gcc, binutils, newlib (15-30 min)"

# Prereqs check
if $IS_MAC; then
    brew install cmake ninja wget python pkg-config >> "$LOG" 2>&1 || true
fi

# Download libdragon source (no git needed)
if dl "https://github.com/DragonMinded/libdragon/archive/refs/heads/trunk.tar.gz" libdragon.tar.gz; then
    tar xzf libdragon.tar.gz >> "$LOG" 2>&1
    mv libdragon-trunk libdragon 2>/dev/null
    rm -f libdragon.tar.gz
    
    cd libdragon
    
    # Build the REAL N64 toolchain
    info "Running build-toolchain.sh..."
    if ./tools/build-toolchain.sh >> "$LOG" 2>&1; then
        # Toolchain binary location
        TC_BIN="$COMPILERS/n64/libdragon/tools/bin"
        
        # Add to PATH
        add_path "export N64_INST=\"$COMPILERS/n64/libdragon\""
        add_path "export PATH=\"$TC_BIN:\$PATH\""
        
        ok "N64 toolchain (mips64-elf-gcc)"
        info "Verify: mips64-elf-gcc --version"
        info "Test: cd libdragon/examples/hello_world && make"
    else
        fail "N64 toolchain build"
        info "Check: ~/retro-dev/install.log"
        info "May need: brew install cmake ninja wget python pkg-config"
    fi
else
    fail "libdragon download"
fi

# ============================================================================
step "DEVKITPRO"
# ============================================================================

cd "$HOME" || cd /tmp
rm -rf "$COMPILERS/devkitpro" 2>/dev/null
mkdir -p "$COMPILERS/devkitpro"
cd "$COMPILERS/devkitpro"

if $IS_MAC; then
    DKP_URL="https://github.com/devkitPro/pacman/releases/latest/download/devkitpro-pacman-installer.pkg"
    if dl "$DKP_URL" devkitpro.pkg; then
        ok "DevkitPro installer"
        info "Run: sudo installer -pkg $COMPILERS/devkitpro/devkitpro.pkg -target /"
    else
        fail "DevkitPro"
    fi
else
    dl "https://apt.devkitpro.org/install-devkitpro-pacman" dkp-install.sh && chmod +x dkp-install.sh && ok "DevkitPro installer" || fail "DevkitPro"
fi
add_path "export DEVKITPRO=\"/opt/devkitpro\"; export DEVKITARM=\"\$DEVKITPRO/devkitARM\""

# ============================================================================
step "GBDK-2020"
# ============================================================================

cd "$HOME" || cd /tmp
mkdir -p "$SDKS"
cd "$SDKS"
rm -f gbdk.tar.gz 2>/dev/null

GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz"
$IS_MAC && GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-macos.tar.gz"
dl "$GB_URL" gbdk.tar.gz && tar xzf gbdk.tar.gz >> "$LOG" 2>&1 && ok "GBDK-2020" || fail "GBDK-2020"
rm -f gbdk.tar.gz
add_path "export GBDK=\"$SDKS/gbdk\"; export PATH=\"\$GBDK/bin:\$PATH\""

# ============================================================================
step "ASSEMBLERS"
# ============================================================================

cd "$HOME" || cd /tmp

# RGBDS
$IS_MAC && ok "RGBDS (via brew)" || {
    mkdir -p "$TOOLS/rgbds"
    cd "$TOOLS/rgbds"
    dl "https://github.com/gbdev/rgbds/releases/download/v0.8.0/rgbds-0.8.0-linux-x86_64.tar.xz" rgbds.tar.xz && \
    tar xJf rgbds.tar.xz >> "$LOG" 2>&1 && ok "RGBDS" || fail "RGBDS"
    rm -f rgbds.tar.xz
    add_path "export PATH=\"$TOOLS/rgbds:\$PATH\""
}

# ASM6F - build from source
cd "$HOME" || cd /tmp
mkdir -p "$TOOLS/asm6"
cd "$TOOLS/asm6"
# Embed minimal asm6f source
cat > asm6f.c << 'ASM6SRC'
// ASM6F - 6502 Assembler by loopy, modifications by freem
// Minimal stub - get full version from https://github.com/freem/asm6f
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
int main(int c, char**v) {
    if(c<2){printf("asm6f - 6502 assembler\nUsage: asm6f input.asm [output.bin]\n");return 1;}
    printf("This is a stub. Download full asm6f from:\nhttps://github.com/freem/asm6f\n");
    return 1;
}
ASM6SRC
cc -O3 -w asm6f.c -o asm6f 2>/dev/null && chmod +x asm6f
# Try to get real source
if dl "https://raw.githubusercontent.com/freem/asm6f/main/asm6f.c" asm6f_real.c 2>/dev/null; then
    cc -O3 -w asm6f_real.c -o asm6f 2>/dev/null && ok "ASM6F" || ok "ASM6F (stub)"
    rm -f asm6f_real.c
else
    ok "ASM6F (stub - get full: github.com/freem/asm6f)"
fi
add_path "export PATH=\"$TOOLS/asm6:\$PATH\""

# WLA-DX
cd "$HOME" || cd /tmp
$IS_MAC && ok "WLA-DX (via brew)" || {
    mkdir -p "$TOOLS"
    cd "$TOOLS"
    rm -rf wla-dx-10.6 wla.tar.gz 2>/dev/null
    dl "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz" wla.tar.gz && \
    tar xzf wla.tar.gz >> "$LOG" 2>&1 && cd wla-dx-10.6 && mkdir -p build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release >> "$LOG" 2>&1 && make -j$NCPU >> "$LOG" 2>&1 && ok "WLA-DX" || fail "WLA-DX"
    rm -f "$TOOLS/wla.tar.gz"
    add_path "export PATH=\"$TOOLS/wla-dx-10.6/build/binaries:\$PATH\""
}

# DASM
cd "$HOME" || cd /tmp
mkdir -p "$SDKS/atari"
cd "$SDKS/atari"
DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz"
$IS_MAC && DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz"
dl "$DASM_URL" dasm.tar.gz && tar xzf dasm.tar.gz >> "$LOG" 2>&1 && ok "DASM" || fail "DASM"
rm -f dasm.tar.gz
add_path "export PATH=\"$SDKS/atari:\$PATH\""

# ============================================================================
step "GENESIS/SNES SDKS"
# ============================================================================

cd "$HOME" || cd /tmp
mkdir -p "$SDKS"
cd "$SDKS"
rm -rf sgdk SGDK-2.00 sgdk.tar.gz 2>/dev/null

dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz && \
tar xzf sgdk.tar.gz >> "$LOG" 2>&1 && mv SGDK-2.00 sgdk 2>/dev/null && ok "SGDK" || fail "SGDK"
rm -f sgdk.tar.gz
add_path "export SGDK=\"$SDKS/sgdk\""

cd "$HOME" || cd /tmp
cd "$SDKS"
rm -rf pvsneslib pvsneslib-master pvs.zip 2>/dev/null

dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip && \
unzip -qo pvs.zip >> "$LOG" 2>&1 && mv pvsneslib-master pvsneslib 2>/dev/null && ok "PVSnesLib" || fail "PVSnesLib"
rm -f pvs.zip
add_path "export PVSNESLIB=\"$SDKS/pvsneslib\""

# ============================================================================
step "ROM HACKING TOOLS"
# ============================================================================

cd "$HOME" || cd /tmp
rm -rf "$TOOLS/flips" 2>/dev/null
mkdir -p "$TOOLS/flips"
cd "$TOOLS/flips"

# Flips v198 (latest)
FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip"
$IS_MAC && FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-mac.zip"
if dl "$FLIPS_URL" flips.zip; then
    unzip -qo flips.zip >> "$LOG" 2>&1
    $IS_MAC && xattr -dr com.apple.quarantine . 2>/dev/null
    chmod +x * 2>/dev/null
    ok "Flips"
else
    # Build from source as fallback (no git)
    info "Building Flips from source..."
    cd "$HOME" || cd /tmp
    rm -rf "$TOOLS/flips-src" "$TOOLS/Flips-master" 2>/dev/null
    cd "$TOOLS"
    if dl "https://github.com/Alcaro/Flips/archive/refs/heads/master.tar.gz" flips-src.tar.gz; then
        tar xzf flips-src.tar.gz >> "$LOG" 2>&1
        cd Flips-master
        if $IS_MAC; then
            make CFLAGS="-O3" >> "$LOG" 2>&1 && cp flips "$TOOLS/flips/" && ok "Flips (built)" || fail "Flips"
        else
            ./make-linux.sh >> "$LOG" 2>&1 && cp flips "$TOOLS/flips/" && ok "Flips (built)" || fail "Flips"
        fi
        cd "$HOME" || cd /tmp
        rm -rf "$TOOLS/Flips-master" "$TOOLS/flips-src.tar.gz"
    else
        fail "Flips"
    fi
fi
rm -f "$TOOLS/flips/flips.zip"
add_path "export PATH=\"$TOOLS/flips:\$PATH\""

# ============================================================================
step "EMULATORS"
# ============================================================================

cd "$HOME" || cd /tmp
mkdir -p "$EMUS"
cd "$EMUS"

# mGBA 0.10.5 (latest)
if $IS_MAC; then
    rm -f mgba.dmg 2>/dev/null
    # Universal macOS build
    if dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-macos.dmg" mgba.dmg; then
        hdiutil attach mgba.dmg -nobrowse >> "$LOG" 2>&1
        cp -R /Volumes/mGBA*/mGBA.app "$EMUS" 2>/dev/null
        hdiutil detach /Volumes/mGBA* >> "$LOG" 2>&1
        xattr -dr com.apple.quarantine "$EMUS/mGBA.app" 2>/dev/null
        ok "mGBA 0.10.5"
    else
        fail "mGBA"
    fi
    rm -f mgba.dmg
else
    dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-appimage-x64.appimage" mGBA.AppImage && \
    chmod +x mGBA.AppImage && ok "mGBA 0.10.5" || fail "mGBA"
fi

# Ares v146 (latest) - macOS is Universal Binary
cd "$HOME" || cd /tmp
cd "$EMUS"
rm -f ares.zip 2>/dev/null

if $IS_MAC; then
    ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-macos-universal.zip"
else
    ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-linux-x86_64.zip"
fi
if dl "$ARES_URL" ares.zip; then
    unzip -qo ares.zip >> "$LOG" 2>&1
    $IS_MAC && xattr -dr com.apple.quarantine ares* Ares* 2>/dev/null
    chmod +x ares*/ares Ares.app/Contents/MacOS/ares 2>/dev/null
    ok "Ares v146"
else
    fail "Ares"
fi
rm -f ares.zip

# ============================================================================
step "MODERN ENGINES"
# ============================================================================

cd "$HOME" || cd /tmp
mkdir -p "$TOOLS"
cd "$TOOLS"

$IS_MAC && ok "Raylib (via brew)" || {
    rm -f raylib.tar.gz 2>/dev/null
    dl "https://github.com/raysan5/raylib/archive/refs/tags/5.5.tar.gz" raylib.tar.gz && \
    tar xzf raylib.tar.gz >> "$LOG" 2>&1 && ok "Raylib" || fail "Raylib"
    rm -f raylib.tar.gz
}

cd "$HOME" || cd /tmp
cd "$TOOLS"
rm -f godot.zip 2>/dev/null

GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
$IS_MAC && GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip"
dl "$GODOT_URL" godot.zip && unzip -qo godot.zip >> "$LOG" 2>&1 && ok "Godot 4.3" || fail "Godot"
$IS_MAC && xattr -dr com.apple.quarantine Godot* 2>/dev/null
rm -f godot.zip

# ============================================================================
step "ENVIRONMENT SETUP"
# ============================================================================

cd "$HOME" || cd /tmp

cat > "$INSTALL_DIR/env.sh" << 'ENVEOF'
#!/bin/bash
export RETRO_DEV="$HOME/retro-dev"
export N64_INST="$RETRO_DEV/compilers/n64/libdragon"
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export GBDK="$RETRO_DEV/sdks/gbdk"
export SGDK="$RETRO_DEV/sdks/sgdk"
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"
export PATH="$N64_INST/tools/bin:$DEVKITARM/bin:$GBDK/bin:$RETRO_DEV/tools/asm6:$RETRO_DEV/tools/flips:$RETRO_DEV/tools/rgbds:$RETRO_DEV/tools/wla-dx-10.6/build/binaries:$RETRO_DEV/sdks/atari:$PATH"
echo "🐱 CAT'S TWEAKER environment loaded! 🎮"
echo "   N64: mips64-elf-gcc --version"
ENVEOF
chmod +x "$INSTALL_DIR/env.sh"
ok "Environment script"

# ============================================================================
# COMPLETE
# ============================================================================

echo ""
printf "${G}  ╔═══════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}  ║${RST}  ${W}✨ CAT'S TWEAKER 1.7 INSTALLATION COMPLETE! ✨${RST}                ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}  ${C}Installed to:${RST} %-44s ${G}║${RST}\n" "$INSTALL_DIR"
printf "${G}  ║${RST}  ${C}Activate:${RST}     source ~/retro-dev/env.sh                      ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Log:${RST}          ~/retro-dev/install.log                       ${G}║${RST}\n"
printf "${G}  ╚═══════════════════════════════════════════════════════════════╝${RST}\n"
echo ""
printf "                           ${M}/\\_____/\\${RST}\n"
printf "                          ${M}/  o   o  \\${RST}\n"
printf "                         ${M}( ==  ^  == )${RST}\n"
printf "                          ${M})  ~nya~  (${RST}\n"
printf "                         ${M}(           )${RST}\n"
printf "                        ${M}( (  )   (  ) )${RST}\n"
printf "                       ${M}(__(__)___(__)__)${RST}\n"
echo ""
