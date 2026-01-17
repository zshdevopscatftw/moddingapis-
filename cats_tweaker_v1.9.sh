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
#                                        「  v1.9 - retro dev toolkit  」
#                                         by Flames / Team Flames 🐱
#                              Apple Silicon M4 Pro + Rosetta 2 Optimized
#
#===============================================================================

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

# Colors
G=$'\033[0;32m'
Y=$'\033[0;33m'
C=$'\033[0;36m'
M=$'\033[0;35m'
R=$'\033[0;31m'
W=$'\033[1;37m'
RST=$'\033[0m'

# ============================================================================
# PLATFORM DETECTION
# ============================================================================

IS_MAC=false; [[ "$(uname)" == "Darwin" ]] && IS_MAC=true
IS_ARM=false; [[ "$(uname -m)" == "arm64" ]] && IS_ARM=true
IS_ROSETTA=false
HAS_DOCKER=false

# Apple Silicon Homebrew at /opt/homebrew
if $IS_MAC && $IS_ARM; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

# CRITICAL FIX: Source Homebrew into current shell IMMEDIATELY
if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
    eval "$("$BREW_PREFIX/bin/brew" shellenv)"
    export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
fi

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

NCPU=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
SHELL_RC="$HOME/.zshrc"
$IS_MAC || SHELL_RC="$HOME/.bashrc"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

dl() {
    local url="$1" out="$2"
    echo "[DL] $url" >> "$LOG"
    curl -fsSL --connect-timeout 30 --max-time 900 --retry 3 -L -o "$out" "$url" 2>>"$LOG"
    if [[ -s "$out" ]]; then
        echo "[DL] OK: $(ls -lh "$out" 2>/dev/null)" >> "$LOG"
        return 0
    fi
    echo "[DL] FAIL" >> "$LOG"
    rm -f "$out" 2>/dev/null
    return 1
}

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${R}[✗]${RST} %s ${Y}(see log)${RST}\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
step() { printf "\n${M}▸ %s${RST}\n" "$1"; }

add_path() {
    local line="$1"
    [[ -z "$line" ]] && return
    grep -qxF "$line" "$SHELL_RC" 2>/dev/null || echo "$line" >> "$SHELL_RC"
}

# ============================================================================
# BANNER
# ============================================================================

clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                                       「  v1.9 - retro dev toolkit  」
                                    Apple Silicon M4 Pro + Rosetta 2 Ready
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )         (
                                          (           )
                                         ( (  )   (  ) )
                                        (__(__)___(__)__)

EOF

# ============================================================================
step "SYSTEM DETECTION"
# ============================================================================

if $IS_MAC; then
    ok "macOS detected"
    if $IS_ARM; then
        ok "Apple Silicon (arm64) - M4 Pro optimized"
        
        # Check/Install Rosetta 2
        if /usr/bin/pgrep -q oahd 2>/dev/null || [[ -f /Library/Apple/usr/share/rosetta/rosetta ]]; then
            IS_ROSETTA=true
            ok "Rosetta 2 installed"
        else
            info "Installing Rosetta 2 (for x86_64 tools)..."
            if softwareupdate --install-rosetta --agree-to-license >> "$LOG" 2>&1; then
                IS_ROSETTA=true
                ok "Rosetta 2 installed"
            else
                warn "Rosetta 2 failed - some x86 tools may not work"
            fi
        fi
    else
        ok "Intel Mac (x86_64)"
    fi
else
    ok "Linux detected"
fi

# ============================================================================
step "HOMEBREW SETUP"
# ============================================================================

if $IS_MAC; then
    if command -v brew >/dev/null 2>&1; then
        ok "Homebrew: $(which brew)"
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG" 2>&1
        
        if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
            eval "$("$BREW_PREFIX/bin/brew" shellenv)"
            export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
            ok "Homebrew installed"
        else
            fail "Homebrew"
        fi
    fi
    
    # Add to shell RC
    add_path "# Homebrew"
    add_path 'eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null'
    
    info "Updating Homebrew..."
    brew update >> "$LOG" 2>&1 || true
fi

# ============================================================================
step "CORE BUILD TOOLS"
# ============================================================================

if $IS_MAC; then
    info "Installing packages (may take a few minutes)..."
    
    # Batch installs for better error isolation
    brew install gcc llvm cmake ninja meson autoconf automake libtool pkg-config >> "$LOG" 2>&1 && ok "Core: gcc llvm cmake ninja meson" || warn "Some core failed"
    brew install sdl2 sdl2_image sdl2_mixer sdl2_ttf libpng jpeg freetype zlib boost glew glfw >> "$LOG" 2>&1 && ok "Libs: SDL2, PNG, freetype" || warn "Some libs failed"
    brew install nasm yasm >> "$LOG" 2>&1 && ok "Assemblers: nasm yasm" || warn "nasm/yasm failed"
    brew install rgbds cc65 sdcc wla-dx >> "$LOG" 2>&1 && ok "Retro: rgbds cc65 sdcc wla-dx" || warn "Some retro failed"
    brew install wget curl p7zip python node >> "$LOG" 2>&1 && ok "Utils: wget python node" || warn "Some utils failed"
    brew install raylib >> "$LOG" 2>&1 && ok "Raylib" || warn "Raylib failed"
    
    # CRITICAL: Refresh PATH after brew installs
    eval "$("$BREW_PREFIX/bin/brew" shellenv)"
    export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
    hash -r 2>/dev/null || true
    
    # Verify nasm/yasm NOW
    if command -v nasm >/dev/null 2>&1; then
        ok "nasm verified: $(nasm -v 2>&1 | head -1)"
    else
        warn "nasm not in PATH - run: source ~/.zshrc"
    fi
    
    if command -v yasm >/dev/null 2>&1; then
        ok "yasm verified: $(yasm --version 2>&1 | head -1)"
    else
        warn "yasm not in PATH - run: source ~/.zshrc"
    fi
else
    info "Installing build tools..."
    sudo apt-get update -qq >> "$LOG" 2>&1
    sudo apt-get install -y -qq \
        build-essential gcc g++ clang llvm cmake ninja-build meson \
        autoconf automake libtool pkg-config \
        libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev \
        libpng-dev libjpeg-dev libfreetype6-dev zlib1g-dev \
        python3 python3-pip nasm yasm flex bison texinfo \
        libncurses-dev libreadline-dev curl wget unzip p7zip-full git \
        >> "$LOG" 2>&1 && ok "Build tools" || fail "Build tools"
fi

# ============================================================================
step "PYTHON PACKAGES"
# ============================================================================

if $IS_MAC; then
    PIP="$BREW_PREFIX/bin/pip3"
    [[ -x "$PIP" ]] || PIP="pip3"
else
    PIP="pip3"
fi

info "Installing Python packages..."
$PIP install --user --break-system-packages \
    pygame pillow numpy pysdl2 pyyaml toml intelhex pyserial capstone \
    >> "$LOG" 2>&1 && ok "Python packages" || warn "Some Python packages failed"

# ============================================================================
step "DOCKER CHECK"
# ============================================================================

if command -v docker >/dev/null 2>&1; then
    HAS_DOCKER=true
    ok "Docker installed"
    if docker info >/dev/null 2>&1; then
        ok "Docker daemon running"
    else
        warn "Docker not running - start Docker Desktop for N64 dev"
    fi
else
    warn "Docker not found - needed for N64 dev"
    info "Install: https://docker.com/products/docker-desktop"
fi

# ============================================================================
step "N64 DEVELOPMENT (libdragon)"
# ============================================================================

mkdir -p "$COMPILERS/n64"
cd "$COMPILERS/n64"

if $IS_MAC; then
    info "N64 on macOS: Docker + libdragon CLI"
    
    if $HAS_DOCKER && command -v npm >/dev/null 2>&1; then
        info "Installing libdragon CLI..."
        npm install -g libdragon >> "$LOG" 2>&1 && ok "libdragon CLI" || warn "libdragon CLI failed"
        
        if command -v libdragon >/dev/null 2>&1; then
            info "Pulling Docker image (~500MB)..."
            docker pull ghcr.io/dragonminded/libdragon:latest >> "$LOG" 2>&1 && ok "libdragon Docker image" || warn "Docker pull failed"
            ok "N64 toolchain ready"
            info "Usage: mkdir proj && cd proj && libdragon init && libdragon make"
        fi
    else
        warn "Need Docker + Node.js for N64"
        info "brew install node && install Docker Desktop"
    fi
else
    info "Downloading prebuilt N64 toolchain..."
    TC_URL="https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz"
    if dl "$TC_URL" tc.tar.gz; then
        tar xzf tc.tar.gz >> "$LOG" 2>&1
        rm -f tc.tar.gz
        ok "N64 toolchain (mips64-elf-gcc)"
    else
        fail "N64 toolchain"
    fi
fi

# ============================================================================
step "DEVKITPRO (GBA/NDS/3DS/Switch)"
# ============================================================================

mkdir -p "$COMPILERS/devkitpro"
cd "$COMPILERS/devkitpro"

if $IS_MAC; then
    if dl "https://github.com/devkitPro/pacman/releases/latest/download/devkitpro-pacman-installer.pkg" devkitpro.pkg; then
        ok "DevkitPro installer"
        info "Run: sudo installer -pkg $COMPILERS/devkitpro/devkitpro.pkg -target /"
        info "Then: sudo dkp-pacman -S gba-dev nds-dev 3ds-dev switch-dev"
    else
        fail "DevkitPro"
    fi
else
    if dl "https://apt.devkitpro.org/install-devkitpro-pacman" dkp-install.sh; then
        chmod +x dkp-install.sh
        ok "DevkitPro installer"
        info "Run: sudo ./dkp-install.sh"
    else
        fail "DevkitPro"
    fi
fi

# ============================================================================
step "GBDK-2020 (Game Boy)"
# ============================================================================

cd "$SDKS"
rm -rf gbdk gbdk.tar.gz 2>/dev/null

$IS_MAC && GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-macos.tar.gz" || \
           GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz"

if dl "$GB_URL" gbdk.tar.gz; then
    tar xzf gbdk.tar.gz >> "$LOG" 2>&1
    rm -f gbdk.tar.gz
    ok "GBDK-2020 4.3.0"
else
    fail "GBDK-2020"
fi

# ============================================================================
step "ASSEMBLERS"
# ============================================================================

# ASM6F (NES/6502)
mkdir -p "$TOOLS/asm6"
cd "$TOOLS/asm6"
info "Building ASM6F..."
if dl "https://raw.githubusercontent.com/freem/asm6f/main/asm6f.c" asm6f.c; then
    cc -O3 -o asm6f asm6f.c >> "$LOG" 2>&1 && chmod +x asm6f && ok "ASM6F" || warn "ASM6F build failed"
else
    warn "ASM6F download failed"
fi

# DASM (Atari/6502)
mkdir -p "$SDKS/atari"
cd "$SDKS/atari"
$IS_MAC && DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz" || \
           DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz"

if dl "$DASM_URL" dasm.tar.gz; then
    tar xzf dasm.tar.gz >> "$LOG" 2>&1
    rm -f dasm.tar.gz
    chmod +x dasm* 2>/dev/null
    ok "DASM (Rosetta 2)" 
else
    fail "DASM"
fi

# VASM (multi-CPU)
mkdir -p "$TOOLS/vasm"
cd "$TOOLS/vasm"
info "Building VASM..."
if dl "http://phoenix.owl.de/tags/vasm1_9i.tar.gz" vasm.tar.gz; then
    tar xzf vasm.tar.gz >> "$LOG" 2>&1
    cd vasm 2>/dev/null || cd vasm-* 2>/dev/null || true
    make CPU=6502 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1 && cp vasm6502_oldstyle "$TOOLS/vasm/" 2>/dev/null
    make clean >> "$LOG" 2>&1
    make CPU=m68k SYNTAX=mot -j$NCPU >> "$LOG" 2>&1 && cp vasmm68k_mot "$TOOLS/vasm/" 2>/dev/null
    cd "$TOOLS/vasm"
    rm -rf vasm vasm-* vasm.tar.gz
    [[ -f vasm6502_oldstyle ]] && ok "VASM (6502, 68K)" || warn "VASM partial"
else
    warn "VASM failed"
fi

# ============================================================================
step "GENESIS SDK (SGDK)"
# ============================================================================

cd "$SDKS"
rm -rf sgdk SGDK-* sgdk.tar.gz 2>/dev/null
if dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz; then
    tar xzf sgdk.tar.gz >> "$LOG" 2>&1
    mv SGDK-2.00 sgdk 2>/dev/null
    rm -f sgdk.tar.gz
    ok "SGDK 2.00"
else
    fail "SGDK"
fi

# ============================================================================
step "SNES SDK (PVSnesLib)"
# ============================================================================

cd "$SDKS"
rm -rf pvsneslib pvsneslib-* pvs.zip 2>/dev/null
if dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip; then
    unzip -qo pvs.zip >> "$LOG" 2>&1
    mv pvsneslib-master pvsneslib 2>/dev/null
    rm -f pvs.zip
    ok "PVSnesLib"
else
    fail "PVSnesLib"
fi

# ============================================================================
step "ROM HACKING TOOLS"
# ============================================================================

mkdir -p "$TOOLS/flips"
cd "$TOOLS/flips"

$IS_MAC && FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-mac.zip" || \
           FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip"

if dl "$FLIPS_URL" flips.zip; then
    unzip -qo flips.zip >> "$LOG" 2>&1
    rm -f flips.zip
    chmod +x * 2>/dev/null
    $IS_MAC && xattr -dr com.apple.quarantine . 2>/dev/null
    ok "Flips v198"
else
    info "Building Flips..."
    cd "$TOOLS"
    if dl "https://github.com/Alcaro/Flips/archive/refs/heads/master.tar.gz" flips-src.tar.gz; then
        tar xzf flips-src.tar.gz >> "$LOG" 2>&1
        cd Flips-master
        make CFLAGS="-O3" >> "$LOG" 2>&1 && cp flips "$TOOLS/flips/" && ok "Flips (built)" || fail "Flips"
        cd "$TOOLS"
        rm -rf Flips-master flips-src.tar.gz
    else
        fail "Flips"
    fi
fi

# ============================================================================
step "EMULATORS"
# ============================================================================

mkdir -p "$EMUS"
cd "$EMUS"

# mGBA
if $IS_MAC; then
    if dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-macos.dmg" mgba.dmg; then
        hdiutil attach mgba.dmg -nobrowse >> "$LOG" 2>&1
        cp -R /Volumes/mGBA*/mGBA.app . 2>/dev/null
        hdiutil detach /Volumes/mGBA* >> "$LOG" 2>&1
        xattr -dr com.apple.quarantine mGBA.app 2>/dev/null
        rm -f mgba.dmg
        ok "mGBA 0.10.5"
    else
        fail "mGBA"
    fi
else
    dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-appimage-x64.appimage" mGBA.AppImage && \
    chmod +x mGBA.AppImage && ok "mGBA 0.10.5" || fail "mGBA"
fi

# Ares
$IS_MAC && ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-macos-universal.zip" || \
           ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-linux-x86_64.zip"

if dl "$ARES_URL" ares.zip; then
    unzip -qo ares.zip >> "$LOG" 2>&1
    rm -f ares.zip
    $IS_MAC && xattr -dr com.apple.quarantine Ares* ares* 2>/dev/null
    ok "Ares v146"
else
    fail "Ares"
fi

# ============================================================================
step "MODERN ENGINES"
# ============================================================================

cd "$TOOLS"

$IS_MAC && GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip" || \
           GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"

if dl "$GODOT_URL" godot.zip; then
    unzip -qo godot.zip >> "$LOG" 2>&1
    rm -f godot.zip
    $IS_MAC && xattr -dr com.apple.quarantine Godot* 2>/dev/null
    ok "Godot 4.3"
else
    fail "Godot"
fi

$IS_MAC && ok "Raylib (via brew)"

# ============================================================================
step "ENVIRONMENT SCRIPT"
# ============================================================================

cat > "$INSTALL_DIR/env.sh" << 'ENVEOF'
#!/bin/bash
# Cat's Tweaker v1.9 Environment

export RETRO_DEV="$HOME/retro-dev"

# Homebrew (Apple Silicon + Intel)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# DevkitPro
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export DEVKITPPC="$DEVKITPRO/devkitPPC"

# SDKs
export GBDK="$RETRO_DEV/sdks/gbdk"
export SGDK="$RETRO_DEV/sdks/sgdk"
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"

# N64 (Linux)
if [[ -d "$RETRO_DEV/compilers/n64/bin" ]]; then
    export N64_INST="$RETRO_DEV/compilers/n64"
    export PATH="$N64_INST/bin:$PATH"
fi

# Tools
export PATH="$DEVKITARM/bin:$GBDK/bin:$PATH"
export PATH="$RETRO_DEV/tools/asm6:$PATH"
export PATH="$RETRO_DEV/tools/vasm:$PATH"
export PATH="$RETRO_DEV/tools/flips:$PATH"
export PATH="$RETRO_DEV/sdks/atari:$PATH"

echo ""
echo "  🐱 CAT'S TWEAKER v1.9 loaded! 🎮"
echo ""
echo "  N64 (macOS):  libdragon init && libdragon make"
echo "  N64 (Linux):  mips64-elf-gcc --version"
echo "  GB/GBC:       lcc --version"
echo "  GBA/NDS:      arm-none-eabi-gcc (DevkitPro)"
echo "  NES:          asm6f input.asm output.nes"
echo ""
ENVEOF

chmod +x "$INSTALL_DIR/env.sh"
ok "Environment script"

add_path ""
add_path "# Cat's Tweaker v1.9"
add_path "source \"$INSTALL_DIR/env.sh\" 2>/dev/null"

# ============================================================================
step "VERIFICATION"
# ============================================================================

source "$INSTALL_DIR/env.sh" 2>/dev/null || true

command -v nasm >/dev/null 2>&1 && ok "nasm: $(nasm -v 2>&1 | head -1)" || warn "nasm: source ~/.zshrc first"
command -v yasm >/dev/null 2>&1 && ok "yasm: $(yasm --version 2>&1 | head -1)" || warn "yasm: source ~/.zshrc first"
command -v cc65 >/dev/null 2>&1 && ok "cc65: found" || warn "cc65: not found"
command -v sdcc >/dev/null 2>&1 && ok "sdcc: found" || warn "sdcc: not found"
command -v rgbasm >/dev/null 2>&1 && ok "rgbasm: found" || warn "rgbasm: not found"
[[ -x "$GBDK/bin/lcc" ]] && ok "GBDK lcc: found" || warn "GBDK: not found"
command -v libdragon >/dev/null 2>&1 && ok "libdragon: found" || warn "libdragon: npm install -g libdragon"

# ============================================================================
# COMPLETE
# ============================================================================

echo ""
printf "${G}  ╔═══════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}  ║${RST}  ${W}✨ CAT'S TWEAKER v1.9 INSTALLATION COMPLETE! ✨${RST}                  ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}  ${C}Platform:${RST}     Apple Silicon M4 Pro + Rosetta 2              ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Installed to:${RST} ~/retro-dev                                    ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Log:${RST}          ~/retro-dev/install.log                        ${G}║${RST}\n"
printf "${G}  ╠═══════════════════════════════════════════════════════════════════╣${RST}\n"
printf "${G}  ║${RST}  ${Y}IMPORTANT:${RST} Run to activate:  ${W}source ~/.zshrc${RST}                 ${G}║${RST}\n"
printf "${G}  ╚═══════════════════════════════════════════════════════════════════╝${RST}\n"
echo ""
printf "                             ${M}/\\_____/\\${RST}\n"
printf "                            ${M}/  o   o  \\${RST}\n"
printf "                           ${M}( ==  ^  == )${RST}\n"
printf "                            ${M})  ~nya~  (${RST}\n"
printf "                           ${M}(           )${RST}\n"
printf "                          ${M}( (  )   (  ) )${RST}\n"
printf "                         ${M}(__(__)___(__)__)${RST}\n"
echo ""
echo ""
info "POST-INSTALL:"
echo "  1. ${W}source ~/.zshrc${RST}"
echo "  2. DevkitPro: sudo installer -pkg ~/retro-dev/compilers/devkitpro/devkitpro.pkg -target /"
echo "  3. N64: Start Docker Desktop, then: mkdir proj && cd proj && libdragon init"
echo ""
