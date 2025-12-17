#!/bin/bash
#===============================================================================
#   CAT'S TWEAKER - FIX SCRIPT (NO GITHUB)
#   Fixes: N64 Toolchain + Ares Emulator
#   Sources: GNU FTP, Sourceware, Flatpak
#===============================================================================

G=$'\033[0;32m'
Y=$'\033[0;33m'
C=$'\033[0;36m'
M=$'\033[0;35m'
RST=$'\033[0m'

INSTALL_DIR="$HOME/retro-dev"
N64_INST="$INSTALL_DIR/compilers/n64"
EMUS="$INSTALL_DIR/emulators"
BUILD_DIR="/tmp/n64-toolchain-build"
LOG="$INSTALL_DIR/fix.log"
NCPU=$(nproc 2>/dev/null || echo 4)

# Toolchain versions
BINUTILS_V="2.42"
GCC_V="14.1.0"
NEWLIB_V="4.4.0.20231231"
GMP_V="6.3.0"
MPFR_V="4.2.1"
MPC_V="1.3.1"

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${Y}[✗]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }

mkdir -p "$INSTALL_DIR"
: > "$LOG"

cat << 'EOF'

    ╔═══════════════════════════════════════════════════╗
    ║   🐱 CAT'S TWEAKER - FIX SCRIPT                   ║
    ║   Fixing: N64 Toolchain + Ares Emulator           ║
    ║   Sources: GNU/Sourceware/Flatpak (no GitHub)     ║
    ╚═══════════════════════════════════════════════════╝

EOF

#===============================================================================
echo -e "\n${M}▸ FIX 1: N64 TOOLCHAIN (mips64-elf-gcc)${RST}"
echo -e "${C}  Building from GNU FTP + Sourceware (30-60 min)${RST}\n"
#===============================================================================

# Install build deps
info "Installing build dependencies..."
sudo apt-get install -y build-essential texinfo libgmp-dev libmpfr-dev libmpc-dev \
    flex bison zlib1g-dev >> "$LOG" 2>&1 && ok "Build deps" || fail "Build deps"

mkdir -p "$BUILD_DIR" "$N64_INST"
cd "$BUILD_DIR"

export PATH="$N64_INST/bin:$PATH"

# Download sources from official GNU/Sourceware mirrors
info "Downloading binutils $BINUTILS_V from ftp.gnu.org..."
wget -q --show-progress -c "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_V}.tar.xz" && ok "binutils" || fail "binutils"

info "Downloading GCC $GCC_V from ftp.gnu.org..."
wget -q --show-progress -c "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_V}/gcc-${GCC_V}.tar.xz" && ok "gcc" || fail "gcc"

info "Downloading newlib $NEWLIB_V from sourceware.org..."
wget -q --show-progress -c "https://sourceware.org/pub/newlib/newlib-${NEWLIB_V}.tar.gz" && ok "newlib" || fail "newlib"

info "Downloading GMP $GMP_V..."
wget -q --show-progress -c "https://ftp.gnu.org/gnu/gmp/gmp-${GMP_V}.tar.xz" && ok "gmp" || fail "gmp"

info "Downloading MPFR $MPFR_V..."
wget -q --show-progress -c "https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_V}.tar.xz" && ok "mpfr" || fail "mpfr"

info "Downloading MPC $MPC_V..."
wget -q --show-progress -c "https://ftp.gnu.org/gnu/mpc/mpc-${MPC_V}.tar.gz" && ok "mpc" || fail "mpc"

# Extract all
info "Extracting sources..."
for f in *.tar.*; do tar xf "$f" >> "$LOG" 2>&1; done
ok "Extraction complete"

# Link GCC deps into gcc source tree
cd "gcc-${GCC_V}"
ln -sf "../gmp-${GMP_V}" gmp
ln -sf "../mpfr-${MPFR_V}" mpfr
ln -sf "../mpc-${MPC_V}" mpc
cd ..

#--- BUILD BINUTILS ---
info "Building binutils for mips64-elf..."
mkdir -p build-binutils && cd build-binutils
../binutils-${BINUTILS_V}/configure \
    --prefix="$N64_INST" \
    --target=mips64-elf \
    --with-cpu=vr4300 \
    --disable-nls \
    --disable-werror >> "$LOG" 2>&1

make -j$NCPU >> "$LOG" 2>&1 && make install >> "$LOG" 2>&1 && ok "binutils installed" || fail "binutils build"
cd ..

#--- BUILD GCC STAGE 1 ---
info "Building GCC stage 1 (bootstrap)..."
mkdir -p build-gcc && cd build-gcc
../gcc-${GCC_V}/configure \
    --prefix="$N64_INST" \
    --target=mips64-elf \
    --with-arch=vr4300 \
    --with-tune=vr4300 \
    --enable-languages=c,c++ \
    --without-headers \
    --with-newlib \
    --disable-libssp \
    --disable-multilib \
    --disable-shared \
    --disable-threads \
    --disable-nls >> "$LOG" 2>&1

make -j$NCPU all-gcc >> "$LOG" 2>&1 && make install-gcc >> "$LOG" 2>&1 && ok "GCC stage 1" || fail "GCC stage 1"
cd ..

#--- BUILD NEWLIB ---
info "Building newlib C library..."
mkdir -p build-newlib && cd build-newlib
../newlib-${NEWLIB_V}/configure \
    --prefix="$N64_INST" \
    --target=mips64-elf \
    --with-cpu=vr4300 \
    --disable-newlib-supplied-syscalls >> "$LOG" 2>&1

make -j$NCPU >> "$LOG" 2>&1 && make install >> "$LOG" 2>&1 && ok "newlib installed" || fail "newlib build"
cd ..

#--- BUILD GCC STAGE 2 ---
info "Building GCC stage 2 (final)..."
cd build-gcc
make -j$NCPU >> "$LOG" 2>&1 && make install >> "$LOG" 2>&1 && ok "GCC complete!" || fail "GCC stage 2"
cd ..

# Verify installation
if [[ -x "$N64_INST/bin/mips64-elf-gcc" ]]; then
    ok "N64 toolchain ready: $N64_INST"
    info "Version: $($N64_INST/bin/mips64-elf-gcc --version | head -1)"
else
    fail "N64 toolchain failed - check $LOG"
fi

#===============================================================================
echo -e "\n${M}▸ FIX 2: ARES EMULATOR (via Flatpak)${RST}"
#===============================================================================

mkdir -p "$EMUS"

# Install flatpak if needed
if ! command -v flatpak >/dev/null 2>&1; then
    info "Installing Flatpak..."
    sudo apt-get install -y flatpak >> "$LOG" 2>&1
fi

# Add flathub repo
info "Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >> "$LOG" 2>&1

# Install ares
info "Installing Ares from Flathub..."
flatpak install -y flathub dev.ares.ares >> "$LOG" 2>&1 && {
    ok "Ares emulator installed"
    info "Run: flatpak run dev.ares.ares"
} || {
    fail "Ares Flatpak install"
    info "Try manually: flatpak install flathub dev.ares.ares"
}

#===============================================================================
echo -e "\n${M}▸ ENVIRONMENT SETUP${RST}"
#===============================================================================

# Update bashrc
if ! grep -q "N64_INST=" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << ENVRC

# N64 Development Toolchain (Cat's Tweaker)
export N64_INST="$N64_INST"
export PATH="\$N64_INST/bin:\$PATH"
ENVRC
    ok "Added to ~/.bashrc"
fi

# Update env.sh
if [[ -f "$INSTALL_DIR/env.sh" ]]; then
    sed -i 's|N64_INST=.*|N64_INST="'"$N64_INST"'"|' "$INSTALL_DIR/env.sh" 2>/dev/null
    ok "Updated env.sh"
fi

#===============================================================================
cat << EOF

    ${G}╔═══════════════════════════════════════════════════╗
    ║   ✨ FIX COMPLETE!                                 ║
    ╠═══════════════════════════════════════════════════╣${RST}
    ${C}N64 GCC:${RST}   $N64_INST/bin/mips64-elf-gcc
    ${C}Ares:${RST}      flatpak run dev.ares.ares
    ${C}Activate:${RST}  source ~/.bashrc
    ${C}Test:${RST}      mips64-elf-gcc --version
    ${C}Log:${RST}       $LOG
    ${G}╚═══════════════════════════════════════════════════╝${RST}

                       /\\_____/\\
                      /  o   o  \\
                     ( ==  ^  == )
                      )  ~nya~  (
                     (           )
                    ( (  )   (  ) )
                   (__(__)___(__)__)

EOF

# Cleanup prompt
read -p "${Y}Clean up build files (~2GB)? [y/N]:${RST} " cleanup
[[ "$cleanup" =~ ^[Yy]$ ]] && {
    rm -rf "$BUILD_DIR"
    ok "Build directory cleaned"
}

echo ""
info "Run: source ~/.bashrc"
