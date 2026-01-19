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
#                       「  v3.5.1 - M4 PRO FINAL EDITION  」
#                         1930-2026 + NES→PS5 TOOLKIT
#                            by Flames / Team Flames 🐱
#                       [PATCHED: DASM, z88dk, rgbasm fixes]
#
#===============================================================================

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

G=$'\033[0;32m'; Y=$'\033[0;33m'; C=$'\033[0;36m'; M=$'\033[0;35m'; R=$'\033[0;31m'; W=$'\033[1;37m'; RST=$'\033[0m'

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
step() { printf "\n${M}══════════════════════════════════════════════════════════════════════${RST}\n${M}▸ %s${RST}\n${M}══════════════════════════════════════════════════════════════════════${RST}\n" "$1"; }

IS_APPLE_SILICON=false; [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" == *"Apple"* ]] && IS_APPLE_SILICON=true
IS_M4=false; [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" == *"M4"* ]] && IS_M4=true
HAS_ROSETTA=false; [[ -f /Library/Apple/usr/share/rosetta/rosetta ]] && HAS_ROSETTA=true

BREW_ARM="/opt/homebrew/bin/brew"; BREW_X86="/usr/local/bin/brew"; BREW=""
[[ -x "$BREW_ARM" ]] && BREW="$BREW_ARM"
[[ -z "$BREW" && -x "$BREW_X86" ]] && BREW="$BREW_X86"

INSTALL_DIR="$HOME/retro-dev"
TOOLS="$INSTALL_DIR/tools"
SDKS="$INSTALL_DIR/sdks"
EMUS="$INSTALL_DIR/emulators"
COMPILERS="$INSTALL_DIR/compilers"
LOG="$INSTALL_DIR/install.log"

mkdir -p "$TOOLS" "$SDKS" "$EMUS" "$COMPILERS"
: > "$LOG"

NCPU=$(sysctl -n hw.ncpu 2>/dev/null || echo 8)
SHELL_RC="$HOME/.zshrc"

dl() {
    local url="$1" dest="$2"
    curl -fsSL --connect-timeout 30 --max-time 600 --retry 3 -L \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        -o "$dest" "$url" 2>>"$LOG" && [[ -s "$dest" ]] && return 0
    wget -q --timeout=30 --tries=3 -O "$dest" "$url" 2>>"$LOG" && [[ -s "$dest" ]] && return 0
    return 1
}

add_path() { grep -qxF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }

brew_pkg() {
    local pkg="$1"
    "$BREW" list "$pkg" &>/dev/null && { ok "$pkg"; return 0; }
    printf "  ${C}[*]${RST} %s..." "$pkg"
    GIT_TERMINAL_PROMPT=0 "$BREW" install "$pkg" >> "$LOG" 2>&1
    "$BREW" list "$pkg" &>/dev/null && { printf "\r  ${G}[✓]${RST} %-30s\n" "$pkg"; return 0; } || { printf "\r  ${Y}[!]${RST} %-30s\n" "$pkg"; return 1; }
}

clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                         「  v3.5.1 - M4 PRO FINAL EDITION  」
                                            /\_____/\
                                           /  o   o  \
                                          ( ==  ^  == )
                                           )  ~nya~  (
                                          (  FINAL   )
                                         ( (  )   (  ) )
                                        (__(__)___(__)__)

EOF

step "SYSTEM"; $IS_M4 && ok "M4 Pro"; $IS_APPLE_SILICON && ok "Apple Silicon"; $HAS_ROSETTA && ok "Rosetta 2"; ok "$NCPU cores"

step "ROSETTA 2"; $HAS_ROSETTA && ok "Ready" || { softwareupdate --install-rosetta --agree-to-license >> "$LOG" 2>&1; ok "Installed"; }

step "XCODE CLI"; xcode-select -p &>/dev/null && ok "Xcode CLI" || { xcode-select --install; exit 1; }

step "HOMEBREW"
[[ -n "$BREW" ]] && { ok "Homebrew"; eval "$("$BREW" shellenv)" 2>/dev/null; } || {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [[ -x "$BREW_ARM" ]] && BREW="$BREW_ARM" || BREW="$BREW_X86"
    eval "$("$BREW" shellenv)" 2>/dev/null
}
add_path '[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"'
add_path '[[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"'
GIT_TERMINAL_PROMPT=0 "$BREW" update >> "$LOG" 2>&1

step "CORE TOOLS"
for pkg in curl wget cmake ninja nasm yasm pkg-config autoconf automake libtool make llvm p7zip unzip xz coreutils; do brew_pkg "$pkg"; done

step "LANGUAGES"
brew_pkg openjdk@21; brew_pkg openjdk@17; brew_pkg node; brew_pkg python3

step "DOCKER"
command -v docker &>/dev/null && ok "Docker" || {
    $IS_APPLE_SILICON && U="https://desktop.docker.com/mac/main/arm64/Docker.dmg" || U="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
    dl "$U" /tmp/docker.dmg && hdiutil attach /tmp/docker.dmg -nobrowse >> "$LOG" 2>&1 && \
        cp -R "/Volumes/Docker/Docker.app" /Applications/ && hdiutil detach /Volumes/Docker >> "$LOG" 2>&1 && \
        rm -f /tmp/docker.dmg && ok "Docker" || warn "Docker"
}

step "VINTAGE"
mkdir -p "$TOOLS/vintage"
cat > "$TOOLS/vintage/turing.py" << 'PY'
#!/usr/bin/env python3
class TM:
    def __init__(s,t='',b='_'):s.tape=list(t)or[b];s.h=0;s.s='q0';s.b=b;s.r={}
    def add(s,st,rd,wr,mv,ns):s.r[(st,rd)]=(wr,mv,ns)
    def run(s,n=1000):
        for _ in range(n):
            if s.h<0:s.tape.insert(0,s.b);s.h=0
            if s.h>=len(s.tape):s.tape.append(s.b)
            if(s.s,s.tape[s.h])not in s.r:break
            w,m,s.s=s.r[(s.s,s.tape[s.h])];s.tape[s.h]=w;s.h+=1 if m=='R'else-1
        return''.join(s.tape).strip(s.b)
PY
chmod +x "$TOOLS/vintage/turing.py"; ok "Turing Machine"
cat > "$TOOLS/vintage/basic.py" << 'PY'
#!/usr/bin/env python3
import re
class BASIC:
    def __init__(s):s.v={};s.l={};s.p=0
    def run(s,c):
        for ln in c.strip().split('\n'):
            m=re.match(r'(\d+)\s+(.*)',ln)
            if m:s.l[int(m.group(1))]=m.group(2)
        s.p=min(s.l)if s.l else 0
        while s.p in s.l:
            st=s.l[s.p].strip()
            if st.startswith('PRINT'):print(s._v(st[5:].strip().strip('"')))
            elif st.startswith('LET'):m=re.match(r'LET\s*([A-Z])=(.+)',st);s.v[m.group(1)]=s._v(m.group(2))if m else None
            elif st.startswith('GOTO'):s.p=int(st[4:])-1
            elif st=='END':break
            s.p=min([k for k in s.l if k>s.p],default=max(s.l)+1)
    def _v(s,e):
        for v in s.v:e=str(e).replace(v,str(s.v[v]))
        try:return eval(str(e))
        except:return e
PY
chmod +x "$TOOLS/vintage/basic.py"; ok "BASIC"
brew_pkg gnucobol && ok "COBOL"; brew_pkg gcc && ok "Fortran"

step "RETRO COMPILERS"
brew_pkg cc65 && ok "cc65 (6502)"; brew_pkg sdcc && ok "SDCC (Z80)"; brew_pkg rgbds && ok "RGBDS (GB)"

# z88dk - try Homebrew first, then provide source build script
info "z88dk..."
if "$BREW" list z88dk &>/dev/null; then
    ok "z88dk (cached)"
elif GIT_TERMINAL_PROMPT=0 "$BREW" install z88dk >> "$LOG" 2>&1 && command -v z88dk-z80asm &>/dev/null; then
    ok "z88dk"
else
    warn "z88dk (brew failed)"
    mkdir -p "$COMPILERS/z88dk"; cd "$COMPILERS/z88dk"
    cat > build_z88dk.sh << 'Z88'
#!/bin/bash
# z88dk source build for Apple Silicon
set -e
cd ~/retro-dev/compilers/z88dk
git clone --depth 1 https://github.com/z88dk/z88dk.git src 2>/dev/null || (cd src && git pull)
cd src
export BUILD_SDCC=1
chmod 777 build.sh && ./build.sh -j$(sysctl -n hw.ncpu)
echo "export ZCCCFG=$PWD/lib/config" >> ~/.zshrc
echo "export PATH=$PWD/bin:\$PATH" >> ~/.zshrc
echo "Done! Run: source ~/.zshrc"
Z88
    chmod +x build_z88dk.sh
    info "z88dk: run ~/retro-dev/compilers/z88dk/build_z88dk.sh"
fi

step "NES (1983)"
mkdir -p "$SDKS/nes" "$EMUS/nes" "$TOOLS/asm6"
cd "$TOOLS/asm6"
cat > asm6.c << 'CEOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define MAXSYM 4096
typedef struct{char n[32];int v;}Sym;Sym sym[MAXSYM];int nsym=0;unsigned char rom[65536];int pc=0,pass;
int getsym(char*n){for(int i=0;i<nsym;i++)if(!strcmp(sym[i].n,n))return sym[i].v;return-1;}
void setsym(char*n,int v){for(int i=0;i<nsym;i++)if(!strcmp(sym[i].n,n)){sym[i].v=v;return;}strcpy(sym[nsym].n,n);sym[nsym++].v=v;}
void emit(int b){if(pass==2)rom[pc]=b;pc++;}
int eval(char*s){while(*s==' ')s++;if(*s=='$')return strtol(s+1,0,16);if(*s=='%')return strtol(s+1,0,2);if(isdigit(*s))return atoi(s);int v=getsym(s);return v>=0?v:0;}
void assemble(char*fn){
    FILE*f=fopen(fn,"r");if(!f){printf("Cannot open %s\n",fn);return;}char line[256],*p,*op,*arg;
    for(pass=1;pass<=2;pass++){pc=0;rewind(f);
        while(fgets(line,256,f)){p=line;while(*p==' '||*p=='\t')p++;if(*p==';'||*p=='\n'||!*p)continue;
            char*c=strchr(p,';');if(c)*c=0;char*col=strchr(p,':');
            if(col){*col=0;setsym(p,pc);p=col+1;while(*p==' ')p++;}if(!*p||*p=='\n')continue;
            op=p;while(*p&&*p!=' '&&*p!='\t'&&*p!='\n')p++;if(*p){*p++=0;while(*p==' '||*p=='\t')p++;}
            arg=p;char*e=arg;while(*e&&*e!='\n')e++;*e=0;for(char*x=op;*x;x++)*x=toupper(*x);
            if(!strcmp(op,".ORG"))pc=eval(arg);
            else if(!strcmp(op,".DB")||!strcmp(op,".BYTE")){char*t=strtok(arg,",");while(t){while(*t==' ')t++;emit(eval(t));t=strtok(0,",");}}
            else if(!strcmp(op,".DW")||!strcmp(op,".WORD")){char*t=strtok(arg,",");while(t){int v=eval(t);emit(v&0xFF);emit(v>>8);t=strtok(0,",");}}
            else if(!strcmp(op,"LDA")){if(*arg=='#'){emit(0xA9);emit(eval(arg+1));}else{emit(0xAD);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"LDX")){if(*arg=='#'){emit(0xA2);emit(eval(arg+1));}else{emit(0xAE);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"LDY")){if(*arg=='#'){emit(0xA0);emit(eval(arg+1));}else{emit(0xAC);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"STA")){emit(0x8D);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"STX")){emit(0x8E);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"STY")){emit(0x8C);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"JMP")){emit(0x4C);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"JSR")){emit(0x20);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"BNE")){emit(0xD0);emit((eval(arg)-pc-1)&0xFF);}
            else if(!strcmp(op,"BEQ")){emit(0xF0);emit((eval(arg)-pc-1)&0xFF);}
            else if(!strcmp(op,"RTS"))emit(0x60);else if(!strcmp(op,"NOP"))emit(0xEA);
            else if(!strcmp(op,"SEI"))emit(0x78);else if(!strcmp(op,"CLD"))emit(0xD8);
            else if(!strcmp(op,"INX"))emit(0xE8);else if(!strcmp(op,"DEX"))emit(0xCA);
            else if(!strcmp(op,"INY"))emit(0xC8);else if(!strcmp(op,"DEY"))emit(0x88);
            else if(!strcmp(op,"TAX"))emit(0xAA);else if(!strcmp(op,"TXA"))emit(0x8A);
            else if(!strcmp(op,"PHA"))emit(0x48);else if(!strcmp(op,"PLA"))emit(0x68);
            else if(!strcmp(op,"ADC")){if(*arg=='#'){emit(0x69);emit(eval(arg+1));}}
            else if(!strcmp(op,"SBC")){if(*arg=='#'){emit(0xE9);emit(eval(arg+1));}}
            else if(!strcmp(op,"CMP")){if(*arg=='#'){emit(0xC9);emit(eval(arg+1));}}
            else if(!strcmp(op,"AND")){if(*arg=='#'){emit(0x29);emit(eval(arg+1));}}
            else if(!strcmp(op,"ORA")){if(*arg=='#'){emit(0x09);emit(eval(arg+1));}}
            else if(!strcmp(op,"CLC"))emit(0x18);else if(!strcmp(op,"SEC"))emit(0x38);
        }
    }fclose(f);
    char out[256];strcpy(out,fn);char*d=strrchr(out,'.');if(d)strcpy(d,".bin");else strcat(out,".bin");
    f=fopen(out,"wb");fwrite(rom,1,pc,f);fclose(f);printf("Assembled %d bytes -> %s\n",pc,out);
}
int main(int c,char**v){if(c<2){puts("ASM6 - 6502 Assembler\nUsage: asm6 file.asm");return 1;}assemble(v[1]);return 0;}
CEOF
clang -O3 -o asm6 asm6.c >> "$LOG" 2>&1 && ok "ASM6" || warn "ASM6"

mkdir -p "$SDKS/nes/neslib"
cat > "$SDKS/nes/neslib/neslib.h" << 'H'
#ifndef _NESLIB_H
#define _NESLIB_H
void __fastcall__ ppu_on_all(void);
void __fastcall__ ppu_off(void);
void __fastcall__ pal_all(const char *data);
void __fastcall__ pal_bg(const char *data);
void __fastcall__ pal_spr(const char *data);
void __fastcall__ vram_adr(unsigned int adr);
void __fastcall__ vram_put(unsigned char n);
void __fastcall__ vram_fill(unsigned char n,unsigned int len);
void __fastcall__ vram_write(const char *src,unsigned int size);
unsigned char __fastcall__ pad_poll(unsigned char pad);
void __fastcall__ oam_clear(void);
void __fastcall__ oam_spr(unsigned char x,unsigned char y,unsigned char chrnum,unsigned char attr);
void __fastcall__ scroll(unsigned int x,unsigned int y);
#define PAD_A 0x01
#define PAD_B 0x02
#define PAD_SELECT 0x04
#define PAD_START 0x08
#define PAD_UP 0x10
#define PAD_DOWN 0x20
#define PAD_LEFT 0x40
#define PAD_RIGHT 0x80
#endif
H
ok "NESLib"

cd "$EMUS/nes"
[[ -d "$EMUS/nes/fceux.app" ]] || [[ -d "$EMUS/nes/FCEUX.app" ]] && ok "FCEUX" || {
    dl "https://sourceforge.net/projects/fceultra/files/Binaries/2.6.6/fceux-2.6.6-macOS.dmg/download" fceux.dmg && {
        hdiutil attach fceux.dmg -nobrowse >> "$LOG" 2>&1
        cp -R /Volumes/fceux*/*.app . 2>/dev/null || cp -R /Volumes/FCEUX*/*.app . 2>/dev/null
        hdiutil detach /Volumes/fceux* 2>/dev/null; hdiutil detach /Volumes/FCEUX* 2>/dev/null
        rm -f fceux.dmg; xattr -dr com.apple.quarantine *.app 2>/dev/null
        ok "FCEUX"
    } || warn "FCEUX"
}

step "GENESIS (1988)"
mkdir -p "$SDKS/genesis"
cat > "$SDKS/genesis/README.md" << 'MD'
# SGDK (Docker)
docker pull doragasu/docker-sgdk
docker run --rm -v $(pwd):/src doragasu/docker-sgdk make
MD
ok "SGDK (Docker)"

step "GAME BOY (1989)"
mkdir -p "$SDKS/gameboy"; cd "$SDKS"
[[ -d "$SDKS/gbdk" ]] && ok "GBDK" || {
    dl "https://sourceforge.net/projects/gbdk/files/gbdk-macos/4.3.0/gbdk-4.3.0-macos.tar.gz/download" gbdk.tar.gz && {
        tar xzf gbdk.tar.gz >> "$LOG" 2>&1; rm -f gbdk.tar.gz; ok "GBDK"
    } || warn "GBDK"
}

step "SNES (1990)"
mkdir -p "$SDKS/snes"
cat > "$SDKS/snes/README.md" << 'MD'
# PVSnesLib
Download: https://github.com/alekmaul/pvsneslib/releases
export PVSNESLIB_HOME=~/retro-dev/sdks/pvsneslib
MD
ok "PVSnesLib (template)"

step "N64 (1996)"
mkdir -p "$COMPILERS/n64" "$COMPILERS/mips-toolchain"
command -v npm &>/dev/null && { npm list -g libdragon &>/dev/null || npm install -g libdragon >> "$LOG" 2>&1; }
command -v libdragon &>/dev/null && ok "libdragon" || warn "libdragon"
cd "$COMPILERS/mips-toolchain"
cat > build_mips.sh << 'MIPS'
#!/bin/bash
set -e
PREFIX="$HOME/retro-dev/compilers/mips-toolchain"; TARGET="mips64-elf"; J=$(sysctl -n hw.ncpu)
mkdir -p "$PREFIX/src" && cd "$PREFIX/src"
curl -fsSL "https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz" -o b.tar.xz && tar xf b.tar.xz && cd binutils-* && mkdir build && cd build && ../configure --target=$TARGET --prefix=$PREFIX --disable-nls --disable-werror && make -j$J && make install && cd "$PREFIX/src"
curl -fsSL "https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz" -o g.tar.xz && tar xf g.tar.xz && cd gcc-* && ./contrib/download_prerequisites && mkdir build && cd build && ../configure --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages=c --without-headers && make -j$J all-gcc && make install-gcc
echo "Done! export PATH=\"$PREFIX/bin:\$PATH\""
MIPS
chmod +x build_mips.sh; ok "MIPS64 script"

step "ATARI"
mkdir -p "$SDKS/atari"; cd "$SDKS/atari"
[[ -x "$SDKS/atari/dasm" ]] && ok "DASM (cached)" || {
    info "Installing DASM..."
    # Try GitHub release first (more reliable)
    if dl "https://github.com/dasm-assembler/dasm/releases/download/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz" dasm.tar.gz; then
        tar xzf dasm.tar.gz >> "$LOG" 2>&1
    # Fallback: SourceForge with proper redirect handling  
    elif curl -fsSL -L --max-redirs 10 -o dasm.tar.gz "https://sourceforge.net/projects/dasm-dillon/files/dasm-dillon/2.20.14.1/dasm-2.20.14.1-osx-x64.tar.gz/download" 2>>"$LOG"; then
        tar xzf dasm.tar.gz >> "$LOG" 2>&1
    fi
    rm -f dasm.tar.gz 2>/dev/null
    # Find and move dasm binary (may be in subdirectory)
    DASM_BIN=$(find . -name "dasm" -type f -perm +111 2>/dev/null | head -1)
    [[ -z "$DASM_BIN" ]] && DASM_BIN=$(find . -name "dasm" -type f 2>/dev/null | head -1)
    if [[ -n "$DASM_BIN" && "$DASM_BIN" != "./dasm" ]]; then
        mv "$DASM_BIN" ./dasm 2>/dev/null
        # Clean up extracted directory
        find . -maxdepth 1 -type d -name "dasm*" -exec rm -rf {} \; 2>/dev/null
    fi
    chmod +x dasm 2>/dev/null
    [[ -x "$SDKS/atari/dasm" ]] && ok "DASM" || warn "DASM"
}

step "PS1-5"
mkdir -p "$SDKS/ps1" "$SDKS/ps2" "$SDKS/ps3" "$SDKS/ps4" "$SDKS/ps5"
ok "PS1-5 placeholders"

step "DEVKITPRO"
mkdir -p "$COMPILERS/devkitpro"; cd "$COMPILERS/devkitpro"
[[ -f "$COMPILERS/devkitpro/devkitpro.pkg" ]] && ok "DevkitPro (cached)" || {
    info "Downloading DevkitPro..."
    # Try official first
    if curl -fsSL --connect-timeout 30 --max-time 300 -o devkitpro.pkg "https://apt.devkitpro.org/devkitpro-pacman-installer.pkg" 2>>"$LOG" && [[ -s devkitpro.pkg ]]; then
        ok "DevkitPro (apt.devkitpro.org)"
    # Try Wii mirror
    elif curl -fsSL --connect-timeout 30 --max-time 300 -o devkitpro.pkg "https://wii.leseratte10.de/devkitPro/devkitpro-pacman-installer.pkg" 2>>"$LOG" && [[ -s devkitpro.pkg ]]; then
        ok "DevkitPro (wii.leseratte10.de)"
    # Try wget
    elif wget -q --timeout=30 --tries=3 -O devkitpro.pkg "https://apt.devkitpro.org/devkitpro-pacman-installer.pkg" 2>>"$LOG" && [[ -s devkitpro.pkg ]]; then
        ok "DevkitPro (wget)"
    # Try wget mirror
    elif wget -q --timeout=30 --tries=3 -O devkitpro.pkg "https://wii.leseratte10.de/devkitPro/devkitpro-pacman-installer.pkg" 2>>"$LOG" && [[ -s devkitpro.pkg ]]; then
        ok "DevkitPro (wget mirror)"
    else
        rm -f devkitpro.pkg 2>/dev/null
        warn "DevkitPro download failed"
        info "Manual: curl -L -o devkitpro.pkg https://apt.devkitpro.org/devkitpro-pacman-installer.pkg"
    fi
}
[[ -f "$COMPILERS/devkitpro/devkitpro.pkg" ]] && info "Install: sudo installer -pkg ~/retro-dev/compilers/devkitpro/devkitpro.pkg -target /"

step "VASM"
mkdir -p "$TOOLS/vasm"; cd "$TOOLS/vasm"
[[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM (cached)" || {
    dl "http://sun.hasenbraten.de/vasm/release/vasm.tar.gz" vasm.tar.gz && {
        tar xzf vasm.tar.gz >> "$LOG" 2>&1; rm -f vasm.tar.gz
        D=$(find . -maxdepth 1 -type d -name "vasm*" | head -1)
        [[ -n "$D" ]] && cd "$D" && {
            make CPU=6502 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1 && cp vasm6502_oldstyle "$TOOLS/vasm/" 2>/dev/null
            make clean >> "$LOG" 2>&1
            make CPU=m68k SYNTAX=mot -j$NCPU >> "$LOG" 2>&1 && cp vasmm68k_mot "$TOOLS/vasm/" 2>/dev/null
            make clean >> "$LOG" 2>&1
            make CPU=z80 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1 && cp vasmz80_oldstyle "$TOOLS/vasm/" 2>/dev/null
            cd "$TOOLS/vasm"; rm -rf "$D"
        }
    }
}
[[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM" || warn "VASM"

step "ROM TOOLS"
mkdir -p "$TOOLS/flips"; cd "$TOOLS/flips"
[[ -f "$TOOLS/flips/flips" ]] || [[ -f "$TOOLS/flips/Flips" ]] && ok "Flips (cached)" || {
    dl "https://dl.smwcentral.net/11474/floating.zip" flips.zip && {
        unzip -qo flips.zip >> "$LOG" 2>&1; rm -f flips.zip; ok "Flips"
    } || warn "Flips"
}

step "GAME ENGINES"
cd "$TOOLS"
[[ -d "$TOOLS/Godot.app" ]] || [[ -d "$TOOLS/Godot_v4"* ]] && ok "Godot (cached)" || {
    dl "https://downloads.tuxfamily.org/godotengine/4.3/Godot_v4.3-stable_macos.universal.zip" godot.zip && {
        unzip -qo godot.zip >> "$LOG" 2>&1; rm -f godot.zip; xattr -dr com.apple.quarantine Godot* 2>/dev/null; ok "Godot"
    } || warn "Godot"
}
brew_pkg raylib && ok "Raylib"; brew_pkg love && ok "LÖVE"; brew_pkg sdl2 && ok "SDL2"

step "EMULATORS"
mkdir -p "$EMUS"; cd "$EMUS"
[[ -d "$EMUS/mGBA.app" ]] && ok "mGBA (cached)" || {
    dl "https://mgba.io/downloads/mGBA-0.10.5-macos-universal.dmg" mgba.dmg && {
        hdiutil attach mgba.dmg -nobrowse >> "$LOG" 2>&1
        cp -R /Volumes/mGBA*/mGBA.app . 2>/dev/null
        hdiutil detach /Volumes/mGBA* >> "$LOG" 2>&1
        rm -f mgba.dmg; xattr -dr com.apple.quarantine mGBA.app 2>/dev/null; ok "mGBA"
    } || warn "mGBA"
}
[[ -d "$EMUS/OpenEmu.app" ]] && ok "OpenEmu (cached)" || {
    dl "https://openemu.org/files/OpenEmu_2.4.1.zip" openemu.zip && {
        unzip -qo openemu.zip >> "$LOG" 2>&1; rm -f openemu.zip; xattr -dr com.apple.quarantine OpenEmu.app 2>/dev/null; ok "OpenEmu"
    } || warn "OpenEmu"
}

step "ENVIRONMENT"
cat > "$INSTALL_DIR/env.sh" << 'ENV'
#!/bin/bash
export RETRO_DEV="$HOME/retro-dev"
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export DEVKITPPC="$DEVKITPRO/devkitPPC"
export GBDK="$RETRO_DEV/sdks/gbdk"
export SGDK="$RETRO_DEV/sdks/sgdk"
export N64_INST="$RETRO_DEV/compilers/mips-toolchain"
[[ -d "$N64_INST/bin" ]] && export PATH="$N64_INST/bin:$PATH"
[[ -d "$DEVKITARM/bin" ]] && export PATH="$DEVKITARM/bin:$PATH"
[[ -d "$GBDK/bin" ]] && export PATH="$GBDK/bin:$PATH"
# z88dk source build support
[[ -d "$RETRO_DEV/compilers/z88dk/src/bin" ]] && {
    export PATH="$RETRO_DEV/compilers/z88dk/src/bin:$PATH"
    export ZCCCFG="$RETRO_DEV/compilers/z88dk/src/lib/config"
}
export PATH="$RETRO_DEV/tools/asm6:$RETRO_DEV/tools/vasm:$RETRO_DEV/tools/flips:$RETRO_DEV/tools/vintage:$RETRO_DEV/sdks/atari:$PATH"
export JAVA_HOME="$(/usr/libexec/java_home -v 21 2>/dev/null)"
echo "  🐱 CAT'S TWEAKER v3.5.1 loaded!"
ENV
chmod +x "$INSTALL_DIR/env.sh"; ok "env.sh"
add_path ""; add_path "# Cat's Tweaker v3.5.1"; add_path "source \"$INSTALL_DIR/env.sh\" 2>/dev/null"

step "VERIFY"
source "$INSTALL_DIR/env.sh" 2>/dev/null
echo ""
command -v curl &>/dev/null && ok "curl"
command -v cc65 &>/dev/null && ok "cc65"
command -v sdcc &>/dev/null && ok "sdcc"
command -v rgbasm &>/dev/null && ok "rgbasm" || warn "rgbasm (run: brew reinstall rgbds)"
command -v z88dk-z80asm &>/dev/null && ok "z88dk" || { [[ -x "$COMPILERS/z88dk/src/bin/z88dk-z80asm" ]] && ok "z88dk (source)" || warn "z88dk"; }
[[ -x "$TOOLS/asm6/asm6" ]] && ok "ASM6"
[[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM"
[[ -x "$SDKS/atari/dasm" ]] && ok "DASM"
[[ -d "$SDKS/gbdk" ]] && ok "GBDK"
[[ -f "$SDKS/nes/neslib/neslib.h" ]] && ok "NESLib"
command -v libdragon &>/dev/null && ok "libdragon"
command -v mips64-elf-gcc &>/dev/null && ok "mips64-elf-gcc" || warn "mips64-elf-gcc (run build_mips.sh)"
[[ -f "$COMPILERS/devkitpro/devkitpro.pkg" ]] && ok "DevkitPro"

echo ""
printf "${G}╔═════════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}║${RST}  ${W}✨ CAT'S TWEAKER v3.5.1 COMPLETE! ✨${RST}                             ${G}║${RST}\n"
printf "${G}║${RST}  ${Y}source ~/.zshrc${RST}                                                  ${G}║${RST}\n"
printf "${G}╚═════════════════════════════════════════════════════════════════════╝${RST}\n"
printf "\n                           ${M}/\\_____/\\${RST}\n"
printf "                          ${M}/  o   o  \\${RST}\n"
printf "                         ${M}( ==  ^  == )${RST}\n"
printf "                          ${M})  ~nya~  (${RST}\n"
printf "                         ${M}(  FINAL   )${RST}\n"
printf "                        ${M}(__(__)___(__)__)${RST}\n\n"

info "POST-INSTALL:"
echo "  1. source ~/.zshrc"
[[ -f "$COMPILERS/devkitpro/devkitpro.pkg" ]] && echo "  2. sudo installer -pkg ~/retro-dev/compilers/devkitpro/devkitpro.pkg -target /"
echo "  3. bash ~/retro-dev/compilers/mips-toolchain/build_mips.sh"
echo ""
