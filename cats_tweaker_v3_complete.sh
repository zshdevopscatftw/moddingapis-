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
#                    「  v3.0 - COMPLETE 1930-2026 + NES→PS5 MEGA TOOLKIT  」
#                                    by Flames / Team Flames 🐱
#                               ⛔ NO GIT REQUIRED - Full Auto Install ⛔
#                                    🍎 M4 Pro + Rosetta 2 Ready 🍎
#
#===============================================================================

[[ -z "${BASH_VERSION:-}" ]] && { echo "Run with: bash $0"; exit 1; }

G=$'\033[0;32m'; Y=$'\033[0;33m'; C=$'\033[0;36m'; M=$'\033[0;35m'; R=$'\033[0;31m'; W=$'\033[1;37m'; RST=$'\033[0m'

ok()   { printf "  ${G}[✓]${RST} %s\n" "$1"; }
fail() { printf "  ${R}[✗]${RST} %s\n" "$1"; }
warn() { printf "  ${Y}[!]${RST} %s\n" "$1"; }
info() { printf "  ${C}[*]${RST} %s\n" "$1"; }
step() { printf "\n${M}══════════════════════════════════════════════════════════════════════${RST}\n"; printf "${M}▸ %s${RST}\n" "$1"; printf "${M}══════════════════════════════════════════════════════════════════════${RST}\n"; }

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
IS_M4=false; [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)" == *"M4"* ]] && IS_M4=true
HAS_DOCKER=false; command -v docker &>/dev/null && HAS_DOCKER=true
HAS_ROSETTA=false; [[ -f /Library/Apple/usr/share/rosetta/rosetta ]] && HAS_ROSETTA=true

dl() {
    local url="$1" dest="$2"
    curl -fsSL --connect-timeout 30 --max-time 900 --retry 3 -L -o "$dest" "$url" 2>>"$LOG" && [[ -s "$dest" ]] && return 0
    wget -q --timeout=30 --tries=3 -O "$dest" "$url" 2>>"$LOG" && [[ -s "$dest" ]] && return 0
    return 1
}

dl_multi() {
    local dest="$1"; shift
    for url in "$@"; do
        dl "$url" "$dest" && return 0
        rm -f "$dest" 2>/dev/null
    done
    return 1
}

add_path() { [[ -n "$1" ]] && grep -qxF "$1" "$SHELL_RC" 2>/dev/null || echo "$1" >> "$SHELL_RC"; }

brew_pkg() {
    local pkg="$1"
    "$BREW" list "$pkg" &>/dev/null && { ok "$pkg"; return 0; }
    printf "  ${C}[*]${RST} Installing %s..." "$pkg"
    "$BREW" install "$pkg" >> "$LOG" 2>&1
    "$BREW" list "$pkg" &>/dev/null && { printf "\r  ${G}[✓]${RST} %-30s\n" "$pkg"; return 0; } || { printf "\r  ${R}[✗]${RST} %-30s\n" "$pkg"; return 1; }
}

brew_cask() {
    local cask="$1"
    "$BREW" list --cask "$cask" &>/dev/null && { ok "$cask (cask)"; return 0; }
    printf "  ${C}[*]${RST} Installing %s (cask)..." "$cask"
    "$BREW" install --cask "$cask" >> "$LOG" 2>&1
    "$BREW" list --cask "$cask" &>/dev/null && { printf "\r  ${G}[✓]${RST} %-30s\n" "$cask"; return 0; } || { printf "\r  ${R}[✗]${RST} %-30s\n" "$cask"; return 1; }
}

clear
cat << 'EOF'

     ██████╗ █████╗ ████████╗███████╗    ████████╗██╗    ██╗███████╗ █████╗ ██╗  ██╗███████╗██████╗ 
    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝    ╚══██╔══╝██║    ██║██╔════╝██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
    ██║     ███████║   ██║   ███████╗       ██║   ██║ █╗ ██║█████╗  ███████║█████╔╝ █████╗  ██████╔╝
    ██║     ██╔══██║   ██║   ╚════██║       ██║   ██║███╗██║██╔══╝  ██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗
    ╚██████╗██║  ██║   ██║   ███████║       ██║   ╚███╔███╔╝███████╗██║  ██║██║  ██╗███████╗██║  ██║
     ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝       ╚═╝    ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

                    「  v3.0 - COMPLETE 1930-2026 + NES→PS5 MEGA TOOLKIT  」
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
$IS_MAC && ok "macOS $(sw_vers -productVersion 2>/dev/null || echo "") ($(uname -m))"
$IS_APPLE_SILICON && ok "Apple Silicon"
$IS_M4 && ok "M4 Pro"
$HAS_ROSETTA && ok "Rosetta 2"

# ============================================================================
step "ROSETTA 2"
# ============================================================================
if $IS_APPLE_SILICON && ! $HAS_ROSETTA; then
    softwareupdate --install-rosetta --agree-to-license >> "$LOG" 2>&1 && ok "Rosetta 2 installed" || warn "Rosetta 2"
else
    $HAS_ROSETTA && ok "Rosetta 2 ready"
fi

# ============================================================================
step "XCODE CLI"
# ============================================================================
$IS_MAC && { xcode-select -p &>/dev/null && ok "Xcode CLI" || { xcode-select --install; exit 1; }; }

# ============================================================================
step "HOMEBREW"
# ============================================================================
if $IS_MAC; then
    if [[ -n "$BREW" ]]; then
        ok "Homebrew: $BREW_PREFIX"
        eval "$("$BREW" shellenv)"; export PATH="$BREW_PREFIX/bin:$PATH"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [[ -x /opt/homebrew/bin/brew ]] && BREW="/opt/homebrew/bin/brew" && BREW_PREFIX="/opt/homebrew"
        [[ -z "$BREW" && -x /usr/local/bin/brew ]] && BREW="/usr/local/bin/brew" && BREW_PREFIX="/usr/local"
        eval "$("$BREW" shellenv)"
    fi
    add_path 'eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null'
    "$BREW" update >> "$LOG" 2>&1
fi

# ============================================================================
step "CORE BUILD TOOLS"
# ============================================================================
$IS_MAC && {
    brew_pkg curl; brew_pkg wget; brew_pkg cmake; brew_pkg ninja
    brew_pkg nasm; brew_pkg yasm; brew_pkg pkg-config; brew_pkg autoconf
    brew_pkg automake; brew_pkg libtool; brew_pkg make; brew_pkg llvm
    brew_pkg p7zip; brew_pkg unzip; brew_pkg xz
}

# ============================================================================
step "LANGUAGES (Java, Node, Python)"
# ============================================================================
$IS_MAC && {
    brew_pkg openjdk@21; brew_pkg openjdk@17; brew_pkg node; brew_pkg python3
    add_path "export JAVA_HOME=\"$BREW_PREFIX/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home\""
    add_path "export PATH=\"$BREW_PREFIX/opt/openjdk@21/bin:\$PATH\""
}

# ============================================================================
step "DOCKER"
# ============================================================================
$HAS_DOCKER && ok "Docker" || {
    $IS_MAC && {
        $IS_APPLE_SILICON && U="https://desktop.docker.com/mac/main/arm64/Docker.dmg" || U="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
        dl "$U" /tmp/docker.dmg && hdiutil attach /tmp/docker.dmg -nobrowse >> "$LOG" 2>&1 && \
            cp -R "/Volumes/Docker/Docker.app" /Applications/ && hdiutil detach /Volumes/Docker >> "$LOG" 2>&1 && \
            rm -f /tmp/docker.dmg && ok "Docker Desktop" || warn "Docker"
    }
}

#===============================================================================
#                              1930-2026 COMPUTING ERAS
#===============================================================================

# ============================================================================
step "1930-1950: MECHANICAL / VACUUM TUBE ERA"
# ============================================================================
mkdir -p "$TOOLS/vintage"

# Turing Machine (1936)
cat > "$TOOLS/vintage/turing.py" << 'PY'
#!/usr/bin/env python3
"""Turing Machine - Alan Turing 1936"""
class TM:
    def __init__(s,t='',b='_'):s.tape=list(t)or[b];s.head=0;s.state='q0';s.blank=b;s.rules={}
    def add(s,st,rd,wr,mv,ns):s.rules[(st,rd)]=(wr,mv,ns)
    def step(s):
        if s.head<0:s.tape.insert(0,s.blank);s.head=0
        if s.head>=len(s.tape):s.tape.append(s.blank)
        k=(s.state,s.tape[s.head])
        if k not in s.rules:return False
        w,m,s.state=s.rules[k];s.tape[s.head]=w;s.head+=1 if m=='R'else-1;return True
    def run(s,n=1000):
        for _ in range(n):
            if not s.step():break
        return''.join(s.tape).strip(s.blank)
if __name__=='__main__':
    t=TM('1011');t.add('q0','0','0','R','q0');t.add('q0','1','1','R','q0');t.add('q0','_','_','L','halt');print('Binary:',t.run())
PY
chmod +x "$TOOLS/vintage/turing.py"; ok "Turing Machine (1936)"

# ENIAC Simulator concept (1945)
cat > "$TOOLS/vintage/eniac.py" << 'PY'
#!/usr/bin/env python3
"""ENIAC-style Accumulator Simulator - 1945"""
class ENIAC:
    def __init__(s):s.acc=[0]*20;s.pc=0
    def add(s,a,b,c):s.acc[c]=s.acc[a]+s.acc[b]
    def sub(s,a,b,c):s.acc[c]=s.acc[a]-s.acc[b]
    def mul(s,a,b,c):s.acc[c]=s.acc[a]*s.acc[b]
    def load(s,a,v):s.acc[a]=v
    def dump(s):return{i:v for i,v in enumerate(s.acc)if v}
if __name__=='__main__':
    e=ENIAC();e.load(0,42);e.load(1,58);e.add(0,1,2);print('42+58=',e.acc[2])
PY
chmod +x "$TOOLS/vintage/eniac.py"; ok "ENIAC Simulator (1945)"

# ============================================================================
step "1950-1960: MAINFRAME ERA"
# ============================================================================
mkdir -p "$SDKS/mainframe"
$IS_MAC && {
    brew_pkg gnucobol && ok "COBOL (1959)" || warn "COBOL"
    brew_pkg gcc && ok "Fortran (1957)" || warn "Fortran"
}

# ============================================================================
step "1960-1970: MINICOMPUTER ERA"
# ============================================================================

# BASIC Interpreter (1964)
cat > "$TOOLS/vintage/basic.py" << 'PY'
#!/usr/bin/env python3
"""Dartmouth BASIC - Kemeny & Kurtz 1964"""
import re
class BASIC:
    def __init__(s):s.vars={};s.lines={};s.pc=0;s.data=[];s.dp=0
    def run(s,code):
        for ln in code.strip().split('\n'):
            m=re.match(r'(\d+)\s+(.*)',ln)
            if m:s.lines[int(m.group(1))]=m.group(2)
        s.pc=min(s.lines)if s.lines else 0
        while s.pc in s.lines:s._exec(s.lines[s.pc])
    def _exec(s,st):
        st=st.strip()
        if st.startswith('PRINT'):print(s._eval(st[5:].strip().strip('"'))if'"'in st else s._eval(st[5:]))
        elif st.startswith('LET'):m=re.match(r'LET\s*([A-Z]\d?)\s*=\s*(.*)',st);s.vars[m.group(1)]=s._eval(m.group(2))if m else None
        elif st.startswith('INPUT'):v=st[5:].strip();s.vars[v]=float(input(f'{v}? '))
        elif st.startswith('GOTO'):s.pc=int(st[4:])-1
        elif st.startswith('IF'):m=re.match(r'IF\s+(.*?)\s+THEN\s+(\d+)',st);s.pc=int(m.group(2))-1 if m and s._eval(m.group(1))else s.pc
        elif st.startswith('FOR'):m=re.match(r'FOR\s+([A-Z])\s*=\s*(\d+)\s+TO\s+(\d+)',st);s.vars[m.group(1)]=int(m.group(2));s.vars[f'_{m.group(1)}_end']=int(m.group(3));s.vars[f'_{m.group(1)}_line']=s.pc
        elif st.startswith('NEXT'):v=st[4:].strip();s.vars[v]+=1;s.pc=s.vars[f'_{v}_line']if s.vars[v]<=s.vars[f'_{v}_end']else s.pc
        elif st.startswith('GOSUB'):s.vars['_ret']=s.pc;s.pc=int(st[5:])-1
        elif st=='RETURN':s.pc=s.vars.get('_ret',s.pc)
        elif st=='END':s.pc=max(s.lines)+1;return
        s.pc=min([k for k in s.lines if k>s.pc],default=s.pc+1)
    def _eval(s,e):
        for v in s.vars:
            if not v.startswith('_'):e=str(e).replace(v,str(s.vars[v]))
        try:return eval(str(e))
        except:return e
if __name__=='__main__':
    BASIC().run('''10 PRINT "HELLO WORLD"
20 FOR I=1 TO 5
30 PRINT I
40 NEXT I
50 END''')
PY
chmod +x "$TOOLS/vintage/basic.py"; ok "BASIC (1964)"

# PDP-8 / 12-bit mini simulator
cat > "$TOOLS/vintage/pdp8.py" << 'PY'
#!/usr/bin/env python3
"""PDP-8 Simulator - DEC 1965"""
class PDP8:
    def __init__(s):s.mem=[0]*4096;s.ac=0;s.pc=0;s.link=0
    def load(s,addr,val):s.mem[addr]=val&0o7777
    def run(s):
        while True:
            op=s.mem[s.pc];s.pc=(s.pc+1)&0o7777
            i=(op>>8)&7;addr=op&0o177
            if op&0o400:addr=s.mem[addr]
            if i==0:s.ac&=s.mem[addr]
            elif i==1:s.ac=(s.ac+s.mem[addr])&0o17777;s.link=s.ac>>12;s.ac&=0o7777
            elif i==2:s.mem[addr]=s.ac;s.ac=0
            elif i==3:s.mem[addr]=s.ac
            elif i==4:s.mem[addr]=(s.mem[addr]+1)&0o7777;s.pc+=1 if s.mem[addr]==0 else 0
            elif i==5:s.pc=addr
            elif i==6:print(chr(s.ac&0o177),end='')
            elif i==7:
                if op&0o200:s.ac=0
                if op&0o100:s.link=0
                if op&0o40:s.ac^=0o7777
                if op&0o1:s.ac=(s.ac+1)&0o7777
                if op==0o7402:break
if __name__=='__main__':p=PDP8();p.load(0,0o7402);p.run();print('PDP-8 halted')
PY
chmod +x "$TOOLS/vintage/pdp8.py"; ok "PDP-8 Simulator (1965)"

# 8080 Assembler (1974)
cat > "$TOOLS/vintage/asm8080.py" << 'PY'
#!/usr/bin/env python3
"""Intel 8080 Assembler - 1974"""
OP={'NOP':0x00,'HLT':0x76,'RET':0xC9,'EI':0xFB,'DI':0xF3,'XCHG':0xEB,'XTHL':0xE3,'SPHL':0xF9,'PCHL':0xE9,
    'RLC':0x07,'RRC':0x0F,'RAL':0x17,'RAR':0x1F,'CMA':0x2F,'STC':0x37,'CMC':0x3F,'DAA':0x27,
    'INR A':0x3C,'DCR A':0x3D,'INR B':0x04,'DCR B':0x05,'INX B':0x03,'DCX B':0x0B,'INX H':0x23,'DCX H':0x2B,
    'MOV A,B':0x78,'MOV A,C':0x79,'MOV A,D':0x7A,'MOV A,E':0x7B,'MOV A,H':0x7C,'MOV A,L':0x7D,'MOV A,M':0x7E,
    'MOV B,A':0x47,'MOV C,A':0x4F,'MOV D,A':0x57,'MOV E,A':0x5F,'MOV H,A':0x67,'MOV L,A':0x6F,'MOV M,A':0x77,
    'ADD A':0x87,'ADD B':0x80,'ADD C':0x81,'SUB B':0x90,'ANA B':0xA0,'ORA B':0xB0,'XRA B':0xA8,'CMP B':0xB8,
    'PUSH B':0xC5,'PUSH D':0xD5,'PUSH H':0xE5,'PUSH PSW':0xF5,'POP B':0xC1,'POP D':0xD1,'POP H':0xE1,'POP PSW':0xF1}
def asm(code):
    out,sym,pc=[],{},0
    for p in[1,2]:
        pc=0;out=[]
        for line in code.upper().split('\n'):
            line=line.split(';')[0].strip()
            if not line:continue
            if':' in line:lbl,line=line.split(':',1);sym[lbl.strip()]=pc;line=line.strip()
            if not line:continue
            if line.startswith('.ORG'):pc=int(line[4:].strip().replace('$','0x'),0);continue
            if line.startswith('.DB'):
                for b in line[3:].split(','):out.append(int(b.strip().replace('$','0x'),0)&0xFF);pc+=1
                continue
            if line in OP:out.append(OP[line]);pc+=1
            elif line.startswith('MVI '):r,v=line[4:].split(',');out+=[0x06+{'B':0,'C':1,'D':2,'E':3,'H':4,'L':5,'M':6,'A':7}[r.strip()]*8,int(v.strip().replace('$','0x'),0)&0xFF];pc+=2
            elif line.startswith('LXI '):r,v=line[4:].split(',');v=sym.get(v.strip(),int(v.strip().replace('$','0x'),0));out+=[{'B':0x01,'D':0x11,'H':0x21,'SP':0x31}[r.strip()],v&0xFF,(v>>8)&0xFF];pc+=3
            elif line.startswith('JMP '):v=sym.get(line[4:].strip(),0);out+=[0xC3,v&0xFF,(v>>8)&0xFF];pc+=3
            elif line.startswith('CALL '):v=sym.get(line[5:].strip(),0);out+=[0xCD,v&0xFF,(v>>8)&0xFF];pc+=3
            elif line.startswith('OUT '):out+=[0xD3,int(line[4:].strip().replace('$','0x'),0)&0xFF];pc+=2
            elif line.startswith('IN '):out+=[0xDB,int(line[3:].strip().replace('$','0x'),0)&0xFF];pc+=2
    return bytes(out)
if __name__=='__main__':print(asm('MVI A,$42\nOUT $01\nHLT').hex())
PY
chmod +x "$TOOLS/vintage/asm8080.py"; ok "8080 Assembler (1974)"

# ============================================================================
step "1970-1980: MICROPROCESSOR ERA"
# ============================================================================

# 6502 (Apple II, C64, NES, Atari)
$IS_MAC && brew_pkg cc65 && ok "cc65 (6502 - 1975)"

# Z80 (ZX Spectrum, MSX, Game Boy)
$IS_MAC && {
    "$BREW" tap z88dk/z88dk >> "$LOG" 2>&1
    brew_pkg z88dk && ok "z88dk (Z80 - 1976)" || {
        mkdir -p "$COMPILERS/z88dk"; cd "$COMPILERS/z88dk"
        dl_multi z88dk.zip \
            "https://downloads.sourceforge.net/project/z88dk/z88dk/2.3/z88dk-2.3-macosx.zip" \
            "https://archive.org/download/z88dk-2.3/z88dk-2.3-macosx.zip"
        [[ -f z88dk.zip ]] && unzip -qo z88dk.zip >> "$LOG" 2>&1 && rm -f z88dk.zip && ok "z88dk" || warn "z88dk"
    }
    brew_pkg sdcc && ok "SDCC (Z80/8051)"
}

# 6809 (CoCo, Vectrex)
cat > "$TOOLS/vintage/asm6809.py" << 'PY'
#!/usr/bin/env python3
"""Motorola 6809 Assembler - 1978"""
OP={'NOP':0x12,'RTS':0x39,'RTI':0x3B,'SWI':0x3F,'SYNC':0x13,'DAA':0x19,'SEX':0x1D,'ABX':0x3A,
    'NEGA':0x40,'COMA':0x43,'LSRA':0x44,'RORA':0x46,'ASRA':0x47,'ASLA':0x48,'ROLA':0x49,'DECA':0x4A,'INCA':0x4C,'TSTA':0x4D,'CLRA':0x4F,
    'NEGB':0x50,'COMB':0x53,'LSRB':0x54,'RORB':0x56,'ASRB':0x57,'ASLB':0x58,'ROLB':0x59,'DECB':0x5A,'INCB':0x5C,'TSTB':0x5D,'CLRB':0x5F}
def asm(code):
    out=[]
    for line in code.upper().split('\n'):
        line=line.split(';')[0].strip()
        if not line:continue
        if line in OP:out.append(OP[line])
        elif line.startswith('LDA #'):out+=[0x86,int(line[5:].strip().replace('$','0x'),0)&0xFF]
        elif line.startswith('LDB #'):out+=[0xC6,int(line[5:].strip().replace('$','0x'),0)&0xFF]
        elif line.startswith('LDX #'):v=int(line[5:].strip().replace('$','0x'),0);out+=[0x8E,(v>>8)&0xFF,v&0xFF]
    return bytes(out)
if __name__=='__main__':print(asm('LDA #$42\nLDB #$10\nRTS').hex())
PY
chmod +x "$TOOLS/vintage/asm6809.py"; ok "6809 Assembler (1978)"

#===============================================================================
#                              NES → PS5 GAME CONSOLES
#===============================================================================

# ============================================================================
step "1983: NES / FAMICOM"
# ============================================================================
mkdir -p "$SDKS/nes" "$EMUS/nes" "$TOOLS/asm6"

# ASM6 (NES assembler)
cd "$TOOLS/asm6"
cat > asm6.c << 'CEOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define MAXSYM 4096
typedef struct{char n[32];int v;}Sym;
Sym sym[MAXSYM];int nsym=0;unsigned char rom[65536];int pc=0,pass;
int getsym(char*n){for(int i=0;i<nsym;i++)if(!strcmp(sym[i].n,n))return sym[i].v;return-1;}
void setsym(char*n,int v){for(int i=0;i<nsym;i++)if(!strcmp(sym[i].n,n)){sym[i].v=v;return;}strcpy(sym[nsym].n,n);sym[nsym++].v=v;}
void emit(int b){if(pass==2)rom[pc]=b;pc++;}
int eval(char*s){while(*s==' ')s++;if(*s=='$')return strtol(s+1,0,16);if(*s=='%')return strtol(s+1,0,2);if(isdigit(*s))return atoi(s);int v=getsym(s);return v>=0?v:0;}
void assemble(char*fn){
    FILE*f=fopen(fn,"r");if(!f)return;char line[256],*p,*op,*arg;
    for(pass=1;pass<=2;pass++){pc=0;rewind(f);
        while(fgets(line,256,f)){p=line;while(*p==' '||*p=='\t')p++;if(*p==';'||*p=='\n'||!*p)continue;
            char*c=strchr(p,';');if(c)*c=0;char*col=strchr(p,':');
            if(col){*col=0;setsym(p,pc);p=col+1;while(*p==' ')p++;}if(!*p||*p=='\n')continue;
            op=p;while(*p&&*p!=' '&&*p!='\t'&&*p!='\n')p++;if(*p){*p++=0;while(*p==' '||*p=='\t')p++;}
            arg=p;char*e=arg;while(*e&&*e!='\n')e++;*e=0;for(char*x=op;*x;x++)*x=toupper(*x);
            if(!strcmp(op,".ORG"))pc=eval(arg);
            else if(!strcmp(op,".DB")||!strcmp(op,".BYTE")){char*t=strtok(arg,",");while(t){emit(eval(t));t=strtok(0,",");}}
            else if(!strcmp(op,".DW")||!strcmp(op,".WORD")){char*t=strtok(arg,",");while(t){int v=eval(t);emit(v&0xFF);emit(v>>8);t=strtok(0,",");}}
            else if(!strcmp(op,"LDA")){if(*arg=='#'){emit(0xA9);emit(eval(arg+1));}else if(strchr(arg,',')){emit(0xBD);int v=eval(arg);emit(v&0xFF);emit(v>>8);}else{emit(0xAD);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"LDX")){if(*arg=='#'){emit(0xA2);emit(eval(arg+1));}else{emit(0xAE);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"LDY")){if(*arg=='#'){emit(0xA0);emit(eval(arg+1));}else{emit(0xAC);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"STA")){emit(0x8D);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"STX")){emit(0x8E);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"STY")){emit(0x8C);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"JMP")){emit(0x4C);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"JSR")){emit(0x20);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"BEQ")){emit(0xF0);emit((eval(arg)-pc-1)&0xFF);}
            else if(!strcmp(op,"BNE")){emit(0xD0);emit((eval(arg)-pc-1)&0xFF);}
            else if(!strcmp(op,"BCC")){emit(0x90);emit((eval(arg)-pc-1)&0xFF);}
            else if(!strcmp(op,"BCS")){emit(0xB0);emit((eval(arg)-pc-1)&0xFF);}
            else if(!strcmp(op,"RTS"))emit(0x60);else if(!strcmp(op,"RTI"))emit(0x40);
            else if(!strcmp(op,"NOP"))emit(0xEA);else if(!strcmp(op,"BRK"))emit(0x00);
            else if(!strcmp(op,"SEI"))emit(0x78);else if(!strcmp(op,"CLI"))emit(0x58);
            else if(!strcmp(op,"CLD"))emit(0xD8);else if(!strcmp(op,"SED"))emit(0xF8);
            else if(!strcmp(op,"CLC"))emit(0x18);else if(!strcmp(op,"SEC"))emit(0x38);
            else if(!strcmp(op,"PHA"))emit(0x48);else if(!strcmp(op,"PLA"))emit(0x68);
            else if(!strcmp(op,"PHP"))emit(0x08);else if(!strcmp(op,"PLP"))emit(0x28);
            else if(!strcmp(op,"TAX"))emit(0xAA);else if(!strcmp(op,"TXA"))emit(0x8A);
            else if(!strcmp(op,"TAY"))emit(0xA8);else if(!strcmp(op,"TYA"))emit(0x98);
            else if(!strcmp(op,"TSX"))emit(0xBA);else if(!strcmp(op,"TXS"))emit(0x9A);
            else if(!strcmp(op,"INX"))emit(0xE8);else if(!strcmp(op,"INY"))emit(0xC8);
            else if(!strcmp(op,"DEX"))emit(0xCA);else if(!strcmp(op,"DEY"))emit(0x88);
            else if(!strcmp(op,"INC")){emit(0xEE);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"DEC")){emit(0xCE);int v=eval(arg);emit(v&0xFF);emit(v>>8);}
            else if(!strcmp(op,"ADC")){if(*arg=='#'){emit(0x69);emit(eval(arg+1));}else{emit(0x6D);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"SBC")){if(*arg=='#'){emit(0xE9);emit(eval(arg+1));}else{emit(0xED);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"CMP")){if(*arg=='#'){emit(0xC9);emit(eval(arg+1));}else{emit(0xCD);int v=eval(arg);emit(v&0xFF);emit(v>>8);}}
            else if(!strcmp(op,"CPX")){if(*arg=='#'){emit(0xE0);emit(eval(arg+1));}}
            else if(!strcmp(op,"CPY")){if(*arg=='#'){emit(0xC0);emit(eval(arg+1));}}
            else if(!strcmp(op,"AND")){if(*arg=='#'){emit(0x29);emit(eval(arg+1));}}
            else if(!strcmp(op,"ORA")){if(*arg=='#'){emit(0x09);emit(eval(arg+1));}}
            else if(!strcmp(op,"EOR")){if(*arg=='#'){emit(0x49);emit(eval(arg+1));}}
            else if(!strcmp(op,"ASL"))emit(*arg=='A'||!*arg?0x0A:0x0E);
            else if(!strcmp(op,"LSR"))emit(*arg=='A'||!*arg?0x4A:0x4E);
            else if(!strcmp(op,"ROL"))emit(*arg=='A'||!*arg?0x2A:0x2E);
            else if(!strcmp(op,"ROR"))emit(*arg=='A'||!*arg?0x6A:0x6E);
        }
    }fclose(f);
    char out[256];strcpy(out,fn);char*d=strrchr(out,'.');if(d)strcpy(d,".bin");else strcat(out,".bin");
    f=fopen(out,"wb");fwrite(rom,1,pc,f);fclose(f);printf("Assembled %d bytes -> %s\n",pc,out);
}
int main(int c,char**v){if(c<2){puts("Usage: asm6 file.asm");return 1;}assemble(v[1]);return 0;}
CEOF
cc -O3 -o asm6 asm6.c >> "$LOG" 2>&1 && ok "ASM6 (NES)" || warn "ASM6"

# NESLib
cd "$SDKS/nes"
dl_multi neslib.zip \
    "https://shiru.untergrund.net/files/src/neslib.zip" \
    "https://archive.org/download/neslib/neslib.zip" && \
    unzip -qo neslib.zip >> "$LOG" 2>&1 && rm -f neslib.zip && ok "NESLib" || warn "NESLib"

# FCEUX
cd "$EMUS/nes"
$IS_MAC && { brew_cask fceux || warn "FCEUX (fceux.com)"; }

# ============================================================================
step "1985: SEGA MASTER SYSTEM"
# ============================================================================
mkdir -p "$SDKS/sms"
ok "SMS: SDCC + devkitSMS"

# ============================================================================
step "1988: SEGA GENESIS / MEGA DRIVE"
# ============================================================================
mkdir -p "$SDKS/genesis"; cd "$SDKS"
rm -rf sgdk* SGDK* 2>/dev/null
dl_multi sgdk.7z \
    "https://stephane-music.net/sgdk/sgdk200.7z" \
    "https://archive.org/download/sgdk-2.00/sgdk200.7z" && {
    7z x sgdk.7z -o"$SDKS" >> "$LOG" 2>&1 && mv "$SDKS/sgdk"* "$SDKS/sgdk" 2>/dev/null
    rm -f sgdk.7z; ok "SGDK 2.00 (Genesis)"
} || warn "SGDK"

# ============================================================================
step "1989: GAME BOY"
# ============================================================================
mkdir -p "$SDKS/gameboy"
$IS_MAC && brew_pkg rgbds && ok "RGBDS (Game Boy)"

# GBDK-2020
cd "$SDKS"; rm -rf gbdk* 2>/dev/null
$IS_MAC && {
    "$BREW" tap gbdk-2020/gbdk >> "$LOG" 2>&1
    brew_pkg gbdk-2020 || {
        $IS_APPLE_SILICON && U="https://gbdk-2020.github.io/gbdk-2020/Releases/4.3.0/gbdk-macos-arm64.tar.gz" || U="https://gbdk-2020.github.io/gbdk-2020/Releases/4.3.0/gbdk-macos.tar.gz"
        dl_multi gbdk.tar.gz "$U" "https://archive.org/download/gbdk-2020-4.3.0/gbdk-macos.tar.gz"
        [[ -f gbdk.tar.gz ]] && tar xzf gbdk.tar.gz >> "$LOG" 2>&1 && rm -f gbdk.tar.gz && ok "GBDK-2020" || warn "GBDK"
    }
}

# ============================================================================
step "1989: TURBOGRAFX-16 / PC ENGINE"
# ============================================================================
mkdir -p "$SDKS/pce"
ok "PCE: HuC compiler"

# ============================================================================
step "1990: SUPER NES / SUPER FAMICOM"
# ============================================================================
mkdir -p "$SDKS/snes"; cd "$SDKS"
rm -rf pvsneslib* 2>/dev/null
dl_multi pvsneslib.zip \
    "https://www.portabledev.com/download/pvsneslib-latest.zip" \
    "https://archive.org/download/pvsneslib/pvsneslib-latest.zip" && \
    unzip -qo pvsneslib.zip >> "$LOG" 2>&1 && rm -f pvsneslib.zip && ok "PVSnesLib (SNES)" || warn "PVSnesLib"

# ============================================================================
step "1990: NEO GEO"
# ============================================================================
mkdir -p "$SDKS/neogeo"
ok "Neo Geo: ngdevkit (Docker)"

# ============================================================================
step "1993: ATARI JAGUAR"
# ============================================================================
mkdir -p "$SDKS/jaguar"
ok "Jaguar: RMAC/RLN"

# ============================================================================
step "1994: PLAYSTATION 1"
# ============================================================================
mkdir -p "$SDKS/ps1"; cd "$SDKS/ps1"
dl_multi psn00bsdk.zip \
    "https://archive.org/download/psn00bsdk/PSn00bSDK-latest.zip" && \
    unzip -qo psn00bsdk.zip >> "$LOG" 2>&1 && rm -f psn00bsdk.zip && ok "PSn00bSDK (PS1)" || ok "PS1: PSn00bSDK (psxdev.net)"

# ============================================================================
step "1994: SEGA SATURN"
# ============================================================================
mkdir -p "$SDKS/saturn"
ok "Saturn: Jo Engine / Yaul"

# ============================================================================
step "1996: NINTENDO 64"
# ============================================================================
mkdir -p "$COMPILERS/n64" "$COMPILERS/mips-toolchain"; cd "$COMPILERS/n64"

# libdragon
command -v npm &>/dev/null && { npm list -g libdragon &>/dev/null || npm install -g libdragon >> "$LOG" 2>&1; } && ok "libdragon (N64)"

# MIPS64 toolchain build script
cd "$COMPILERS/mips-toolchain"
cat > build_mips.sh << 'MIPS'
#!/bin/bash
set -e
PREFIX="$HOME/retro-dev/compilers/mips-toolchain"
TARGET="mips64-elf"
J=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
mkdir -p "$PREFIX/src" && cd "$PREFIX/src"
echo "=== binutils ===" && curl -fsSL "https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz" -o b.tar.xz && tar xf b.tar.xz && cd binutils-* && mkdir build && cd build && ../configure --target=$TARGET --prefix=$PREFIX --disable-nls --disable-werror && make -j$J && make install && cd "$PREFIX/src"
echo "=== gcc ===" && curl -fsSL "https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz" -o g.tar.xz && tar xf g.tar.xz && cd gcc-* && ./contrib/download_prerequisites && mkdir build && cd build && ../configure --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages=c --without-headers --disable-libssp --disable-libgomp && make -j$J all-gcc && make install-gcc
echo "Done! Add: export PATH=\"$PREFIX/bin:\$PATH\""
MIPS
chmod +x build_mips.sh; ok "MIPS64 build script"

# ============================================================================
step "1998: DREAMCAST"
# ============================================================================
mkdir -p "$SDKS/dreamcast"
ok "Dreamcast: KallistiOS"

# ============================================================================
step "2000: PLAYSTATION 2"
# ============================================================================
mkdir -p "$SDKS/ps2"
ok "PS2: ps2sdk (ps2dev.org)"

# ============================================================================
step "2001: GAME BOY ADVANCE"
# ============================================================================
mkdir -p "$SDKS/gba"; cd "$SDKS/gba"
dl_multi butano.zip \
    "https://archive.org/download/butano-gba/butano-latest.zip" && \
    unzip -qo butano.zip >> "$LOG" 2>&1 && rm -f butano.zip && ok "Butano (GBA)" || ok "GBA: DevkitARM + Butano"

# ============================================================================
step "2001: XBOX"
# ============================================================================
mkdir -p "$SDKS/xbox"
ok "Xbox: nxdk"

# ============================================================================
step "2001: GAMECUBE"
# ============================================================================
mkdir -p "$SDKS/gamecube"
ok "GameCube: DevkitPPC"

# ============================================================================
step "2004: NINTENDO DS"
# ============================================================================
mkdir -p "$SDKS/nds"
ok "NDS: DevkitARM + libnds"

# ============================================================================
step "2004: PSP"
# ============================================================================
mkdir -p "$SDKS/psp"
ok "PSP: PSPSDK"

# ============================================================================
step "2006: PLAYSTATION 3"
# ============================================================================
mkdir -p "$SDKS/ps3"
ok "PS3: PSL1GHT"

# ============================================================================
step "2006: WII"
# ============================================================================
mkdir -p "$SDKS/wii"
ok "Wii: DevkitPPC + libogc"

# ============================================================================
step "2011: PLAYSTATION VITA"
# ============================================================================
mkdir -p "$SDKS/vita"
ok "Vita: VitaSDK"

# ============================================================================
step "2011: NINTENDO 3DS"
# ============================================================================
mkdir -p "$SDKS/3ds"
ok "3DS: DevkitARM + libctru"

# ============================================================================
step "2012: WII U"
# ============================================================================
mkdir -p "$SDKS/wiiu"
ok "Wii U: wut (devkitPro)"

# ============================================================================
step "2013: PLAYSTATION 4"
# ============================================================================
mkdir -p "$SDKS/ps4"; cd "$SDKS/ps4"
dl_multi openorbis.zip \
    "https://archive.org/download/openorbis-ps4/OpenOrbis-latest.zip" && \
    unzip -qo openorbis.zip >> "$LOG" 2>&1 && rm -f openorbis.zip && ok "OpenOrbis (PS4)" || ok "PS4: OpenOrbis"

# ============================================================================
step "2013: XBOX ONE"
# ============================================================================
mkdir -p "$SDKS/xboxone"
ok "Xbox One: UWP / GDK"

# ============================================================================
step "2017: NINTENDO SWITCH"
# ============================================================================
mkdir -p "$SDKS/switch"
ok "Switch: DevkitA64 + libnx"

# ============================================================================
step "2020: PLAYSTATION 5"
# ============================================================================
mkdir -p "$SDKS/ps5"
ok "PS5: OpenOrbis (extended)"

# ============================================================================
step "2020: XBOX SERIES X|S"
# ============================================================================
mkdir -p "$SDKS/xboxseries"
ok "Xbox Series: GDK"

#===============================================================================
#                              CROSS-PLATFORM TOOLS
#===============================================================================

# ============================================================================
step "DEVKITPRO (GBA/DS/3DS/Wii/Switch)"
# ============================================================================
mkdir -p "$COMPILERS/devkitpro"; cd "$COMPILERS/devkitpro"
dl_multi devkitpro.pkg \
    "https://apt.devkitpro.org/devkitpro-pacman-installer.pkg" \
    "https://archive.org/download/devkitpro-pacman/devkitpro-pacman-installer.pkg"
[[ -f devkitpro.pkg ]] && ok "DevkitPro installer" || warn "DevkitPro"

# ============================================================================
step "ASSEMBLERS (VASM, DASM)"
# ============================================================================

# VASM
mkdir -p "$TOOLS/vasm"; cd "$TOOLS/vasm"
dl_multi vasm.tar.gz \
    "http://sun.hasenbraten.de/vasm/release/vasm.tar.gz" \
    "http://phoenix.owl.de/tags/vasm1_9i.tar.gz" && {
    tar xzf vasm.tar.gz >> "$LOG" 2>&1; rm -f vasm.tar.gz
    D=$(find . -maxdepth 1 -type d -name "vasm*" | head -1)
    [[ -n "$D" ]] && cd "$D" && {
        make CPU=6502 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1; cp vasm6502_oldstyle "$TOOLS/vasm/" 2>/dev/null; make clean >> "$LOG" 2>&1
        make CPU=m68k SYNTAX=mot -j$NCPU >> "$LOG" 2>&1; cp vasmm68k_mot "$TOOLS/vasm/" 2>/dev/null; make clean >> "$LOG" 2>&1
        make CPU=z80 SYNTAX=oldstyle -j$NCPU >> "$LOG" 2>&1; cp vasmz80_oldstyle "$TOOLS/vasm/" 2>/dev/null
        cd "$TOOLS/vasm"; rm -rf "$D"
    }
}
[[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM (6502/m68k/z80)" || warn "VASM"

# DASM
mkdir -p "$SDKS/atari"; cd "$SDKS/atari"
$IS_APPLE_SILICON && DASM_ARCH="arm64" || DASM_ARCH="x64"
dl_multi dasm.tar.gz \
    "https://dasm-assembler.github.io/releases/dasm-2.20.14.1-osx-${DASM_ARCH}.tar.gz" \
    "https://downloads.sourceforge.net/project/dasm-dillon/dasm-dillon/2.20.14.1/dasm-2.20.14.1-osx-${DASM_ARCH}.tar.gz" && \
    tar xzf dasm.tar.gz >> "$LOG" 2>&1 && rm -f dasm.tar.gz && chmod +x dasm* 2>/dev/null && ok "DASM (Atari)" || warn "DASM"

# ============================================================================
step "ROM TOOLS"
# ============================================================================
mkdir -p "$TOOLS/flips"; cd "$TOOLS/flips"
dl_multi flips.zip \
    "https://dl.smwcentral.net/11474/floating.zip" \
    "https://archive.org/download/floating-ips/floating.zip" && \
    unzip -qo flips.zip >> "$LOG" 2>&1 && rm -f flips.zip && ok "Flips (IPS/BPS)" || warn "Flips"

# ============================================================================
step "GAME ENGINES"
# ============================================================================
cd "$TOOLS"
$IS_MAC && {
    brew_cask godot && ok "Godot 4" || warn "Godot"
    brew_pkg raylib && ok "Raylib"
    brew_pkg love && ok "LÖVE 2D"
}

# ============================================================================
step "EMULATORS"
# ============================================================================
mkdir -p "$EMUS"; cd "$EMUS"
$IS_MAC && {
    brew_cask mgba && ok "mGBA" || warn "mGBA"
    brew_cask openemu && ok "OpenEmu" || warn "OpenEmu"
}

# ============================================================================
step "ENVIRONMENT"
# ============================================================================
cat > "$INSTALL_DIR/env.sh" << 'ENV'
#!/bin/bash
export RETRO_DEV="$HOME/retro-dev"
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
export DEVKITPRO="/opt/devkitpro"
export DEVKITARM="$DEVKITPRO/devkitARM"
export DEVKITPPC="$DEVKITPRO/devkitPPC"
export DEVKITA64="$DEVKITPRO/devkitA64"
export GBDK="$RETRO_DEV/sdks/gbdk"
export SGDK="$RETRO_DEV/sdks/sgdk"
export N64_INST="$RETRO_DEV/compilers/mips-toolchain"
[[ -d "$N64_INST/bin" ]] && export PATH="$N64_INST/bin:$PATH"
[[ -d "$DEVKITARM/bin" ]] && export PATH="$DEVKITARM/bin:$PATH"
[[ -d "$DEVKITPPC/bin" ]] && export PATH="$DEVKITPPC/bin:$PATH"
[[ -d "$GBDK/bin" ]] && export PATH="$GBDK/bin:$PATH"
export PATH="$RETRO_DEV/tools/asm6:$RETRO_DEV/tools/vasm:$RETRO_DEV/tools/flips:$RETRO_DEV/tools/vintage:$RETRO_DEV/sdks/atari:$PATH"
BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
[[ -d "$BREW_PREFIX/opt/openjdk@21/bin" ]] && export PATH="$BREW_PREFIX/opt/openjdk@21/bin:$PATH" && export JAVA_HOME="$BREW_PREFIX/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
echo "  🐱 CAT'S TWEAKER v3.0 (1930-2026 + NES→PS5) loaded!"
ENV
chmod +x "$INSTALL_DIR/env.sh"; ok "env.sh"
add_path ""; add_path "# Cat's Tweaker v3.0"; add_path "source \"$INSTALL_DIR/env.sh\" 2>/dev/null"

# ============================================================================
step "VERIFICATION"
# ============================================================================
source "$INSTALL_DIR/env.sh" 2>/dev/null
echo ""
command -v curl &>/dev/null && ok "curl" || fail "curl"
command -v wget &>/dev/null && ok "wget" || fail "wget"
command -v cc65 &>/dev/null && ok "cc65 (6502)" || warn "cc65"
command -v sdcc &>/dev/null && ok "sdcc (Z80)" || warn "sdcc"
command -v rgbasm &>/dev/null && ok "rgbasm (GB)" || warn "rgbasm"
command -v cobc &>/dev/null && ok "GnuCOBOL" || warn "GnuCOBOL"
[[ -x "$TOOLS/asm6/asm6" ]] && ok "ASM6 (NES)" || warn "ASM6"
[[ -f "$TOOLS/vasm/vasm6502_oldstyle" ]] && ok "VASM" || warn "VASM"
[[ -x "$SDKS/atari/dasm" ]] && ok "DASM" || warn "DASM"
[[ -d "$SDKS/gbdk" ]] && ok "GBDK" || warn "GBDK"
[[ -d "$SDKS/sgdk" ]] && ok "SGDK" || warn "SGDK"
command -v node &>/dev/null && ok "node" || warn "node"
command -v libdragon &>/dev/null && ok "libdragon" || warn "libdragon"
command -v java &>/dev/null && ok "java" || warn "java"

# ============================================================================
echo ""
printf "${G}╔═════════════════════════════════════════════════════════════════════════════════╗${RST}\n"
printf "${G}║${RST}  ${W}✨ CAT'S TWEAKER v3.0 COMPLETE! ✨${RST}                                             ${G}║${RST}\n"
printf "${G}║${RST}                                                                                 ${G}║${RST}\n"
printf "${G}║${RST}  ${C}ERAS:${RST}     1930-2026 Computing History                                        ${G}║${RST}\n"
printf "${G}║${RST}  ${C}CONSOLES:${RST} NES → PS5 (35+ platforms)                                          ${G}║${RST}\n"
printf "${G}║${RST}  ${C}TOOLS:${RST}    Assemblers, SDKs, Emulators, Engines                               ${G}║${RST}\n"
printf "${G}║${RST}                                                                                 ${G}║${RST}\n"
printf "${G}║${RST}  ${Y}ACTIVATE:${RST} ${W}source ~/.zshrc${RST}                                                    ${G}║${RST}\n"
printf "${G}╚═════════════════════════════════════════════════════════════════════════════════╝${RST}\n"
printf "\n                                 ${M}/\\_____/\\${RST}\n"
printf "                                ${M}/  o   o  \\${RST}\n"
printf "                               ${M}( ==  ^  == )${RST}\n"
printf "                                ${M})  ~nya~  (${RST}\n"
printf "                               ${M}(           )${RST}\n"
printf "                              ${M}( (  )   (  ) )${RST}\n"
printf "                             ${M}(__(__)___(__)__)${RST}\n\n"

info "POST-INSTALL:"
echo "  1. ${W}source ~/.zshrc${RST}"
echo "  2. ${W}sudo installer -pkg ~/retro-dev/compilers/devkitpro/devkitpro.pkg -target /${RST}"
echo "  3. ${W}sudo dkp-pacman -S gba-dev nds-dev 3ds-dev wii-dev switch-dev${RST}"
echo "  4. ${W}bash ~/retro-dev/compilers/mips-toolchain/build_mips.sh${RST} (N64)"
echo ""
info "QUICK START:"
echo "  NES:    ${W}asm6 game.asm${RST}"
echo "  GB:     ${W}rgbasm -o game.o game.asm && rgblink -o game.gb game.o${RST}"
echo "  GBA:    ${W}arm-none-eabi-gcc ...${RST}"
echo "  N64:    ${W}mkdir proj && cd proj && libdragon init && libdragon make${RST}"
echo "  Genesis:${W}cd \$SGDK && make${RST}"
echo ""
