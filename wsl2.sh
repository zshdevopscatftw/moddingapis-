#!/bin/bash
#===============================================================================
# WSL2 RETRO-MODERN SDK INSTALLER (1930-2025)
# For WSL2 with systemd=false
# Installs: Clang, Homebrew, Python 3.13, all retro/modern game SDKs
# Uses: wget/curl only (no git)
# Author: Flames / Team Flames
#===============================================================================

set -e

#===============================================================================
# COLORS & GLOBALS
#===============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/retro-sdk"
DOWNLOAD_DIR="$INSTALL_DIR/downloads"
TOOLS_DIR="$INSTALL_DIR/tools"
SDK_DIR="$INSTALL_DIR/sdks"

# WSL2 Detection
IS_WSL=false
IS_WSL2=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
    if grep -qi "WSL2" /proc/version 2>/dev/null || [[ -d /run/WSL ]]; then
        IS_WSL2=true
    fi
fi

# Systemd check
HAS_SYSTEMD=false
if pidof systemd &>/dev/null; then
    HAS_SYSTEMD=true
fi

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_era() { 
    echo -e "\n${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA} $1${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}\n"
}

download_file() {
    local url="$1"
    local output="$2"
    log_info "Downloading: $(basename "$output")"
    if command -v wget &>/dev/null; then
        wget -q --show-progress --no-check-certificate -O "$output" "$url" 2>/dev/null || \
        wget -q -O "$output" "$url" 2>/dev/null || \
        curl -fsSL -o "$output" "$url" 2>/dev/null || true
    else
        curl -fsSL -o "$output" "$url" 2>/dev/null || true
    fi
}

extract_archive() {
    local file="$1"
    local dest="$2"
    [[ ! -f "$file" ]] && return 1
    case "$file" in
        *.tar.gz|*.tgz) tar -xzf "$file" -C "$dest" 2>/dev/null ;;
        *.tar.bz2|*.tbz2) tar -xjf "$file" -C "$dest" 2>/dev/null ;;
        *.tar.xz|*.txz) tar -xJf "$file" -C "$dest" 2>/dev/null ;;
        *.zip) unzip -qo "$file" -d "$dest" 2>/dev/null ;;
        *.7z) 7z x -y "$file" -o"$dest" 2>/dev/null ;;
        *.lha|*.lzh) lha x "$file" -w="$dest" 2>/dev/null ;;
        *) log_warn "Unknown archive: $file" ;;
    esac
}

#===============================================================================
# BANNER
#===============================================================================
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
╔═══════════════════════════════════════════════════════════════════════════════╗
║        ██╗    ██╗███████╗██╗     ██████╗     ███████╗██████╗ ██╗  ██╗         ║
║        ██║    ██║██╔════╝██║     ╚════██╗    ██╔════╝██╔══██╗██║ ██╔╝         ║
║        ██║ █╗ ██║███████╗██║      █████╔╝    ███████╗██║  ██║█████╔╝          ║
║        ██║███╗██║╚════██║██║     ██╔═══╝     ╚════██║██║  ██║██╔═██╗          ║
║        ╚███╔███╔╝███████║███████╗███████╗    ███████║██████╔╝██║  ██╗         ║
║         ╚══╝╚══╝ ╚══════╝╚══════╝╚══════╝    ╚══════╝╚═════╝ ╚═╝  ╚═╝         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║              RETRO-MODERN SDK INSTALLER v2.0 (1930-2025)                      ║
║                   WSL2 Edition - No Systemd Required                          ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║  Tools: Python 3.13 | Clang/LLVM 18 | Homebrew | CMake | Ninja               ║
║  Eras:  Pre-Electronic → 8-bit → 16-bit → 32-bit → HD → Modern               ║
║  Range: Atari 2600 to PlayStation 5                                           ║
╚═══════════════════════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
    
    echo -e "${YELLOW}System Detection:${NC}"
    echo -e "  WSL:      ${GREEN}$IS_WSL${NC}"
    echo -e "  WSL2:     ${GREEN}$IS_WSL2${NC}"
    echo -e "  Systemd:  ${GREEN}$HAS_SYSTEMD${NC}"
    echo -e "  User:     ${GREEN}$(whoami)${NC}"
    echo -e "  Arch:     ${GREEN}$(uname -m)${NC}"
    echo ""
}

#===============================================================================
# DIRECTORIES SETUP
#===============================================================================
setup_directories() {
    log_info "Creating directory structure..."
    mkdir -p "$DOWNLOAD_DIR"
    mkdir -p "$TOOLS_DIR"/{llvm,python,cmake,ninja,homebrew}
    mkdir -p "$SDK_DIR"/{pre-electronic,8bit,16bit,32bit,64bit,modern}
    mkdir -p "$SDK_DIR"/8bit/{atari2600,atari8bit,c64,nes,zxspectrum,msx,gameboy}
    mkdir -p "$SDK_DIR"/16bit/{genesis,snes,gba,amiga,neogeo}
    mkdir -p "$SDK_DIR"/32bit/{ps1,n64,saturn,dreamcast}
    mkdir -p "$SDK_DIR"/64bit/{ps3,wii,wiiu,3ds,vita}
    mkdir -p "$SDK_DIR"/modern/{switch,ps4,ps5,xbox}
    log_success "Directories created"
}

#===============================================================================
# APT DEPENDENCIES (WSL2)
#===============================================================================
install_apt_deps() {
    log_era "INSTALLING SYSTEM DEPENDENCIES (APT)"
    
    log_info "Updating package lists..."
    if [[ $EUID -eq 0 ]]; then
        apt-get update -qq
    else
        sudo apt-get update -qq
    fi
    
    local packages=(
        # Build essentials
        build-essential
        gcc
        g++
        make
        autoconf
        automake
        libtool
        pkg-config
        # Compression
        p7zip-full
        unzip
        xz-utils
        lhasa
        # Network
        wget
        curl
        ca-certificates
        # Python build deps
        libssl-dev
        zlib1g-dev
        libbz2-dev
        libreadline-dev
        libsqlite3-dev
        libncursesw5-dev
        libxml2-dev
        libxslt1-dev
        libffi-dev
        liblzma-dev
        tk-dev
        # Dev libs
        libcurl4-openssl-dev
        libpng-dev
        libjpeg-dev
        libfreetype6-dev
        libsdl2-dev
        libsdl2-image-dev
        libsdl2-mixer-dev
        # Tools
        cmake
        ninja-build
        ccache
        gdb
        # For Homebrew
        file
        git
        procps
        locales
    )
    
    log_info "Installing ${#packages[@]} packages..."
    if [[ $EUID -eq 0 ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${packages[@]}" 2>/dev/null || true
    else
        DEBIAN_FRONTEND=noninteractive sudo apt-get install -y -qq "${packages[@]}" 2>/dev/null || true
    fi
    
    log_success "System dependencies installed"
}

#===============================================================================
# HOMEBREW (WSL2 Compatible - Non-Root)
#===============================================================================
install_homebrew() {
    log_era "INSTALLING HOMEBREW"
    
    if [[ $EUID -eq 0 ]]; then
        log_warn "Homebrew cannot run as root - skipping"
        log_info "Run this script as non-root user for Homebrew support"
        return
    fi
    
    if command -v brew &>/dev/null; then
        log_success "Homebrew already installed"
        return
    fi
    
    log_info "Installing Homebrew for Linux/WSL2..."
    
    # Download and run installer non-interactively
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        log_warn "Homebrew install failed, trying manual method..."
        
        # Manual installation
        mkdir -p "$HOME/.linuxbrew"
        download_file "https://github.com/Homebrew/brew/archive/refs/heads/master.zip" \
            "$DOWNLOAD_DIR/homebrew.zip"
        extract_archive "$DOWNLOAD_DIR/homebrew.zip" "$HOME/.linuxbrew"
        mv "$HOME/.linuxbrew/brew-master"/* "$HOME/.linuxbrew/" 2>/dev/null || true
        rm -rf "$HOME/.linuxbrew/brew-master"
    }
    
    # Setup Homebrew environment
    if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        BREW_PREFIX="/home/linuxbrew/.linuxbrew"
    elif [[ -d "$HOME/.linuxbrew" ]]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
        BREW_PREFIX="$HOME/.linuxbrew"
    fi
    
    if command -v brew &>/dev/null; then
        log_success "Homebrew installed at $BREW_PREFIX"
        
        # Install some useful packages via brew
        log_info "Installing Homebrew packages..."
        brew install gcc make cmake ninja 2>/dev/null || true
    else
        log_warn "Homebrew installation incomplete"
    fi
}

#===============================================================================
# PYTHON 3.13
#===============================================================================
install_python313() {
    log_era "INSTALLING PYTHON 3.13"
    
    local py_ver="3.13.1"
    local py_installed=false
    
    # Check if already installed
    if command -v python3.13 &>/dev/null; then
        log_success "Python 3.13 already installed: $(python3.13 --version)"
        return
    fi
    
    # Method 1: deadsnakes PPA (Ubuntu/Debian)
    log_info "Trying deadsnakes PPA..."
    if command -v add-apt-repository &>/dev/null; then
        if [[ $EUID -eq 0 ]]; then
            add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null || true
            apt-get update -qq 2>/dev/null || true
            apt-get install -y python3.13 python3.13-venv python3.13-dev python3.13-distutils 2>/dev/null && py_installed=true
        else
            sudo add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null || true
            sudo apt-get update -qq 2>/dev/null || true
            sudo apt-get install -y python3.13 python3.13-venv python3.13-dev python3.13-distutils 2>/dev/null && py_installed=true
        fi
    fi
    
    if [[ "$py_installed" == "true" ]]; then
        log_success "Python 3.13 installed via PPA"
        return
    fi
    
    # Method 2: Build from source
    log_info "Building Python ${py_ver} from source..."
    download_file "https://www.python.org/ftp/python/${py_ver}/Python-${py_ver}.tgz" \
        "$DOWNLOAD_DIR/Python-${py_ver}.tgz"
    
    if [[ -f "$DOWNLOAD_DIR/Python-${py_ver}.tgz" ]]; then
        mkdir -p "$TOOLS_DIR/python/src"
        extract_archive "$DOWNLOAD_DIR/Python-${py_ver}.tgz" "$TOOLS_DIR/python/src"
        
        cd "$TOOLS_DIR/python/src/Python-${py_ver}"
        
        log_info "Configuring Python..."
        ./configure \
            --prefix="$TOOLS_DIR/python/python313" \
            --enable-optimizations \
            --with-lto \
            --with-ensurepip=install \
            2>/dev/null || ./configure --prefix="$TOOLS_DIR/python/python313" --with-ensurepip=install
        
        log_info "Compiling Python (this may take a while)..."
        make -j$(nproc) 2>/dev/null || make
        make install
        
        cd - >/dev/null
        
        # Create symlinks
        ln -sf "$TOOLS_DIR/python/python313/bin/python3.13" "$TOOLS_DIR/python/python313/bin/python"
        ln -sf "$TOOLS_DIR/python/python313/bin/pip3.13" "$TOOLS_DIR/python/python313/bin/pip"
        
        log_success "Python ${py_ver} built and installed"
    else
        log_error "Failed to download Python source"
    fi
}

#===============================================================================
# CLANG/LLVM
#===============================================================================
install_clang() {
    log_era "INSTALLING CLANG/LLVM 18"
    
    local llvm_ver="18.1.8"
    
    # Check if already installed
    if command -v clang-18 &>/dev/null || command -v clang &>/dev/null; then
        local ver=$(clang --version 2>/dev/null | head -1)
        log_success "Clang already installed: $ver"
    fi
    
    # Method 1: LLVM apt repository
    log_info "Installing LLVM via official repository..."
    
    download_file "https://apt.llvm.org/llvm.sh" "$DOWNLOAD_DIR/llvm.sh"
    
    if [[ -f "$DOWNLOAD_DIR/llvm.sh" ]]; then
        chmod +x "$DOWNLOAD_DIR/llvm.sh"
        if [[ $EUID -eq 0 ]]; then
            bash "$DOWNLOAD_DIR/llvm.sh" 18 all 2>/dev/null || true
        else
            sudo bash "$DOWNLOAD_DIR/llvm.sh" 18 all 2>/dev/null || true
        fi
    fi
    
    # Check if installed via apt
    if command -v clang-18 &>/dev/null; then
        log_success "Clang 18 installed via apt"
        
        # Create unversioned symlinks
        if [[ $EUID -eq 0 ]]; then
            update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 2>/dev/null || true
            update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 2>/dev/null || true
        else
            sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 2>/dev/null || true
            sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 2>/dev/null || true
        fi
        return
    fi
    
    # Method 2: Download prebuilt binaries
    log_info "Downloading prebuilt LLVM ${llvm_ver}..."
    local arch=$(uname -m)
    local llvm_url=""
    
    if [[ "$arch" == "x86_64" ]]; then
        llvm_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_ver}/clang+llvm-${llvm_ver}-x86_64-linux-gnu-ubuntu-18.04.tar.xz"
    elif [[ "$arch" == "aarch64" ]]; then
        llvm_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_ver}/clang+llvm-${llvm_ver}-aarch64-linux-gnu.tar.xz"
    fi
    
    if [[ -n "$llvm_url" ]]; then
        download_file "$llvm_url" "$DOWNLOAD_DIR/llvm-${llvm_ver}.tar.xz"
        
        if [[ -f "$DOWNLOAD_DIR/llvm-${llvm_ver}.tar.xz" ]]; then
            log_info "Extracting LLVM..."
            extract_archive "$DOWNLOAD_DIR/llvm-${llvm_ver}.tar.xz" "$TOOLS_DIR/llvm"
            
            # Find extracted directory
            local llvm_dir=$(find "$TOOLS_DIR/llvm" -maxdepth 1 -type d -name "clang+llvm*" | head -1)
            if [[ -d "$llvm_dir" ]]; then
                mv "$llvm_dir"/* "$TOOLS_DIR/llvm/" 2>/dev/null || true
                log_success "LLVM ${llvm_ver} installed to $TOOLS_DIR/llvm"
            fi
        fi
    fi
}

#===============================================================================
# ERA 1: PRE-ELECTRONIC (1930-1945)
#===============================================================================
install_era_pre_electronic() {
    log_era "ERA 1: PRE-ELECTRONIC (1930-1945)"
    local dest="$SDK_DIR/pre-electronic"
    
    # Plankalkül Interpreter
    log_info "Creating Plankalkül interpreter (Zuse 1945)..."
    cat > "$dest/plankaluel.py" << 'PYEOF'
#!/usr/bin/env python3
"""
Plankalkül Interpreter - Konrad Zuse's 1945 Programming Language
First high-level programming language ever designed
"""

class Plankaluel:
    def __init__(self):
        self.vars = {}
        self.results = []
    
    def parse_2d_notation(self, text):
        """Parse Zuse's 2D variable notation: V | subscript | type"""
        lines = text.strip().split('\n')
        if len(lines) >= 3:
            return {
                'var': lines[0].replace('V', '').strip(),
                'subscript': lines[1].strip() if len(lines) > 1 else '0',
                'type': lines[2].strip() if len(lines) > 2 else 'S0'
            }
        return None
    
    def execute(self, statement):
        """Execute a Plankalkül statement"""
        if '=>' in statement:
            parts = statement.split('=>')
            value = self.evaluate(parts[0].strip())
            var_name = parts[1].strip()
            self.vars[var_name] = value
            return value
        return self.evaluate(statement)
    
    def evaluate(self, expr):
        try:
            return eval(expr, {"__builtins__": {}}, self.vars)
        except:
            return expr
    
    def run_program(self, program):
        for line in program.strip().split('\n'):
            if line.strip() and not line.startswith(';'):
                result = self.execute(line)
                self.results.append(result)
        return self.results

if __name__ == "__main__":
    print("Plankalkül Interpreter - Konrad Zuse (1945)")
    print("First high-level programming language")
    p = Plankaluel()
    p.execute("x => 5")
    p.execute("y => 3")
    print(f"x + y = {p.execute('x + y')}")
PYEOF
    chmod +x "$dest/plankaluel.py"
    
    # ENIAC Simulator
    log_info "Creating ENIAC simulator (1945)..."
    cat > "$dest/eniac.py" << 'PYEOF'
#!/usr/bin/env python3
"""
ENIAC Simulator - First general-purpose electronic computer (1945)
Simulates the plugboard programming paradigm
"""

class ENIAC:
    def __init__(self):
        self.accumulators = [0] * 20  # 20 ten-digit accumulators
        self.function_tables = {}     # 3 function tables
        self.program_cables = []      # Plugboard connections
        self.cycle_time = 200e-6      # 200 microseconds per cycle
        self.cycles = 0
    
    def plug(self, source, dest, operation):
        """Simulate plugging cables on the plugboard"""
        self.program_cables.append({
            'src': source,
            'dst': dest,
            'op': operation
        })
    
    def load_table(self, table_id, values):
        """Load a function table (read-only memory)"""
        self.function_tables[table_id] = values[:104]  # 104 entries max
    
    def cycle(self):
        """Execute one addition cycle"""
        for cable in self.program_cables:
            src_val = self.accumulators[cable['src']]
            op = cable['op']
            
            if op == 'A':    # Add
                self.accumulators[cable['dst']] += src_val
            elif op == 'S':  # Subtract
                self.accumulators[cable['dst']] -= src_val
            elif op == 'T':  # Transfer
                self.accumulators[cable['dst']] = src_val
            elif op == 'C':  # Clear and add
                self.accumulators[cable['dst']] = src_val
        
        self.cycles += 1
        return self.accumulators[:]
    
    def run(self, num_cycles):
        """Run for specified cycles"""
        for _ in range(num_cycles):
            self.cycle()
        return self.accumulators

if __name__ == "__main__":
    print("ENIAC Simulator - 1945")
    print("First general-purpose electronic computer")
    
    eniac = ENIAC()
    eniac.accumulators[0] = 5
    eniac.accumulators[1] = 3
    eniac.plug(0, 2, 'T')  # Transfer acc0 to acc2
    eniac.plug(1, 2, 'A')  # Add acc1 to acc2
    eniac.run(1)
    print(f"5 + 3 = {eniac.accumulators[2]}")
PYEOF
    chmod +x "$dest/eniac.py"
    
    log_success "Pre-electronic era tools created"
}

#===============================================================================
# ERA 2: 8-BIT (1975-1985)
#===============================================================================
install_era_8bit() {
    log_era "ERA 2: 8-BIT GOLDEN AGE (1975-1985)"
    local dest="$SDK_DIR/8bit"
    
    # CC65 - 6502 C Compiler
    log_info "Installing CC65 (6502: Atari, C64, NES, Apple II)..."
    download_file "https://github.com/cc65/cc65/archive/refs/tags/V2.19.tar.gz" \
        "$DOWNLOAD_DIR/cc65.tar.gz"
    
    if [[ -f "$DOWNLOAD_DIR/cc65.tar.gz" ]]; then
        extract_archive "$DOWNLOAD_DIR/cc65.tar.gz" "$dest"
        if [[ -d "$dest/cc65-2.19" ]]; then
            cd "$dest/cc65-2.19"
            make -j$(nproc) 2>/dev/null || make
            cd - >/dev/null
            log_success "CC65 built"
        fi
    fi
    
    # DASM - Atari 2600 Assembler  
    log_info "Installing DASM (Atari 2600/VCS)..."
    download_file "https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz" \
        "$DOWNLOAD_DIR/dasm.tar.gz"
    extract_archive "$DOWNLOAD_DIR/dasm.tar.gz" "$dest/atari2600" 2>/dev/null || true
    
    # z88dk - Z80 Development Kit
    log_info "Installing z88dk (Z80: ZX Spectrum, MSX, ColecoVision)..."
    download_file "https://github.com/z88dk/z88dk/releases/download/v2.3/z88dk-linux-x86_64-2.3.tgz" \
        "$DOWNLOAD_DIR/z88dk.tgz"
    extract_archive "$DOWNLOAD_DIR/z88dk.tgz" "$dest/zxspectrum" 2>/dev/null || true
    
    # RGBDS - Game Boy Assembler
    log_info "Installing RGBDS (Game Boy)..."
    download_file "https://github.com/gbdev/rgbds/releases/download/v0.7.0/rgbds-0.7.0-linux-x86_64.tar.xz" \
        "$DOWNLOAD_DIR/rgbds.tar.xz"
    mkdir -p "$dest/gameboy/rgbds"
    extract_archive "$DOWNLOAD_DIR/rgbds.tar.xz" "$dest/gameboy/rgbds" 2>/dev/null || true
    
    # GBDK-2020
    log_info "Installing GBDK-2020 (Game Boy C SDK)..."
    download_file "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz" \
        "$DOWNLOAD_DIR/gbdk.tar.gz"
    extract_archive "$DOWNLOAD_DIR/gbdk.tar.gz" "$dest/gameboy" 2>/dev/null || true
    
    # NES Template
    log_info "Creating NES development template..."
    cat > "$dest/nes/nes_template.s" << 'ASMEOF'
; NES ROM Template (ca65/cc65)
; iNES Header
.segment "HEADER"
    .byte "NES", $1A
    .byte $02            ; 32KB PRG-ROM
    .byte $01            ; 8KB CHR-ROM
    .byte $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

.segment "CODE"
RESET:
    SEI
    CLD
    LDX #$FF
    TXS
    
    ; Wait for PPU
    BIT $2002
@vwait1:
    BIT $2002
    BPL @vwait1
@vwait2:
    BIT $2002
    BPL @vwait2
    
    ; Main loop
@loop:
    JMP @loop

NMI:
    RTI
    
IRQ:
    RTI

.segment "VECTORS"
    .word NMI, RESET, IRQ

.segment "CHARS"
    ; CHR-ROM data here
ASMEOF

    # Atari 2600 Template
    log_info "Creating Atari 2600 template..."
    cat > "$dest/atari2600/atari2600_template.asm" << 'ASMEOF'
; Atari 2600 Template (DASM)
    PROCESSOR 6502
    INCLUDE "vcs.h"
    
    SEG CODE
    ORG $F000

Reset:
    SEI
    CLD
    LDX #$FF
    TXS
    LDA #0
Clear:
    STA 0,X
    DEX
    BNE Clear

MainLoop:
    ; Wait for VBLANK
    LDA #2
    STA VSYNC
    STA WSYNC
    STA WSYNC
    STA WSYNC
    LDA #0
    STA VSYNC
    
    ; 37 lines of VBLANK
    LDX #37
VBlank:
    STA WSYNC
    DEX
    BNE VBlank
    
    STA VBLANK
    
    ; 192 visible scanlines
    LDX #192
Picture:
    STA WSYNC
    DEX
    BNE Picture
    
    ; Overscan
    LDA #2
    STA VBLANK
    LDX #30
Overscan:
    STA WSYNC
    DEX
    BNE Overscan
    
    JMP MainLoop

    ORG $FFFA
    .word Reset
    .word Reset
    .word Reset
    
    END
ASMEOF
    
    log_success "8-bit era SDKs installed"
}

#===============================================================================
# ERA 3: 16-BIT (1985-1995)
#===============================================================================
install_era_16bit() {
    log_era "ERA 3: 16-BIT REVOLUTION (1985-1995)"
    local dest="$SDK_DIR/16bit"
    
    # SGDK - Sega Genesis
    log_info "Installing SGDK (Sega Genesis/Mega Drive)..."
    download_file "https://github.com/Stephane-D/SGDK/archive/refs/tags/v2.00.tar.gz" \
        "$DOWNLOAD_DIR/sgdk.tar.gz"
    extract_archive "$DOWNLOAD_DIR/sgdk.tar.gz" "$dest/genesis" 2>/dev/null || true
    
    # PVSnesLib - SNES
    log_info "Installing PVSnesLib (Super Nintendo)..."
    download_file "https://github.com/alekmaul/pvsneslib/archive/refs/heads/master.zip" \
        "$DOWNLOAD_DIR/pvsneslib.zip"
    extract_archive "$DOWNLOAD_DIR/pvsneslib.zip" "$dest/snes" 2>/dev/null || true
    
    # WLA-DX Multi-platform Assembler
    log_info "Installing WLA-DX (Multi-platform assembler)..."
    download_file "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz" \
        "$DOWNLOAD_DIR/wla-dx.tar.gz"
    mkdir -p "$dest/wla-dx"
    extract_archive "$DOWNLOAD_DIR/wla-dx.tar.gz" "$dest/wla-dx" 2>/dev/null || true
    
    # devkitARM (GBA)
    log_info "Setting up GBA development..."
    mkdir -p "$dest/gba"
    
    cat > "$dest/gba/gba_template.c" << 'CEOF'
// Game Boy Advance Template (devkitARM/libgba)
#include <gba.h>

int main(void) {
    // Set video mode 3 (240x160 bitmap)
    REG_DISPCNT = MODE_3 | BG2_ON;
    
    // Draw a red pixel at (120, 80)
    ((u16*)VRAM)[120 + 80 * 240] = RGB5(31, 0, 0);
    
    while(1) {
        VBlankIntrWait();
        
        // Read keys
        scanKeys();
        u16 keys = keysDown();
        
        if(keys & KEY_START) {
            // Start pressed
        }
    }
    
    return 0;
}
CEOF

    # SNES Template
    cat > "$dest/snes/snes_template.asm" << 'ASMEOF'
; Super Nintendo Template (WLA-DX / ca65)
.include "snes.inc"

.segment "HEADER"
    .byte "SNES TEMPLATE       "  ; 21 bytes ROM name
    .byte $20                      ; LoROM, fast
    .byte $00                      ; No battery
    .byte $07                      ; 128KB ROM
    .byte $00                      ; No RAM
    .byte $01                      ; USA
    .byte $00                      ; Developer ID
    .byte $00                      ; Version
    .word $0000                    ; Checksum complement
    .word $0000                    ; Checksum

.segment "CODE"
Reset:
    sei
    clc
    xce                 ; Native mode
    rep #$30            ; 16-bit A/X/Y
    
    lda #$0000
    sta $2100           ; Screen off
    
    ; Initialize stack
    lda #$1FFF
    tcs
    
MainLoop:
    wai
    jmp MainLoop

NMI:
    rti

.segment "VECTORS"
    ; Native vectors
    .word $0000, $0000, $0000, $0000
    .word $0000, NMI, Reset, $0000
    ; Emulation vectors
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, Reset, $0000
ASMEOF
    
    log_success "16-bit era SDKs installed"
}

#===============================================================================
# ERA 4: 32-BIT (1993-2005)
#===============================================================================
install_era_32bit() {
    log_era "ERA 4: 32-BIT 3D REVOLUTION (1993-2005)"
    local dest="$SDK_DIR/32bit"
    
    # PSn00bSDK - PlayStation 1
    log_info "Installing PSn00bSDK (PlayStation 1)..."
    download_file "https://github.com/Lameguy64/PSn00bSDK/archive/refs/heads/master.zip" \
        "$DOWNLOAD_DIR/psn00bsdk.zip"
    extract_archive "$DOWNLOAD_DIR/psn00bsdk.zip" "$dest/ps1" 2>/dev/null || true
    
    # LibDragon - Nintendo 64
    log_info "Installing LibDragon toolchain (Nintendo 64)..."
    download_file "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz" \
        "$DOWNLOAD_DIR/n64-toolchain.tar.gz"
    mkdir -p "$dest/n64"
    extract_archive "$DOWNLOAD_DIR/n64-toolchain.tar.gz" "$dest/n64" 2>/dev/null || true
    
    # N64 Template
    cat > "$dest/n64/n64_template.c" << 'CEOF'
// Nintendo 64 Template (libdragon)
#include <libdragon.h>

int main(void) {
    display_init(RESOLUTION_320x240, DEPTH_32_BPP, 2, GAMMA_NONE, FILTERS_RESAMPLE);
    dfs_init(DFS_DEFAULT_LOCATION);
    rdpq_init();
    controller_init();
    
    while(1) {
        surface_t *disp = display_get();
        
        rdpq_attach_clear(disp, NULL);
        rdpq_detach_show();
        
        controller_scan();
        struct controller_data keys = get_keys_down();
        
        if(keys.c[0].start) {
            // Start pressed
        }
    }
    
    return 0;
}
CEOF
    
    # KallistiOS - Dreamcast
    log_info "Installing KallistiOS (Dreamcast)..."
    download_file "https://github.com/KallistiOS/KallistiOS/archive/refs/heads/master.zip" \
        "$DOWNLOAD_DIR/kos.zip"
    extract_archive "$DOWNLOAD_DIR/kos.zip" "$dest/dreamcast" 2>/dev/null || true
    
    # Dreamcast Template
    cat > "$dest/dreamcast/dc_template.c" << 'CEOF'
// Dreamcast Template (KallistiOS)
#include <kos.h>

int main(int argc, char *argv[]) {
    vid_set_mode(DM_640x480, PM_RGB565);
    pvr_init_defaults();
    
    while(1) {
        pvr_wait_ready();
        pvr_scene_begin();
        pvr_list_begin(PVR_LIST_OP_POLY);
        // Draw here
        pvr_list_finish();
        pvr_scene_finish();
        
        maple_device_t *cont = maple_enum_type(0, MAPLE_FUNC_CONTROLLER);
        if(cont) {
            cont_state_t *state = maple_dev_status(cont);
            if(state && state->buttons & CONT_START)
                break;
        }
    }
    
    return 0;
}
CEOF

    # Saturn Template
    cat > "$dest/saturn/saturn_template.c" << 'CEOF'
// Sega Saturn Template (Jo Engine)
#include <jo/jo.h>

void game_loop(void) {
    jo_printf(10, 10, "Hello Saturn!");
}

void jo_main(void) {
    jo_core_init(JO_COLOR_Black);
    jo_core_add_callback(game_loop);
    jo_core_run();
}
CEOF
    
    log_success "32-bit era SDKs installed"
}

#===============================================================================
# ERA 5: HD ERA (2005-2015)
#===============================================================================
install_era_64bit() {
    log_era "ERA 5: HD CONSOLE ERA (2005-2015)"
    local dest="$SDK_DIR/64bit"
    
    # VitaSDK
    log_info "Installing VitaSDK (PS Vita)..."
    download_file "https://github.com/vitasdk/autobuilds/releases/download/master-linux-v2.469/vitasdk-x86_64-linux-gnu-2024-04-27_18-28-53.tar.bz2" \
        "$DOWNLOAD_DIR/vitasdk.tar.bz2"
    mkdir -p "$dest/vita"
    extract_archive "$DOWNLOAD_DIR/vitasdk.tar.bz2" "$dest/vita" 2>/dev/null || true
    
    # Vita Template
    cat > "$dest/vita/vita_template.c" << 'CEOF'
// PS Vita Template (VitaSDK)
#include <psp2/kernel/processmgr.h>
#include <psp2/ctrl.h>
#include <vita2d.h>

int main() {
    vita2d_init();
    vita2d_set_clear_color(RGBA8(0, 0, 0, 255));
    
    SceCtrlData ctrl;
    
    while(1) {
        sceCtrlPeekBufferPositive(0, &ctrl, 1);
        if(ctrl.buttons & SCE_CTRL_START) break;
        
        vita2d_start_drawing();
        vita2d_clear_screen();
        vita2d_end_drawing();
        vita2d_swap_buffers();
    }
    
    vita2d_fini();
    sceKernelExitProcess(0);
    return 0;
}
CEOF
    
    # 3DS Template
    log_info "Setting up Nintendo 3DS development..."
    mkdir -p "$dest/3ds"
    cat > "$dest/3ds/3ds_template.c" << 'CEOF'
// Nintendo 3DS Template (devkitARM/libctru)
#include <3ds.h>
#include <citro2d.h>

int main() {
    gfxInitDefault();
    C3D_Init(C3D_DEFAULT_CMDBUF_SIZE);
    C2D_Init(C2D_DEFAULT_MAX_OBJECTS);
    C2D_Prepare();
    
    C3D_RenderTarget* top = C2D_CreateScreenTarget(GFX_TOP, GFX_LEFT);
    
    while(aptMainLoop()) {
        hidScanInput();
        if(hidKeysDown() & KEY_START) break;
        
        C3D_FrameBegin(C3D_FRAME_SYNCDRAW);
        C2D_TargetClear(top, C2D_Color32(0, 0, 0, 255));
        C2D_SceneBegin(top);
        C3D_FrameEnd(0);
    }
    
    C2D_Fini();
    C3D_Fini();
    gfxExit();
    return 0;
}
CEOF

    # Wii Template
    log_info "Setting up Wii development..."
    mkdir -p "$dest/wii"
    cat > "$dest/wii/wii_template.c" << 'CEOF'
// Nintendo Wii Template (devkitPPC/libogc)
#include <gccore.h>
#include <wiiuse/wpad.h>

static void *xfb = NULL;
static GXRModeObj *rmode = NULL;

int main() {
    VIDEO_Init();
    WPAD_Init();
    
    rmode = VIDEO_GetPreferredMode(NULL);
    xfb = MEM_K0_TO_K1(SYS_AllocateFramebuffer(rmode));
    
    VIDEO_Configure(rmode);
    VIDEO_SetNextFramebuffer(xfb);
    VIDEO_SetBlack(false);
    VIDEO_Flush();
    VIDEO_WaitVSync();
    
    while(1) {
        WPAD_ScanPads();
        if(WPAD_ButtonsDown(0) & WPAD_BUTTON_HOME) break;
        VIDEO_WaitVSync();
    }
    
    return 0;
}
CEOF

    # PS3 Template
    log_info "Setting up PlayStation 3 development..."
    mkdir -p "$dest/ps3"
    cat > "$dest/ps3/ps3_template.c" << 'CEOF'
// PlayStation 3 Template (PSL1GHT)
#include <psl1ght/lv2.h>
#include <io/pad.h>

int main() {
    ioPadInit(7);
    
    padInfo padinfo;
    padData paddata;
    
    while(1) {
        ioPadGetInfo(&padinfo);
        if(padinfo.status[0]) {
            ioPadGetData(0, &paddata);
            if(paddata.BTN_START) break;
        }
    }
    
    return 0;
}
CEOF
    
    log_success "HD era SDKs installed"
}

#===============================================================================
# ERA 6: MODERN (2013-2025)
#===============================================================================
install_era_modern() {
    log_era "ERA 6: MODERN CONSOLE ERA (2013-2025)"
    local dest="$SDK_DIR/modern"
    
    # libnx - Nintendo Switch
    log_info "Installing libnx (Nintendo Switch)..."
    download_file "https://github.com/devkitPro/libnx/archive/refs/heads/master.zip" \
        "$DOWNLOAD_DIR/libnx.zip"
    extract_archive "$DOWNLOAD_DIR/libnx.zip" "$dest/switch" 2>/dev/null || true
    
    # Switch Template
    cat > "$dest/switch/switch_template.c" << 'CEOF'
// Nintendo Switch Template (libnx)
#include <switch.h>

int main(int argc, char* argv[]) {
    consoleInit(NULL);
    
    padConfigureInput(1, HidNpadStyleSet_NpadStandard);
    PadState pad;
    padInitializeDefault(&pad);
    
    printf("Hello Nintendo Switch!\n");
    
    while(appletMainLoop()) {
        padUpdate(&pad);
        if(padGetButtonsDown(&pad) & HidNpadButton_Plus) break;
        consoleUpdate(NULL);
    }
    
    consoleExit(NULL);
    return 0;
}
CEOF

    # OpenOrbis - PS4
    log_info "Installing OpenOrbis (PlayStation 4)..."
    download_file "https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain/archive/refs/heads/master.zip" \
        "$DOWNLOAD_DIR/openorbis.zip"
    extract_archive "$DOWNLOAD_DIR/openorbis.zip" "$dest/ps4" 2>/dev/null || true
    
    # PS4 Template
    cat > "$dest/ps4/ps4_template.c" << 'CEOF'
// PlayStation 4 Template (OpenOrbis)
#include <orbis/libkernel.h>
#include <orbis/Sysmodule.h>
#include <orbis/Pad.h>

int main() {
    sceSysmoduleLoadModule(ORBIS_SYSMODULE_PAD);
    
    OrbisPadData padData;
    int pad = scePadOpen(0x1, 0, 0, NULL);
    
    while(1) {
        scePadReadState(pad, &padData);
        if(padData.buttons & ORBIS_PAD_BUTTON_OPTIONS) break;
        sceKernelUsleep(16666);
    }
    
    scePadClose(pad);
    return 0;
}
CEOF

    # PS5 Template
    cat > "$dest/ps5/ps5_template.c" << 'CEOF'
// PlayStation 5 Template
// DualSense Adaptive Triggers Example

typedef struct {
    uint8_t rightTrigger[10];
    uint8_t leftTrigger[10];
    uint8_t hapticIntensity;
    uint8_t triggerMode;  // 0=off, 1=rigid, 2=pulse
} DualSenseEffect;

int main() {
    // PS5 uses similar APIs to PS4 with DualSense extensions
    DualSenseEffect effect = {0};
    effect.triggerMode = 2;  // Pulse mode
    
    while(1) {
        // Game loop with DualSense features
    }
    
    return 0;
}
CEOF

    # SDL2 (Cross-platform)
    log_info "Installing SDL2..."
    download_file "https://github.com/libsdl-org/SDL/releases/download/release-2.30.3/SDL2-2.30.3.tar.gz" \
        "$DOWNLOAD_DIR/sdl2.tar.gz"
    mkdir -p "$dest/sdl2"
    extract_archive "$DOWNLOAD_DIR/sdl2.tar.gz" "$dest/sdl2" 2>/dev/null || true
    
    # Godot Engine
    log_info "Downloading Godot Engine..."
    download_file "https://github.com/godotengine/godot/releases/download/4.2.2-stable/Godot_v4.2.2-stable_linux.x86_64.zip" \
        "$DOWNLOAD_DIR/godot.zip"
    mkdir -p "$dest/godot"
    extract_archive "$DOWNLOAD_DIR/godot.zip" "$dest/godot" 2>/dev/null || true
    
    log_success "Modern era SDKs installed"
}

#===============================================================================
# ENVIRONMENT SETUP
#===============================================================================
setup_environment() {
    log_era "CONFIGURING ENVIRONMENT"
    
    cat > "$INSTALL_DIR/env.sh" << ENVEOF
#!/bin/bash
# WSL2 Retro-Modern SDK Environment
# Source this file: source ~/retro-sdk/env.sh

export RETRO_SDK_HOME="$INSTALL_DIR"
export RETRO_SDK_VERSION="2.0"

# Python 3.13
if [[ -d "\$RETRO_SDK_HOME/tools/python/python313/bin" ]]; then
    export PATH="\$RETRO_SDK_HOME/tools/python/python313/bin:\$PATH"
fi

# LLVM/Clang
if [[ -d "\$RETRO_SDK_HOME/tools/llvm/bin" ]]; then
    export PATH="\$RETRO_SDK_HOME/tools/llvm/bin:\$PATH"
fi

# Homebrew (if installed as non-root)
if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
    eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -d "\$HOME/.linuxbrew" ]]; then
    eval "\$(\$HOME/.linuxbrew/bin/brew shellenv)"
fi

# 8-bit SDKs
export CC65_HOME="\$RETRO_SDK_HOME/sdks/8bit/cc65-2.19"
export Z88DK="\$RETRO_SDK_HOME/sdks/8bit/zxspectrum"
export GBDK="\$RETRO_SDK_HOME/sdks/8bit/gameboy/gbdk"
[[ -d "\$CC65_HOME/bin" ]] && export PATH="\$CC65_HOME/bin:\$PATH"
[[ -d "\$GBDK/bin" ]] && export PATH="\$GBDK/bin:\$PATH"

# 16-bit SDKs
export SGDK="\$RETRO_SDK_HOME/sdks/16bit/genesis"
export PVSNESLIB="\$RETRO_SDK_HOME/sdks/16bit/snes"

# 32-bit SDKs
export N64_INST="\$RETRO_SDK_HOME/sdks/32bit/n64"
[[ -d "\$N64_INST/bin" ]] && export PATH="\$N64_INST/bin:\$PATH"

# 64-bit SDKs
export VITASDK="\$RETRO_SDK_HOME/sdks/64bit/vita"
[[ -d "\$VITASDK/bin" ]] && export PATH="\$VITASDK/bin:\$PATH"

# Convenience aliases
alias retro-info='echo "Retro-Modern SDK v\$RETRO_SDK_VERSION"; echo "Location: \$RETRO_SDK_HOME"'
alias retro-list='ls -la \$RETRO_SDK_HOME/sdks'

echo -e "\033[0;32m[✓] Retro-Modern SDK Environment Loaded\033[0m"
echo "    Platforms: atari2600 nes snes genesis n64 ps1 dreamcast gba 3ds vita switch ps4 ps5"
ENVEOF

    chmod +x "$INSTALL_DIR/env.sh"
    
    # Add to shell profile
    local shell_rc=""
    if [[ -f "$HOME/.bashrc" ]]; then
        shell_rc="$HOME/.bashrc"
    elif [[ -f "$HOME/.zshrc" ]]; then
        shell_rc="$HOME/.zshrc"
    fi
    
    if [[ -n "$shell_rc" ]]; then
        if ! grep -q "retro-sdk/env.sh" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# Retro-Modern SDK" >> "$shell_rc"
            echo "[[ -f \"$INSTALL_DIR/env.sh\" ]] && source \"$INSTALL_DIR/env.sh\"" >> "$shell_rc"
            log_info "Added to $shell_rc"
        fi
    fi
    
    log_success "Environment configured"
}

#===============================================================================
# MAIN
#===============================================================================
main() {
    show_banner
    
    echo -e "${YELLOW}Select installation:${NC}"
    echo "  1) Full install (all eras + tools)"
    echo "  2) Tools only (Python, Clang, Homebrew)"
    echo "  3) Retro only (8-bit + 16-bit)"
    echo "  4) Classic 3D (32-bit + 64-bit)"
    echo "  5) Modern only (Switch, PS4, PS5)"
    echo "  6) Custom selection"
    echo ""
    read -p "Choice [1-6]: " choice
    
    setup_directories
    
    case $choice in
        1)
            install_apt_deps
            install_homebrew
            install_python313
            install_clang
            install_era_pre_electronic
            install_era_8bit
            install_era_16bit
            install_era_32bit
            install_era_64bit
            install_era_modern
            ;;
        2)
            install_apt_deps
            install_homebrew
            install_python313
            install_clang
            ;;
        3)
            install_apt_deps
            install_era_8bit
            install_era_16bit
            ;;
        4)
            install_apt_deps
            install_era_32bit
            install_era_64bit
            ;;
        5)
            install_apt_deps
            install_era_modern
            ;;
        6)
            install_apt_deps
            read -p "Python 3.13? [Y/n]: " p; [[ ! "$p" =~ ^[Nn] ]] && install_python313
            read -p "Clang/LLVM? [Y/n]: " c; [[ ! "$c" =~ ^[Nn] ]] && install_clang
            read -p "Homebrew? [Y/n]: " b; [[ ! "$b" =~ ^[Nn] ]] && install_homebrew
            read -p "Pre-electronic (1930-45)? [y/N]: " e1; [[ "$e1" =~ ^[Yy] ]] && install_era_pre_electronic
            read -p "8-bit (1975-85)? [Y/n]: " e2; [[ ! "$e2" =~ ^[Nn] ]] && install_era_8bit
            read -p "16-bit (1985-95)? [Y/n]: " e3; [[ ! "$e3" =~ ^[Nn] ]] && install_era_16bit
            read -p "32-bit (1993-2005)? [Y/n]: " e4; [[ ! "$e4" =~ ^[Nn] ]] && install_era_32bit
            read -p "HD era (2005-15)? [Y/n]: " e5; [[ ! "$e5" =~ ^[Nn] ]] && install_era_64bit
            read -p "Modern (2013-25)? [Y/n]: " e6; [[ ! "$e6" =~ ^[Nn] ]] && install_era_modern
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
    
    setup_environment
    
    log_era "INSTALLATION COMPLETE"
    echo -e "${GREEN}SDK Location:${NC} $INSTALL_DIR"
    echo -e "${GREEN}To activate:${NC} source $INSTALL_DIR/env.sh"
    echo ""
    echo -e "${CYAN}Directory structure:${NC}"
    echo "  sdks/8bit/     - CC65, DASM, z88dk, GBDK, RGBDS"
    echo "  sdks/16bit/    - SGDK, PVSnesLib, WLA-DX"
    echo "  sdks/32bit/    - PSn00bSDK, LibDragon, KallistiOS"
    echo "  sdks/64bit/    - VitaSDK, PSL1GHT"
    echo "  sdks/modern/   - libnx, OpenOrbis, SDL2, Godot"
    echo "  tools/         - Python 3.13, LLVM/Clang"
    echo ""
    echo -e "${YELLOW}Restart your shell or run:${NC}"
    echo "  source $INSTALL_DIR/env.sh"
}

# Entry point
if [[ "$1" == "--auto" ]]; then
    show_banner
    setup_directories
    install_apt_deps
    install_homebrew
    install_python313
    install_clang
    install_era_pre_electronic
    install_era_8bit
    install_era_16bit
    install_era_32bit
    install_era_64bit
    install_era_modern
    setup_environment
elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "WSL2 Retro-Modern SDK Installer"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --auto     Full non-interactive installation"
    echo "  --help     Show this help"
    echo ""
    echo "Run without arguments for interactive mode"
else
    main
fi
