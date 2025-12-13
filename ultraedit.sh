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
#                                        「  v1.0 - retro dev toolkit  」
#                                         by Flames / Team Flames 🐱
#
#===============================================================================

set -e

INSTALL_DIR="${HOME}/retro-dev"
DOWNLOADS="${INSTALL_DIR}/downloads"
TOOLS="${INSTALL_DIR}/tools"
SDKS="${INSTALL_DIR}/sdks"
EMUS="${INSTALL_DIR}/emulators"
COMPILERS="${INSTALL_DIR}/compilers"
LOG="${INSTALL_DIR}/install.log"

mkdir -p "$DOWNLOADS" "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
exec 3>&1 4>&2 1>>"$LOG" 2>&1

IS_MAC=false; [[ "$(uname)" == "Darwin" ]] && IS_MAC=true
NCPU=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
SHELL_RC="$HOME/.bashrc"; $IS_MAC && SHELL_RC="$HOME/.zshrc"

dl() { curl -fsSL --retry 2 -o "$2" "$1" 2>/dev/null || wget -q -O "$2" "$1" 2>/dev/null; }

TOTAL=32
CURRENT=0

bar() {
    CURRENT=$((CURRENT + 1))
    local pct=$((CURRENT * 100 / TOTAL))
    local filled=$((pct / 2))
    local empty=$((50 - filled))
    printf "\r\033[K  \033[36m[\033[0m" >&3
    printf "%0.s█" $(seq 1 $filled 2>/dev/null || jot $filled 1) >&3
    printf "%0.s░" $(seq 1 $empty 2>/dev/null || jot $empty 1) >&3
    printf "\033[36m]\033[0m \033[33m%3d%%\033[0m  \033[35m%s\033[0m" "$pct" "$1" >&3
}

clear >&3
cat >&3 << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                                       「  v1.0 - retro dev toolkit  」
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )         (
                                          (           )
                                         ( (  )   (  ) )
                                        (__(__)___(__)__)

EOF
echo "" >&3

# === SYSTEM PACKAGES ===
bar "system deps..."
if $IS_MAC; then
    brew install gcc llvm cmake ninja meson autoconf automake libtool sdl2 sdl2_image sdl2_mixer sdl2_ttf libpng jpeg freetype zlib python3 nasm yasm flex bison texinfo readline ncurses wget curl p7zip libusb libftdi qemu dosbox-x glew glfw boost 2>/dev/null || true
else
    sudo apt-get update -qq && sudo apt-get install -y -qq build-essential gcc g++ clang llvm cmake ninja-build meson autoconf automake libtool libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev libpng-dev libjpeg-dev libfreetype6-dev zlib1g-dev python3 python3-pip nasm yasm flex bison texinfo libncurses-dev libreadline-dev curl wget unzip p7zip-full libusb-1.0-0-dev qemu-system-misc dosbox libgtk-3-dev libglew-dev libglfw3-dev xxd 2>/dev/null || true
fi

# === PYTHON ===
bar "python packages..."
pip3 install --user --break-system-packages -q pygame ursina pillow numpy pysdl2 pysdl2-dll pyyaml toml intelhex pyserial capstone keystone-engine unicorn 2>/dev/null || pip3 install --user -q pygame ursina pillow numpy pysdl2 pyyaml toml intelhex pyserial capstone 2>/dev/null || true

# === LIBDRAGON N64 ===
bar "libdragon n64..."
cd "$SDKS"
dl "https://github.com/DragonMinded/libdragon/archive/refs/heads/trunk.zip" libdragon.zip && unzip -qo libdragon.zip && mv libdragon-trunk libdragon 2>/dev/null; rm -f libdragon.zip

bar "n64 toolchain..."
mkdir -p "${COMPILERS}/n64" && cd "${COMPILERS}/n64"
if $IS_MAC; then
    dl "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-macos-arm64.tar.gz" tc.tar.gz || dl "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-macos-x86_64.tar.gz" tc.tar.gz
else
    dl "https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-linux-x86_64.tar.gz" tc.tar.gz
fi
tar xzf tc.tar.gz 2>/dev/null; rm -f tc.tar.gz
grep -q "N64_INST" "$SHELL_RC" 2>/dev/null || echo "export N64_INST=\"${COMPILERS}/n64\"; export PATH=\"\$N64_INST/bin:\$PATH\"" >> "$SHELL_RC"

# === DEVKITPRO ===
bar "devkitpro..."
mkdir -p "${COMPILERS}/devkitpro" && cd "${COMPILERS}/devkitpro"
if $IS_MAC; then
    dl "https://github.com/devkitPro/pacman/releases/download/v1.0.2/devkitpro-pacman-installer.pkg" devkitpro.pkg 2>/dev/null || true
else
    dl "https://wii.leseratte10.de/devkitPro/devkitARM/r64/devkitARM-r64-1-linux_x86_64.tar.xz" dkarm.tar.xz && tar xJf dkarm.tar.xz 2>/dev/null; rm -f dkarm.tar.xz
fi
grep -q "DEVKITPRO" "$SHELL_RC" 2>/dev/null || echo "export DEVKITPRO=\"/opt/devkitpro\"; export DEVKITARM=\"\$DEVKITPRO/devkitARM\"" >> "$SHELL_RC"

# === GBDK ===
bar "gbdk-2020..."
cd "$SDKS"
if $IS_MAC; then
    dl "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-macos.tar.gz" gbdk.tar.gz
else
    dl "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.3.0/gbdk-linux64.tar.gz" gbdk.tar.gz
fi
tar xzf gbdk.tar.gz 2>/dev/null; rm -f gbdk.tar.gz
grep -q "GBDK=" "$SHELL_RC" 2>/dev/null || echo "export GBDK=\"${SDKS}/gbdk\"; export PATH=\"\$GBDK/bin:\$PATH\"" >> "$SHELL_RC"

# === RGBDS ===
bar "rgbds..."
if $IS_MAC; then
    brew install rgbds 2>/dev/null || true
else
    cd "$TOOLS" && mkdir -p rgbds
    dl "https://github.com/gbdev/rgbds/releases/download/v0.8.0/rgbds-0.8.0-linux-x86_64.tar.xz" rgbds.tar.xz && tar xJf rgbds.tar.xz -C rgbds 2>/dev/null; rm -f rgbds.tar.xz
    grep -q "rgbds" "$SHELL_RC" 2>/dev/null || echo "export PATH=\"${TOOLS}/rgbds:\$PATH\"" >> "$SHELL_RC"
fi

# === CC65 ===
bar "cc65..."
if $IS_MAC; then
    brew install cc65 2>/dev/null || true
else
    cd "$COMPILERS"
    dl "https://github.com/cc65/cc65/archive/refs/tags/V2.19.tar.gz" cc65.tar.gz && tar xzf cc65.tar.gz && cd cc65-2.19 && make -j$NCPU && PREFIX="${COMPILERS}/cc65-install" make install; cd ..; rm -f cc65.tar.gz
    grep -q "CC65_HOME" "$SHELL_RC" 2>/dev/null || echo "export CC65_HOME=\"${COMPILERS}/cc65-install\"; export PATH=\"\$CC65_HOME/bin:\$PATH\"" >> "$SHELL_RC"
fi

# === SDCC ===
bar "sdcc..."
if $IS_MAC; then
    brew install sdcc 2>/dev/null || true
else
    cd "$COMPILERS"
    dl "https://sourceforge.net/projects/sdcc/files/sdcc-linux-amd64/4.4.0/sdcc-4.4.0-amd64-unknown-linux2.5.tar.bz2/download" sdcc.tar.bz2 && tar xjf sdcc.tar.bz2 && mv sdcc-4.4.0 sdcc 2>/dev/null; rm -f sdcc.tar.bz2
    grep -q "sdcc/bin" "$SHELL_RC" 2>/dev/null || echo "export PATH=\"${COMPILERS}/sdcc/bin:\$PATH\"" >> "$SHELL_RC"
fi

# === WLA-DX ===
bar "wla-dx..."
cd "$TOOLS"
dl "https://github.com/vhelin/wla-dx/archive/refs/tags/v10.6.tar.gz" wla.tar.gz && tar xzf wla.tar.gz && cd wla-dx-10.6 && mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make -j$NCPU; cd ../..
rm -f wla.tar.gz
grep -q "wla-dx" "$SHELL_RC" 2>/dev/null || echo "export PATH=\"${TOOLS}/wla-dx-10.6/build/binaries:\$PATH\"" >> "$SHELL_RC"

# === ASM6 ===
bar "asm6..."
cd "$TOOLS" && mkdir -p asm6 && cd asm6
dl "https://raw.githubusercontent.com/loopy-ru/asm6f/master/asm6f.c" asm6f.c && gcc -O3 -o asm6f asm6f.c 2>/dev/null || true
grep -q "asm6" "$SHELL_RC" 2>/dev/null || echo "export PATH=\"${TOOLS}/asm6:\$PATH\"" >> "$SHELL_RC"

# === NESASM ===
bar "nesasm..."
cd "$TOOLS" && mkdir -p nesasm && cd nesasm
dl "https://github.com/camsaul/nesasm/archive/refs/heads/master.zip" nesasm.zip && unzip -qo nesasm.zip && cd nesasm-master/source && make 2>/dev/null || true; cd ../..
rm -f nesasm.zip

# === DASM ===
bar "dasm..."
cd "$SDKS" && mkdir -p atari && cd atari
if $IS_MAC; then
    dl "https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-macos-x64.tar.gz" dasm.tar.gz
else
    dl "https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-linux-x64.tar.gz" dasm.tar.gz
fi
tar xzf dasm.tar.gz 2>/dev/null; rm -f dasm.tar.gz
grep -q "atari" "$SHELL_RC" 2>/dev/null || echo "export PATH=\"${SDKS}/atari:\$PATH\"" >> "$SHELL_RC"

# === SGDK ===
bar "sgdk..."
cd "$SDKS"
dl "https://github.com/Stephane-D/SGDK/releases/download/v2.00/sgdk200.zip" sgdk.zip && mkdir -p sgdk && unzip -qo sgdk.zip -d sgdk 2>/dev/null; rm -f sgdk.zip
grep -q "SGDK=" "$SHELL_RC" 2>/dev/null || echo "export SGDK=\"${SDKS}/sgdk\"" >> "$SHELL_RC"

# === PVSNESLIB ===
bar "pvsneslib..."
cd "$SDKS"
dl "https://github.com/alekmaul/pvsneslib/releases/download/4.3.0/pvsneslib-4.3.0.zip" pvs.zip && unzip -qo pvs.zip -d pvsneslib 2>/dev/null; rm -f pvs.zip
grep -q "PVSNESLIB" "$SHELL_RC" 2>/dev/null || echo "export PVSNESLIB=\"${SDKS}/pvsneslib\"" >> "$SHELL_RC"

# === VBCC ===
bar "vbcc..."
cd "$COMPILERS" && mkdir -p vbcc && cd vbcc
dl "http://phoenix.owl.de/tags/vbcc0_9h.tar.gz" vbcc.tar.gz && tar xzf vbcc.tar.gz 2>/dev/null; rm -f vbcc.tar.gz

# === FLIPS ===
bar "flips..."
cd "$TOOLS" && mkdir -p flips
if $IS_MAC; then
    dl "https://github.com/Alcaro/Flips/releases/download/v1.31/flips-mac.zip" flips.zip
else
    dl "https://github.com/Alcaro/Flips/releases/download/v1.31/flips-linux.zip" flips.zip
fi
unzip -qo flips.zip -d flips 2>/dev/null; rm -f flips.zip
grep -q "flips" "$SHELL_RC" 2>/dev/null || echo "export PATH=\"${TOOLS}/flips:\$PATH\"" >> "$SHELL_RC"

# === LUNAR IPS ===
bar "lunar ips..."
cd "$TOOLS" && mkdir -p lunar
dl "https://fusoya.eludevisibility.org/lips/download/lips106.zip" lips.zip && unzip -qo lips.zip -d lunar 2>/dev/null; rm -f lips.zip

# === EMULATORS ===
bar "fceux..."
cd "$EMUS"
dl "https://github.com/TASEmulators/fceux/archive/refs/tags/v2.6.6.tar.gz" fceux.tar.gz && tar xzf fceux.tar.gz 2>/dev/null; rm -f fceux.tar.gz

bar "snes9x..."
dl "https://github.com/snes9xgit/snes9x/archive/refs/tags/1.63.tar.gz" snes9x.tar.gz && tar xzf snes9x.tar.gz 2>/dev/null; rm -f snes9x.tar.gz

bar "mgba..."
if $IS_MAC; then
    dl "https://github.com/mgba-emu/mgba/releases/download/0.10.3/mGBA-0.10.3-macos-arm64.dmg" mgba.dmg 2>/dev/null || dl "https://github.com/mgba-emu/mgba/releases/download/0.10.3/mGBA-0.10.3-macos-x86_64.dmg" mgba.dmg
else
    dl "https://github.com/mgba-emu/mgba/archive/refs/tags/0.10.3.tar.gz" mgba.tar.gz && tar xzf mgba.tar.gz 2>/dev/null; rm -f mgba.tar.gz
fi

bar "mupen64plus..."
dl "https://github.com/mupen64plus/mupen64plus-core/archive/refs/tags/2.6.0.tar.gz" mupen.tar.gz && tar xzf mupen.tar.gz 2>/dev/null; rm -f mupen.tar.gz

bar "ares..."
if $IS_MAC; then
    dl "https://github.com/ares-emulator/ares/releases/download/v141/ares-macos-arm64.zip" ares.zip 2>/dev/null || dl "https://github.com/ares-emulator/ares/releases/download/v141/ares-macos-x64.zip" ares.zip
else
    dl "https://github.com/ares-emulator/ares/releases/download/v139/ares-linux-x86_64.zip" ares.zip
fi
mkdir -p ares && unzip -qo ares.zip -d ares 2>/dev/null; rm -f ares.zip

bar "stella..."
dl "https://github.com/stella-emu/stella/archive/refs/tags/6.7.1.tar.gz" stella.tar.gz && tar xzf stella.tar.gz 2>/dev/null; rm -f stella.tar.gz

# === VINTAGE ===
bar "simh..."
cd "$TOOLS" && mkdir -p vintage
if $IS_MAC; then
    brew install simh 2>/dev/null || true
else
    dl "https://github.com/simh/simh/archive/refs/tags/v3.12-4.tar.gz" simh.tar.gz && tar xzf simh.tar.gz -C vintage 2>/dev/null; rm -f simh.tar.gz
fi

bar "z80pack..."
dl "https://www.autometer.de/unix4fun/z80pack/ftp/z80pack-1.37.tgz" z80.tgz && tar xzf z80.tgz -C vintage 2>/dev/null; rm -f z80.tgz

# === MODERN LIBS ===
bar "raylib..."
cd "$TOOLS"
dl "https://github.com/raysan5/raylib/archive/refs/tags/5.5.tar.gz" raylib.tar.gz && tar xzf raylib.tar.gz 2>/dev/null; rm -f raylib.tar.gz
$IS_MAC && brew install raylib 2>/dev/null || true

bar "love2d..."
if $IS_MAC; then
    dl "https://github.com/love2d/love/releases/download/11.5/love-11.5-macos.zip" love.zip && unzip -qo love.zip 2>/dev/null; rm -f love.zip
else
    dl "https://github.com/love2d/love/releases/download/11.5/love-11.5-linux-x86_64.tar.gz" love.tar.gz && tar xzf love.tar.gz 2>/dev/null; rm -f love.tar.gz
fi

bar "godot..."
if $IS_MAC; then
    dl "https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_macos.universal.zip" godot.zip
else
    dl "https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip" godot.zip
fi
unzip -qo godot.zip 2>/dev/null; rm -f godot.zip

# === AUDIO ===
bar "audio tools..."
cd "$TOOLS" && mkdir -p audio
$IS_MAC && brew install milkytracker 2>/dev/null || dl "https://github.com/milkytracker/MilkyTracker/archive/refs/tags/v1.04.00.tar.gz" mt.tar.gz && tar xzf mt.tar.gz -C audio 2>/dev/null; rm -f mt.tar.gz

# === ENV SCRIPT ===
bar "finalizing..."
cat > "${INSTALL_DIR}/env.sh" << 'ENVEOF'
#!/bin/bash
export RETRO_DEV="$HOME/retro-dev"
export N64_INST="$RETRO_DEV/compilers/n64"
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export GBDK="$RETRO_DEV/sdks/gbdk"
export CC65_HOME="$RETRO_DEV/compilers/cc65-install"
export SGDK="$RETRO_DEV/sdks/sgdk"
export PVSNESLIB="$RETRO_DEV/sdks/pvsneslib"
export PATH="$N64_INST/bin:$DEVKITARM/bin:$GBDK/bin:$CC65_HOME/bin:$RETRO_DEV/compilers/sdcc/bin:$RETRO_DEV/tools/rgbds:$RETRO_DEV/tools/flips:$RETRO_DEV/tools/asm6:$RETRO_DEV/tools/wla-dx-10.6/build/binaries:$RETRO_DEV/sdks/atari:$PATH"
echo "🐱 CATS TWEAKER environment loaded! 🎮"
ENVEOF
chmod +x "${INSTALL_DIR}/env.sh"

exec 1>&3 2>&4

echo "" >&3
echo "" >&3
echo -e "\033[32m  ╔═══════════════════════════════════════════════════════════════╗\033[0m" >&3
echo -e "\033[32m  ║\033[0m  \033[1;37m✨ CATS TWEAKER 1.0 INSTALLATION COMPLETE! ✨\033[0m                \033[32m║\033[0m" >&3
echo -e "\033[32m  ╠═══════════════════════════════════════════════════════════════╣\033[0m" >&3
echo -e "\033[32m  ║\033[0m  \033[36mInstalled to:\033[0m $INSTALL_DIR" >&3
echo -e "\033[32m  ║\033[0m  \033[36mActivate:\033[0m     source ~/retro-dev/env.sh                      \033[32m║\033[0m" >&3
echo -e "\033[32m  ║\033[0m  \033[36mLog:\033[0m          ~/retro-dev/install.log                       \033[32m║\033[0m" >&3
echo -e "\033[32m  ╚═══════════════════════════════════════════════════════════════╝\033[0m" >&3
echo "" >&3
echo -e "                           \033[35m/\\_____/\\\033[0m" >&3
echo -e "                          \033[35m/  o   o  \\\033[0m" >&3
echo -e "                         \033[35m( ==  ^  == )\033[0m" >&3
echo -e "                          \033[35m)  ~nya~  (\033[0m" >&3
echo -e "                         \033[35m(           )\033[0m" >&3
echo -e "                        \033[35m( (  )   (  ) )\033[0m" >&3
echo -e "                       \033[35m(__(__)___(__)__)\033[0m" >&3
echo "" >&3
