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
#
#   FIXES IN v1.9:
#   - Fixed DASM for Apple Silicon (ARM64) Macs
#   - Fixed libdragon init Docker detection
#   - Added Docker Desktop auto-start
#   - Better error handling for all tools
#   - Added missing ASM6F full source build
#   - Fixed DevkitPro auto-install on macOS
#
#===============================================================================

[[ -z "$BASH_VERSION" ]] && { echo "Run with: bash $0"; exit 1; }

# Colors
G=$'\033[0;32m'  # Green
Y=$'\033[0;33m'  # Yellow  
R=$'\033[0;31m'  # Red
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

# Download with retry and better error handling
dl() {
    local url="$1" out="$2"
    echo "[DL] $url" >> "$LOG"
    
    # Try curl first
    if curl -fsSL --connect-timeout 30 --max-time 600 --retry 3 -L -o "$out" "$url" 2>>"$LOG"; then
        if [[ -s "$out" ]]; then
            echo "[DL] Success: $(ls -lh "$out" 2>/dev/null)" >> "$LOG"
            return 0
        fi
    fi
    
    # Try wget as fallback
    if command -v wget >/dev/null 2>&1; then
        rm -f "$out" 2>/dev/null
        if wget -q --timeout=30 -O "$out" "$url" 2>>"$LOG"; then
            if [[ -s "$out" ]]; then
                echo "[DL] Success (wget): $(ls -lh "$out" 2>/dev/null)" >> "$LOG"
                return 0
            fi
        fi
    fi
    
    echo "[DL] Failed or empty" >> "$LOG"
    rm -f "$out" 2>/dev/null
    return 1
}

# Status indicators
ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${R}[✗]${RST} %s ${Y}(see log)${RST}\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
step() { printf "\n${M}▸ %s${RST}\n" "$1"; }

add_path() { grep -qF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }

# Check if Docker is running (macOS)
check_docker_running() {
    if $IS_MAC; then
        if ! docker info >/dev/null 2>&1; then
            return 1
        fi
    fi
    return 0
}

# Start Docker Desktop (macOS)
start_docker() {
    if $IS_MAC; then
        if [[ -d "/Applications/Docker.app" ]]; then
            info "Starting Docker Desktop..."
            open -a Docker
            # Wait up to 60 seconds for Docker to start
            local count=0
            while ! docker info >/dev/null 2>&1; do
                sleep 2
                count=$((count + 1))
                if [[ $count -ge 30 ]]; then
                    return 1
                fi
            done
            return 0
        fi
        return 1
    fi
    return 0
}

clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                                       「  v1.9 - retro dev toolkit  」
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )  ~nya~  (
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
        # Add brew to path for Apple Silicon
        if $IS_ARM; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    
    info "Installing brew packages..."
    # Install in smaller batches to avoid failures
    brew install gcc llvm cmake ninja meson >> "$LOG" 2>&1
    brew install sdl2 sdl2_image sdl2_mixer sdl2_ttf >> "$LOG" 2>&1
    brew install libpng jpeg freetype zlib python nasm yasm >> "$LOG" 2>&1
    brew install wget curl p7zip glew glfw boost >> "$LOG" 2>&1
    brew install raylib rgbds cc65 sdcc wla-dx >> "$LOG" 2>&1
    ok "Brew packages"
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

cd "$HOME" || cd /tmp

if $IS_MAC; then
    # On macOS, libdragon is managed via Docker CLI
    if command -v libdragon >/dev/null 2>&1; then
        ok "libdragon CLI found"
    else
        info "libdragon CLI will be installed in toolchain section"
    fi
else
    # On Linux, download SDK source
    mkdir -p "$SDKS"
    cd "$SDKS"
    rm -rf libdragon libdragon-trunk libdragon.tar.gz 2>/dev/null
    
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

cd "$HOME" || cd /tmp

if $IS_MAC; then
    # macOS: Use Docker + libdragon CLI (official recommended method)
    info "N64 toolchain for macOS requires Docker"
    
    # Check for Docker
    if ! command -v docker >/dev/null 2>&1; then
        if [[ -d "/Applications/Docker.app" ]]; then
            warn "Docker installed but not in PATH"
            info "Opening Docker Desktop..."
            open -a Docker
            sleep 5
        else
            fail "Docker not installed"
            info "Install Docker Desktop from: https://docker.com/products/docker-desktop"
            info "Then re-run this script"
        fi
    fi
    
    # Check if Docker is running
    if command -v docker >/dev/null 2>&1; then
        if ! check_docker_running; then
            info "Docker not running, attempting to start..."
            if start_docker; then
                ok "Docker started"
            else
                warn "Could not start Docker automatically"
                info "Please start Docker Desktop manually and re-run"
            fi
        else
            ok "Docker running"
        fi
        
        # Check for npm/node
        if ! command -v npm >/dev/null 2>&1; then
            info "Installing Node.js..."
            brew install node >> "$LOG" 2>&1 || true
        fi
        
        if command -v npm >/dev/null 2>&1; then
            # Check if libdragon is already installed
            if ! command -v libdragon >/dev/null 2>&1; then
                info "Installing libdragon CLI..."
                npm install -g libdragon >> "$LOG" 2>&1
            fi
            
            if command -v libdragon >/dev/null 2>&1; then
                ok "libdragon CLI installed"
                
                # Create a test project dir
                mkdir -p "$COMPILERS/n64"
                cd "$COMPILERS/n64"
                
                # Check if Docker is actually running before init
                if check_docker_running; then
                    info "Initializing libdragon (downloads ~500MB Docker image)..."
                    # Use timeout to prevent hanging
                    if timeout 300 libdragon init >> "$LOG" 2>&1; then
                        ok "N64 toolchain ready (via Docker)"
                    else
                        # Try alternative: just pull the Docker image
                        info "Trying direct Docker pull..."
                        if docker pull ghcr.io/dragonminded/libdragon:latest >> "$LOG" 2>&1; then
                            ok "N64 Docker image pulled"
                            info "Usage: cd project && libdragon init && libdragon make"
                        else
                            warn "libdragon init incomplete"
                            info "Try manually: cd ~/retro-dev/compilers/n64 && libdragon init"
                        fi
                    fi
                else
                    warn "Docker not running - skipping libdragon init"
                    info "Start Docker Desktop, then run: cd ~/retro-dev/compilers/n64 && libdragon init"
                fi
            else
                fail "libdragon CLI install"
                info "Try manually: npm install -g libdragon"
            fi
        else
            fail "Node.js not found"
            info "Install: brew install node"
        fi
    fi
    
    add_path "# N64 dev uses Docker: cd project && libdragon init && libdragon make"
    
else
    # Linux: Download prebuilt toolchain (faster, no Docker needed)
    rm -rf "$COMPILERS/n64" 2>/dev/null
    mkdir -p "$COMPILERS/n64"
    cd "$COMPILERS/n64"
    
    TC_URL="https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz"
    info "Downloading prebuilt N64 toolchain..."
    if dl "$TC_URL" tc.tar.gz; then
        tar xzf tc.tar.gz >> "$LOG" 2>&1
        rm -f tc.tar.gz
        add_path "export N64_INST=\"$COMPILERS/n64\"; export PATH=\"\$N64_INST/bin:\$PATH\""
        ok "N64 toolchain (mips64-elf-gcc)"
    else
        fail "N64 toolchain download"
    fi
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
        ok "DevkitPro installer downloaded"
        # Try to auto-install (requires password)
        info "Installing DevkitPro (may require password)..."
        if sudo installer -pkg "$COMPILERS/devkitpro/devkitpro.pkg" -target / >> "$LOG" 2>&1; then
            ok "DevkitPro installed"
            # Install GBA/NDS toolchains
            if command -v dkp-pacman >/dev/null 2>&1; then
                info "Installing GBA/NDS toolchains..."
                sudo dkp-pacman -Sy --noconfirm gba-dev nds-dev >> "$LOG" 2>&1 && ok "GBA/NDS toolchains" || warn "Some toolchains failed"
            fi
        else
            warn "Auto-install failed"
            info "Run manually: sudo installer -pkg $COMPILERS/devkitpro/devkitpro.pkg -target /"
        fi
    else
        fail "DevkitPro download"
    fi
else
    if dl "https://apt.devkitpro.org/install-devkitpro-pacman" dkp-install.sh; then
        chmod +x dkp-install.sh
        info "Installing DevkitPro..."
        if sudo ./dkp-install.sh >> "$LOG" 2>&1; then
            ok "DevkitPro installed"
        else
            warn "DevkitPro install script"
            info "Try: sudo ./dkp-install.sh"
        fi
    else
        fail "DevkitPro"
    fi
fi
add_path "export DEVKITPRO=\"/opt/devkitpro\"; export DEVKITARM=\"\$DEVKITPRO/devkitARM\"; export PATH=\"\$DEVKITARM/bin:\$PATH\""

# ============================================================================
step "GBDK-2020"
# ============================================================================

cd "$HOME" || cd /tmp
mkdir -p "$SDKS"
cd "$SDKS"
rm -rf gbdk gbdk-4.3.0 gbdk.tar.gz gbdk.zip 2>/dev/null

# Use correct URL based on platform
if $IS_MAC; then
    GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-macos.tar.gz"
else
    GB_URL="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz"
fi

if dl "$GB_URL" gbdk.tar.gz; then
    tar xzf gbdk.tar.gz >> "$LOG" 2>&1
    # Handle different archive structures
    [[ -d "gbdk-4.3.0" ]] && mv gbdk-4.3.0 gbdk
    rm -f gbdk.tar.gz
    if [[ -d "gbdk" ]] && [[ -f "gbdk/bin/lcc" || -f "gbdk/bin/lcc.exe" ]]; then
        $IS_MAC && xattr -dr com.apple.quarantine gbdk 2>/dev/null
        chmod +x gbdk/bin/* 2>/dev/null
        ok "GBDK-2020"
    else
        warn "GBDK extracted but binaries not found"
    fi
else
    fail "GBDK-2020"
fi
add_path "export GBDK=\"$SDKS/gbdk\"; export PATH=\"\$GBDK/bin:\$PATH\""

# ============================================================================
step "ASSEMBLERS"
# ============================================================================

cd "$HOME" || cd /tmp

# RGBDS
if $IS_MAC; then
    if command -v rgbasm >/dev/null 2>&1; then
        ok "RGBDS (via brew)"
    else
        brew install rgbds >> "$LOG" 2>&1 && ok "RGBDS" || fail "RGBDS"
    fi
else
    mkdir -p "$TOOLS/rgbds"
    cd "$TOOLS/rgbds"
    if dl "https://github.com/gbdev/rgbds/releases/download/v0.8.0/rgbds-0.8.0-linux-x86_64.tar.xz" rgbds.tar.xz; then
        tar xJf rgbds.tar.xz >> "$LOG" 2>&1
        chmod +x rgbasm rgblink rgbfix rgbgfx 2>/dev/null
        rm -f rgbds.tar.xz
        ok "RGBDS"
    else
        fail "RGBDS"
    fi
    add_path "export PATH=\"$TOOLS/rgbds:\$PATH\""
fi

# ASM6F - build from source properly
cd "$HOME" || cd /tmp
mkdir -p "$TOOLS/asm6"
cd "$TOOLS/asm6"
rm -f asm6f asm6f.c 2>/dev/null

info "Building ASM6F from source..."
# Download the real asm6f source
if dl "https://raw.githubusercontent.com/freem/asm6f/main/asm6f.c" asm6f.c; then
    if cc -O3 -w -o asm6f asm6f.c 2>>"$LOG"; then
        chmod +x asm6f
        ok "ASM6F"
    else
        fail "ASM6F compile"
    fi
else
    # Create a working stub as fallback
    cat > asm6f.c << 'ASM6STUB'
#include <stdio.h>
int main(int c, char**v) {
    printf("ASM6F stub - download full version:\n");
    printf("  git clone https://github.com/freem/asm6f\n");
    printf("  cd asm6f && cc -O3 asm6f.c -o asm6f\n");
    return 1;
}
ASM6STUB
    cc -O3 -w -o asm6f asm6f.c 2>/dev/null
    warn "ASM6F (stub only)"
    info "Get full version: github.com/freem/asm6f"
fi
rm -f asm6f.c
add_path "export PATH=\"$TOOLS/asm6:\$PATH\""

# WLA-DX
if $IS_MAC; then
    if command -v wla-z80 >/dev/null 2>&1; then
        ok "WLA-DX (via brew)"
    else
        brew install wla-dx >> "$LOG" 2>&1 && ok "WLA-DX" || fail "WLA-DX"
    fi
else
    mkdir -p "$TOOLS"
    cd "$TOOLS"
    rm -rf wla-dx-10.6 wla.tar.gz 2>/dev/null
    if dl "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz" wla.tar.gz; then
        tar xzf wla.tar.gz >> "$LOG" 2>&1
        cd wla-dx-10.6
        mkdir -p build && cd build
        if cmake .. -DCMAKE_BUILD_TYPE=Release >> "$LOG" 2>&1 && make -j$NCPU >> "$LOG" 2>&1; then
            ok "WLA-DX"
        else
            fail "WLA-DX build"
        fi
        rm -f "$TOOLS/wla.tar.gz"
    else
        fail "WLA-DX download"
    fi
    add_path "export PATH=\"$TOOLS/wla-dx-10.6/build/binaries:\$PATH\""
fi

# DASM - FIXED for Apple Silicon
cd "$HOME" || cd /tmp
mkdir -p "$SDKS/atari"
cd "$SDKS/atari"
rm -f dasm dasm.tar.gz dasm.zip 2>/dev/null

info "Installing DASM..."

if $IS_MAC; then
    if $IS_ARM; then
        # Apple Silicon: Build from source (no ARM64 binary available)
        info "Building DASM for Apple Silicon..."
        rm -rf dasm-src dasm-2.20.14.1 2>/dev/null
        if dl "https://github.com/dasm-assembler/dasm/archive/refs/tags/2.20.14.1.tar.gz" dasm-src.tar.gz; then
            tar xzf dasm-src.tar.gz >> "$LOG" 2>&1
            cd dasm-2.20.14.1/src
            if make >> "$LOG" 2>&1; then
                cp dasm "$SDKS/atari/"
                chmod +x "$SDKS/atari/dasm"
                cd "$SDKS/atari"
                rm -rf dasm-2.20.14.1 dasm-src.tar.gz
                ok "DASM (built for ARM64)"
            else
                fail "DASM build"
            fi
        else
            fail "DASM source download"
        fi
    else
        # Intel Mac: Use prebuilt binary
        DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz"
        if dl "$DASM_URL" dasm.tar.gz; then
            tar xzf dasm.tar.gz >> "$LOG" 2>&1
            chmod +x dasm 2>/dev/null
            xattr -dr com.apple.quarantine dasm 2>/dev/null
            rm -f dasm.tar.gz
            ok "DASM"
        else
            fail "DASM download"
        fi
    fi
else
    # Linux
    DASM_URL="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz"
    if dl "$DASM_URL" dasm.tar.gz; then
        tar xzf dasm.tar.gz >> "$LOG" 2>&1
        chmod +x dasm 2>/dev/null
        rm -f dasm.tar.gz
        ok "DASM"
    else
        fail "DASM download"
    fi
fi
add_path "export PATH=\"$SDKS/atari:\$PATH\""

# ============================================================================
step "GENESIS/SNES SDKS"
# ============================================================================

cd "$HOME" || cd /tmp
mkdir -p "$SDKS"
cd "$SDKS"
rm -rf sgdk SGDK-2.00 sgdk.tar.gz 2>/dev/null

if dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz; then
    tar xzf sgdk.tar.gz >> "$LOG" 2>&1
    mv SGDK-2.00 sgdk 2>/dev/null
    rm -f sgdk.tar.gz
    ok "SGDK"
else
    fail "SGDK"
fi
add_path "export SGDK=\"$SDKS/sgdk\""

cd "$HOME" || cd /tmp
cd "$SDKS"
rm -rf pvsneslib pvsneslib-master pvs.zip 2>/dev/null

if dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip; then
    unzip -qo pvs.zip >> "$LOG" 2>&1
    mv pvsneslib-master pvsneslib 2>/dev/null
    rm -f pvs.zip
    ok "PVSnesLib"
else
    fail "PVSnesLib"
fi
add_path "export PVSNESLIB=\"$SDKS/pvsneslib\""

# ============================================================================
step "ROM HACKING TOOLS"
# ============================================================================

cd "$HOME" || cd /tmp
rm -rf "$TOOLS/flips" 2>/dev/null
mkdir -p "$TOOLS/flips"
cd "$TOOLS/flips"

# Flips v198 (latest)
info "Installing Flips..."
if $IS_MAC; then
    FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-mac.zip"
else
    FLIPS_URL="https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip"
fi

if dl "$FLIPS_URL" flips.zip; then
    unzip -qo flips.zip >> "$LOG" 2>&1
    $IS_MAC && xattr -dr com.apple.quarantine . 2>/dev/null
    chmod +x flips* Flips* 2>/dev/null
    rm -f flips.zip
    ok "Flips"
else
    # Build from source as fallback
    info "Building Flips from source..."
    cd "$TOOLS"
    rm -rf Flips-master flips-src.tar.gz 2>/dev/null
    if dl "https://github.com/Alcaro/Flips/archive/refs/heads/master.tar.gz" flips-src.tar.gz; then
        tar xzf flips-src.tar.gz >> "$LOG" 2>&1
        cd Flips-master
        if $IS_MAC; then
            # macOS build
            if make CFLAGS="-O3 -std=c++11" >> "$LOG" 2>&1; then
                cp flips "$TOOLS/flips/"
                ok "Flips (built)"
            else
                fail "Flips build"
            fi
        else
            # Linux build
            if ./make-linux.sh >> "$LOG" 2>&1; then
                cp flips "$TOOLS/flips/"
                ok "Flips (built)"
            else
                fail "Flips build"
            fi
        fi
        cd "$TOOLS"
        rm -rf Flips-master flips-src.tar.gz
    else
        fail "Flips"
    fi
fi
add_path "export PATH=\"$TOOLS/flips:\$PATH\""

# ============================================================================
step "EMULATORS"
# ============================================================================

cd "$HOME" || cd /tmp
mkdir -p "$EMUS"
cd "$EMUS"

# mGBA 0.10.5 (latest)
info "Installing mGBA..."
if $IS_MAC; then
    rm -f mgba.dmg 2>/dev/null
    if dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-macos.dmg" mgba.dmg; then
        hdiutil attach mgba.dmg -nobrowse >> "$LOG" 2>&1
        cp -R /Volumes/mGBA*/mGBA.app "$EMUS" 2>/dev/null
        hdiutil detach /Volumes/mGBA* >> "$LOG" 2>&1
        xattr -dr com.apple.quarantine "$EMUS/mGBA.app" 2>/dev/null
        rm -f mgba.dmg
        ok "mGBA 0.10.5"
    else
        fail "mGBA"
    fi
else
    if dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-appimage-x64.appimage" mGBA.AppImage; then
        chmod +x mGBA.AppImage
        ok "mGBA 0.10.5"
    else
        fail "mGBA"
    fi
fi

# Ares v146 (latest)
cd "$EMUS"
rm -f ares.zip 2>/dev/null

info "Installing Ares..."
if $IS_MAC; then
    ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-macos-universal.zip"
else
    ARES_URL="https://github.com/ares-emulator/ares/releases/download/v146/ares-linux-x86_64.zip"
fi

if dl "$ARES_URL" ares.zip; then
    unzip -qo ares.zip >> "$LOG" 2>&1
    $IS_MAC && xattr -dr com.apple.quarantine ares* Ares* 2>/dev/null
    chmod +x ares*/ares Ares.app/Contents/MacOS/ares 2>/dev/null
    rm -f ares.zip
    ok "Ares v146"
else
    fail "Ares"
fi

# ============================================================================
step "MODERN ENGINES"
# ============================================================================

cd "$HOME" || cd /tmp
mkdir -p "$TOOLS"
cd "$TOOLS"

# Raylib
if $IS_MAC; then
    if brew list raylib >/dev/null 2>&1; then
        ok "Raylib (via brew)"
    else
        brew install raylib >> "$LOG" 2>&1 && ok "Raylib" || fail "Raylib"
    fi
else
    rm -rf raylib raylib-5.5 raylib.tar.gz 2>/dev/null
    if dl "https://github.com/raysan5/raylib/archive/refs/tags/5.5.tar.gz" raylib.tar.gz; then
        tar xzf raylib.tar.gz >> "$LOG" 2>&1
        rm -f raylib.tar.gz
        ok "Raylib source"
    else
        fail "Raylib"
    fi
fi

# Godot 4.3
cd "$TOOLS"
rm -f godot.zip 2>/dev/null

info "Installing Godot..."
if $IS_MAC; then
    GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip"
else
    GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
fi

if dl "$GODOT_URL" godot.zip; then
    unzip -qo godot.zip >> "$LOG" 2>&1
    $IS_MAC && xattr -dr com.apple.quarantine Godot* 2>/dev/null
    chmod +x Godot* 2>/dev/null
    rm -f godot.zip
    ok "Godot 4.3"
else
    fail "Godot"
fi

# ============================================================================
step "ENVIRONMENT SETUP"
# ============================================================================

cd "$HOME" || cd /tmp

cat > "$INSTALL_DIR/env.sh" << 'ENVEOF'
#!/bin/bash
# Cat's Tweaker v1.9 Environment
export RETRO_DEV="$HOME/retro-dev"
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export DEVKITPPC="$DEVKITPRO/devkitPPC"
export GBDK="$RETRO_DEV/sdks/gbdk"
export SGDK="$RETRO_DEV/sdks/sgdk"
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"

# Linux: native N64 toolchain
if [[ -d "$RETRO_DEV/compilers/n64/bin" ]]; then
    export N64_INST="$RETRO_DEV/compilers/n64"
    export PATH="$N64_INST/bin:$PATH"
fi

# Add all tool paths
export PATH="$DEVKITARM/bin:$GBDK/bin:$PATH"
export PATH="$RETRO_DEV/tools/asm6:$PATH"
export PATH="$RETRO_DEV/tools/flips:$PATH"
export PATH="$RETRO_DEV/tools/rgbds:$PATH"
export PATH="$RETRO_DEV/tools/wla-dx-10.6/build/binaries:$PATH"
export PATH="$RETRO_DEV/sdks/atari:$PATH"

echo ""
echo "  🐱 CAT'S TWEAKER v1.9 environment loaded! 🎮"
echo ""
echo "  Development Commands:"
echo "    N64 (macOS): cd project && libdragon init && libdragon make"
echo "    N64 (Linux): mips64-elf-gcc --version"
echo "    GB/GBC:      lcc --version"
echo "    GBA/NDS:     arm-none-eabi-gcc --version"
echo "    NES:         asm6f input.asm output.nes"
echo "    Atari:       dasm input.asm -f3 -ooutput.bin"
echo ""
ENVEOF
chmod +x "$INSTALL_DIR/env.sh"
ok "Environment script"

# Add to shell RC
add_path ""
add_path "# Cat's Tweaker v1.9"
add_path "source \"$INSTALL_DIR/env.sh\" 2>/dev/null"

# ============================================================================
# COMPLETE
# ============================================================================

echo ""
printf "${G}  ╔═══════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}  ║${RST}  ${W}✨ CAT'S TWEAKER v1.9 INSTALLATION COMPLETE! ✨${RST}               ${G}║${RST}\n"
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
printf "${C}  Quick Test Commands:${RST}\n"
echo "    source ~/retro-dev/env.sh"
echo "    lcc --version          # GB/GBC compiler"
echo "    dasm                   # Atari assembler"
echo "    rgbasm --version       # GB assembler"
echo ""
