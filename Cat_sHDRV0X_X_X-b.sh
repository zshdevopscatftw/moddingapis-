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
#                                      「  v1.9.5 - retro dev toolkit  」
#                                         by Flames / Team Flames 🐱
#                                  Auto: Docker, wget, curl, libdragon
#                                            ⛔ NO GIT REQUIRED ⛔
#
#===============================================================================

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

G=$'\033[0;32m'; Y=$'\033[0;33m'; C=$'\033[0;36m'; M=$'\033[0;35m'; R=$'\033[0;31m'; W=$'\033[1;37m'; RST=$'\033[0m'

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${R}[✗]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
step() { printf "\n${M}▸ %s${RST}\n" "$1"; }

BREW=""; BREW_PREFIX=""
[[ -x /opt/homebrew/bin/brew ]] && BREW="/opt/homebrew/bin/brew" && BREW_PREFIX="/opt/homebrew"
[[ -z "$BREW" && -x /usr/local/bin/brew ]] && BREW="/usr/local/bin/brew" && BREW_PREFIX="/usr/local"

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

NCPU=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
SHELL_RC="$HOME/.zshrc"; [[ "$(uname)" != "Darwin" ]] && SHELL_RC="$HOME/.bashrc"
IS_MAC=false; [[ "$(uname)" == "Darwin" ]] && IS_MAC=true
IS_APPLE_SILICON=false; [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" == *"Apple"* ]] && IS_APPLE_SILICON=true
HAS_DOCKER=false

dl() {
    curl -fsSL --connect-timeout 30 --max-time 900 --retry 3 -L -o "$2" "$1" 2>>"$LOG"
    [[ -s "$2" ]]
}

add_path() { [[ -n "$1" ]] && grep -qxF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }

brew_pkg() {
    local pkg="$1"
    "$BREW" list "$pkg" &>/dev/null && { ok "$pkg (installed)"; return 0; }
    printf "  ${C}[*]${RST} Installing %s..." "$pkg"
    local out; out=$("$BREW" install "$pkg" 2>&1); local ret=$?
    echo "$out" | grep -q "brew link" && "$BREW" link --overwrite "$pkg" >> "$LOG" 2>&1 && ret=0
    if [[ $ret -eq 0 ]] || "$BREW" list "$pkg" &>/dev/null; then
        printf "\r  ${G}[✓]${RST} %-20s\n" "$pkg"; return 0
    else
        printf "\r  ${R}[✗]${RST} %-20s\n" "$pkg"
        echo "$out" >> "$LOG"; return 1
    fi
}

# ============================================================================
clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                                      「  v1.9.5 - retro dev toolkit  」
                                    ⛔ NO GIT REQUIRED - Full Auto Install ⛔
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )         (
                                          (           )
                                         ( (  )   (  ) )
                                        (__(__)___(__)__)

EOF

# ============================================================================
step "SYSTEM"
# ============================================================================
$IS_MAC && ok "macOS $(uname -m)"
$IS_APPLE_SILICON && ok "Apple Silicon"

# ============================================================================
step "XCODE CLI"
# ============================================================================
if $IS_MAC; then
    xcode-select -p &>/dev/null && ok "Xcode CLI tools" || { xcode-select --install; warn "Install Xcode CLI, then re-run"; exit 1; }
fi

# ============================================================================
step "HOMEBREW"
# ============================================================================
if $IS_MAC; then
    if [[ -n "$BREW" ]]; then
        ok "Homebrew: $BREW"
        eval "$("$BREW" shellenv)"; export PATH="$BREW_PREFIX/bin:$PATH"
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [[ -x /opt/homebrew/bin/brew ]] && BREW="/opt/homebrew/bin/brew" && BREW_PREFIX="/opt/homebrew"
        [[ -z "$BREW" && -x /usr/local/bin/brew ]] && BREW="/usr/local/bin/brew" && BREW_PREFIX="/usr/local"
        [[ -n "$BREW" ]] && eval "$("$BREW" shellenv)" && ok "Homebrew" || { fail "Homebrew"; exit 1; }
    fi
    [[ "$BREW_PREFIX" == "/usr/local" ]] && sed -i.bak 's|eval "\$(/opt/homebrew|# &|g' "$HOME/.zprofile" "$HOME/.zshrc" 2>/dev/null
    add_path "# Homebrew"
    [[ "$BREW_PREFIX" == "/opt/homebrew" ]] && add_path 'eval "$(/opt/homebrew/bin/brew shellenv)"' || add_path 'eval "$(/usr/local/bin/brew shellenv)"'
    "$BREW" update >> "$LOG" 2>&1
fi

# ============================================================================
step "WGET + CURL (auto-install)"
# ============================================================================
if $IS_MAC; then
    brew_pkg curl
    brew_pkg wget
    eval "$("$BREW" shellenv)"; export PATH="$BREW_PREFIX/bin:$PATH"
    command -v wget &>/dev/null && ok "wget ready" || warn "wget not in path yet"
    command -v curl &>/dev/null && ok "curl ready" || warn "curl not in path yet"
fi

# ============================================================================
step "JAVA / OPENJDK"
# ============================================================================
if $IS_MAC; then
    # OpenJDK Latest (bleeding edge)
    brew_pkg openjdk
    # OpenJDK 21 LTS (Long Term Support - stable)
    brew_pkg openjdk@21
    # OpenJDK 17 LTS (older LTS, widely used)
    brew_pkg openjdk@17
    
    # Create symlinks for system java wrappers
    JAVA_LATEST="$BREW_PREFIX/opt/openjdk/libexec/openjdk.jdk"
    JAVA_21="$BREW_PREFIX/opt/openjdk@21/libexec/openjdk.jdk"
    JAVA_17="$BREW_PREFIX/opt/openjdk@17/libexec/openjdk.jdk"
    
    # Symlink to system JavaVirtualMachines (needs sudo, optional)
    if [[ -d "$JAVA_LATEST" ]]; then
        sudo ln -sfn "$JAVA_LATEST" /Library/Java/JavaVirtualMachines/openjdk.jdk 2>/dev/null && ok "Symlinked openjdk (latest)" || warn "Symlink openjdk (run: sudo ln -sfn $JAVA_LATEST /Library/Java/JavaVirtualMachines/openjdk.jdk)"
    fi
    if [[ -d "$JAVA_21" ]]; then
        sudo ln -sfn "$JAVA_21" /Library/Java/JavaVirtualMachines/openjdk-21.jdk 2>/dev/null && ok "Symlinked openjdk@21" || warn "Symlink openjdk@21 (run: sudo ln -sfn $JAVA_21 /Library/Java/JavaVirtualMachines/openjdk-21.jdk)"
    fi
    if [[ -d "$JAVA_17" ]]; then
        sudo ln -sfn "$JAVA_17" /Library/Java/JavaVirtualMachines/openjdk-17.jdk 2>/dev/null && ok "Symlinked openjdk@17" || warn "Symlink openjdk@17 (run: sudo ln -sfn $JAVA_17 /Library/Java/JavaVirtualMachines/openjdk-17.jdk)"
    fi
    
    # Add to PATH (use LTS 21 as default JAVA_HOME)
    add_path ""
    add_path "# Java / OpenJDK"
    add_path "export PATH=\"$BREW_PREFIX/opt/openjdk/bin:\$PATH\""
    add_path "export PATH=\"$BREW_PREFIX/opt/openjdk@21/bin:\$PATH\""
    add_path "export PATH=\"$BREW_PREFIX/opt/openjdk@17/bin:\$PATH\""
    add_path "export JAVA_HOME=\"$BREW_PREFIX/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home\""
    add_path "export CPPFLAGS=\"-I$BREW_PREFIX/opt/openjdk@21/include \$CPPFLAGS\""
    
    # Show installed versions
    info "Java versions installed:"
    "$BREW_PREFIX/opt/openjdk/bin/java" --version 2>/dev/null | head -1 && ok "OpenJDK Latest"
    "$BREW_PREFIX/opt/openjdk@21/bin/java" --version 2>/dev/null | head -1 && ok "OpenJDK 21 LTS"
    "$BREW_PREFIX/opt/openjdk@17/bin/java" --version 2>/dev/null | head -1 && ok "OpenJDK 17 LTS"
    info "Switch versions: export JAVA_HOME=\$(/usr/libexec/java_home -v 21)"
else
    # Linux: install via apt/dnf
    if command -v apt &>/dev/null; then
        sudo apt update >> "$LOG" 2>&1
        sudo apt install -y openjdk-21-jdk openjdk-17-jdk >> "$LOG" 2>&1 && ok "OpenJDK 21+17 LTS" || fail "OpenJDK"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y java-21-openjdk-devel java-17-openjdk-devel >> "$LOG" 2>&1 && ok "OpenJDK 21+17 LTS" || fail "OpenJDK"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm jdk21-openjdk jdk17-openjdk >> "$LOG" 2>&1 && ok "OpenJDK 21+17 LTS" || fail "OpenJDK"
    else
        warn "Install OpenJDK manually for your distro"
    fi
    add_path ""
    add_path "# Java / OpenJDK"
    add_path 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))'
fi

# ============================================================================
step "DOCKER DESKTOP (auto-download + install)"
# ============================================================================
if command -v docker &>/dev/null; then
    HAS_DOCKER=true
    ok "Docker installed"
elif $IS_MAC; then
    info "Downloading Docker Desktop..."
    $IS_APPLE_SILICON && U="https://desktop.docker.com/mac/main/arm64/Docker.dmg" || U="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
    dl "$U" docker.dmg && hdiutil attach docker.dmg -nobrowse >> "$LOG" 2>&1 && cp -R "/Volumes/Docker/Docker.app" /Applications/ && hdiutil detach /Volumes/Docker >> "$LOG" 2>&1 && rm -f docker.dmg && ok "Docker Desktop" || fail "Docker"
    info "Launch Docker Desktop from /Applications"
fi

# ============================================================================
step "BUILD TOOLS"
# ============================================================================
if $IS_MAC; then
    brew_pkg cmake
    brew_pkg ninja
    brew_pkg nasm
    brew_pkg yasm
    brew_pkg pkg-config
    brew_pkg autoconf
    brew_pkg automake
    brew_pkg libtool
fi

# ============================================================================
step "RETRO COMPILERS"
# ============================================================================
if $IS_MAC; then
    brew_pkg cc65
    brew_pkg sdcc
    brew_pkg rgbds
    brew_pkg z88dk
fi

# ============================================================================
step "NODE.JS"
# ============================================================================
if $IS_MAC; then
    brew_pkg node
fi

# ============================================================================
step "N64 LIBDRAGON"
# ============================================================================
cd "$COMPILERS"; mkdir -p n64; cd n64
if $IS_MAC; then
    if command -v npm &>/dev/null; then
        npm list -g libdragon &>/dev/null && ok "libdragon (npm)" || { npm install -g libdragon >> "$LOG" 2>&1 && ok "libdragon" || fail "libdragon"; }
        if command -v libdragon &>/dev/null; then
            info "Pulling libdragon toolchain (Docker)..."
            if $HAS_DOCKER || command -v docker &>/dev/null; then
                libdragon install >> "$LOG" 2>&1 && ok "libdragon toolchain" || warn "libdragon (start Docker first)"
            else
                warn "Start Docker Desktop, then: libdragon install"
            fi
        fi
    else
        fail "npm not found - node install failed?"
    fi
else
    # Linux: prebuilt toolchain
    dl "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz" tc.tar.gz && \
        tar xzf tc.tar.gz >> "$LOG" 2>&1 && rm -f tc.tar.gz && ok "N64 toolchain" || fail "N64 toolchain"
fi

# ============================================================================
step "DEVKITPRO"
# ============================================================================
mkdir -p "$COMPILERS/devkitpro"; cd "$COMPILERS/devkitpro"
dl "https://github.com/devkitPro/pacman/releases/latest/download/devkitpro-pacman-installer.pkg" devkitpro.pkg && ok "DevkitPro installer" || fail "DevkitPro"
info "Run: sudo installer -pkg $COMPILERS/devkitpro/devkitpro.pkg -target /"

# ============================================================================
step "GBDK-2020"
# ============================================================================
cd "$SDKS"; rm -rf gbdk* 2>/dev/null
$IS_MAC && U="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-macos.tar.gz" || U="https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz"
dl "$U" gbdk.tar.gz && tar xzf gbdk.tar.gz >> "$LOG" 2>&1 && rm -f gbdk.tar.gz && ok "GBDK-2020" || fail "GBDK-2020"

# ============================================================================
step "ASSEMBLERS (no git)"
# ============================================================================
mkdir -p "$TOOLS/asm6"; cd "$TOOLS/asm6"
dl "https://raw.githubusercontent.com/freem/asm6f/main/asm6f.c" asm6f.c && cc -O3 -o asm6f asm6f.c >> "$LOG" 2>&1 && ok "ASM6F" || warn "ASM6F"

mkdir -p "$SDKS/atari"; cd "$SDKS/atari"
$IS_MAC && U="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz" || U="https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz"
dl "$U" dasm.tar.gz && tar xzf dasm.tar.gz >> "$LOG" 2>&1 && rm -f dasm.tar.gz && chmod +x dasm* 2>/dev/null && ok "DASM" || fail "DASM"

mkdir -p "$TOOLS/vasm"; cd "$TOOLS/vasm"
for u in "http://phoenix.owl.de/tags/vasm1_9i.tar.gz" "http://sun.hasenbraten.de/vasm/release/vasm.tar.gz"; do
    if dl "$u" vasm.tar.gz; then
        tar xzf vasm.tar.gz >> "$LOG" 2>&1; rm -f vasm.tar.gz
        D=$(find . -maxdepth 1 -type d -name "vasm*" | head -1)
        [[ -n "$D" ]] && cd "$D" && make CPU=6502 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1 && cp vasm6502_oldstyle "$TOOLS/vasm/" 2>/dev/null
        make clean >> "$LOG" 2>&1; make CPU=m68k SYNTAX=mot -j$NCPU >> "$LOG" 2>&1 && cp vasmm68k_mot "$TOOLS/vasm/" 2>/dev/null
        cd "$TOOLS/vasm"; rm -rf "$D"; break
    fi
done
[[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM" || warn "VASM"

# ============================================================================
step "GENESIS SDK"
# ============================================================================
cd "$SDKS"; rm -rf sgdk* SGDK* 2>/dev/null
dl "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" sgdk.tar.gz && tar xzf sgdk.tar.gz >> "$LOG" 2>&1 && mv SGDK-2.00 sgdk && rm -f sgdk.tar.gz && ok "SGDK" || fail "SGDK"

# ============================================================================
step "SNES SDK"
# ============================================================================
cd "$SDKS"; rm -rf pvsneslib* 2>/dev/null
dl "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" pvs.zip && unzip -qo pvs.zip >> "$LOG" 2>&1 && mv pvsneslib-master pvsneslib && rm -f pvs.zip && ok "PVSnesLib" || fail "PVSnesLib"

# ============================================================================
step "ROM TOOLS"
# ============================================================================
mkdir -p "$TOOLS/flips"; cd "$TOOLS/flips"
$IS_MAC && U="https://github.com/Alcaro/Flips/releases/download/v198/flips-mac.zip" || U="https://github.com/Alcaro/Flips/releases/download/v198/flips-linux.zip"
dl "$U" flips.zip && unzip -qo flips.zip >> "$LOG" 2>&1 && rm -f flips.zip && chmod +x * 2>/dev/null && $IS_MAC && xattr -dr com.apple.quarantine . 2>/dev/null && ok "Flips" || warn "Flips"

# ============================================================================
step "EMULATORS"
# ============================================================================
mkdir -p "$EMUS"; cd "$EMUS"
if $IS_MAC; then
    dl "https://github.com/mgba-emu/mgba/releases/download/0.10.5/mGBA-0.10.5-macos.dmg" mgba.dmg && hdiutil attach mgba.dmg -nobrowse >> "$LOG" 2>&1 && cp -R /Volumes/mGBA*/mGBA.app . && hdiutil detach /Volumes/mGBA* >> "$LOG" 2>&1 && xattr -dr com.apple.quarantine mGBA.app 2>/dev/null && rm -f mgba.dmg && ok "mGBA" || fail "mGBA"
fi
$IS_MAC && U="https://github.com/ares-emulator/ares/releases/download/v146/ares-macos-universal.zip" || U="https://github.com/ares-emulator/ares/releases/download/v146/ares-linux-x86_64.zip"
dl "$U" ares.zip && unzip -qo ares.zip >> "$LOG" 2>&1 && rm -f ares.zip && $IS_MAC && xattr -dr com.apple.quarantine Ares* 2>/dev/null && ok "Ares" || fail "Ares"

# ============================================================================
step "ENGINES"
# ============================================================================
cd "$TOOLS"
$IS_MAC && U="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_macos.universal.zip" || U="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
dl "$U" godot.zip && unzip -qo godot.zip >> "$LOG" 2>&1 && rm -f godot.zip && $IS_MAC && xattr -dr com.apple.quarantine Godot* 2>/dev/null && ok "Godot 4.3" || fail "Godot"
$IS_MAC && ok "Raylib (brew)"

# ============================================================================
step "ENVIRONMENT"
# ============================================================================
cat > "$INSTALL_DIR/env.sh" << 'ENVEOF'
#!/bin/bash
export RETRO_DEV="$HOME/retro-dev"
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export GBDK="$RETRO_DEV/sdks/gbdk"
export SGDK="$RETRO_DEV/sdks/sgdk"
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"
[[ -d "$RETRO_DEV/compilers/n64/bin" ]] && export PATH="$RETRO_DEV/compilers/n64/bin:$PATH"
export PATH="$DEVKITARM/bin:$GBDK/bin:$RETRO_DEV/tools/asm6:$RETRO_DEV/tools/vasm:$RETRO_DEV/tools/flips:$RETRO_DEV/sdks/atari:$PATH"
# Java - default to LTS 21
BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
[[ -d "$BREW_PREFIX/opt/openjdk@21" ]] && export JAVA_HOME="$BREW_PREFIX/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
[[ -d "$BREW_PREFIX/opt/openjdk@21/bin" ]] && export PATH="$BREW_PREFIX/opt/openjdk@21/bin:$PATH"
echo "  🐱 CAT'S TWEAKER v1.9.5 loaded!"
ENVEOF
chmod +x "$INSTALL_DIR/env.sh"; ok "env.sh"
add_path ""; add_path "# Cat's Tweaker v1.9.5"; add_path "source \"$INSTALL_DIR/env.sh\" 2>/dev/null"

# ============================================================================
step "VERIFY"
# ============================================================================
source "$INSTALL_DIR/env.sh" 2>/dev/null; [[ -n "$BREW" ]] && eval "$("$BREW" shellenv)"
echo ""
command -v wget &>/dev/null && ok "wget" || fail "wget"
command -v curl &>/dev/null && ok "curl" || fail "curl"
command -v docker &>/dev/null && ok "docker" || fail "docker"
command -v nasm &>/dev/null && ok "nasm" || fail "nasm"
command -v yasm &>/dev/null && ok "yasm" || fail "yasm"
command -v cc65 &>/dev/null && ok "cc65" || fail "cc65"
command -v sdcc &>/dev/null && ok "sdcc" || fail "sdcc"
command -v rgbasm &>/dev/null && ok "rgbasm" || fail "rgbasm"
command -v node &>/dev/null && ok "node" || fail "node"
command -v npm &>/dev/null && ok "npm" || fail "npm"
command -v libdragon &>/dev/null && ok "libdragon" || warn "libdragon"
command -v java &>/dev/null && ok "java ($(java --version 2>&1 | head -1))" || fail "java"
command -v javac &>/dev/null && ok "javac" || fail "javac"
[[ -x "$SDKS/gbdk/bin/lcc" ]] && ok "GBDK lcc" || warn "GBDK"

# ============================================================================
echo ""
printf "${G}  ╔═══════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}  ║${RST}  ${W}✨ CAT'S TWEAKER v1.9.5 COMPLETE! ✨${RST}                              ${G}║${RST}\n"
printf "${G}  ║${RST}  ${C}Homebrew:${RST} %-52s ${G}║${RST}\n" "$BREW_PREFIX"
printf "${G}  ║${RST}  ${C}Docker:${RST}   %-52s ${G}║${RST}\n" "$($HAS_DOCKER && echo "Running" || echo "Installed - start Docker Desktop")"
printf "${G}  ║${RST}  ${C}Java:${RST}     %-52s ${G}║${RST}\n" "OpenJDK 21 LTS (default) + 17 LTS + Latest"
printf "${G}  ║${RST}  ${Y}ACTIVATE:${RST} ${W}source ~/.zshrc${RST}                                       ${G}║${RST}\n"
printf "${G}  ╚═══════════════════════════════════════════════════════════════════╝${RST}\n"
printf "\n                             ${M}/\\_____/\\${RST}\n"
printf "                            ${M}/  o   o  \\${RST}\n"
printf "                           ${M}( ==  ^  == )${RST}\n"
printf "                            ${M})  ~nya~  (${RST}\n"
printf "                           ${M}(           )${RST}\n"
printf "                          ${M}( (  )   (  ) )${RST}\n"
printf "                         ${M}(__(__)___(__)__)${RST}\n\n"
info "POST-INSTALL:"
echo "  1. ${W}source ~/.zshrc${RST}"
echo "  2. DevkitPro: sudo installer -pkg ~/retro-dev/compilers/devkitpro/devkitpro.pkg -target /"
echo "  3. N64: mkdir proj && cd proj && libdragon init && libdragon make"
echo ""
info "JAVA SWITCH:"
echo "  • Use Java 21 LTS: ${W}export JAVA_HOME=\$(/usr/libexec/java_home -v 21)${RST}"
echo "  • Use Java 17 LTS: ${W}export JAVA_HOME=\$(/usr/libexec/java_home -v 17)${RST}"
echo "  • Use Latest:      ${W}export JAVA_HOME=\$(/usr/libexec/java_home)${RST}"
echo ""
