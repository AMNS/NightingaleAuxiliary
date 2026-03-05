#!/bin/bash
# =============================================================================
# Nightingale 5.6 - QEMU PowerPC Emulator for macOS
# =============================================================================
#
# Run classic Mac music notation software on modern macOS via emulation.
#
# QUICKSTART:
#   chmod +x nightingale-emulation.sh
#   ./nightingale-emulation.sh                  # Download Tiger & launch
#   (inside Tiger: Safari → http://10.0.2.2:8000 to download Nightingale)
#
# COMMANDS:
#   ./nightingale-emulation.sh                  Full setup & launch
#   ./nightingale-emulation.sh --help           Show all commands
#   ./nightingale-emulation.sh --run-only       Launch (skip downloads)
#   ./nightingale-emulation.sh --mount          Mount Tiger disk
#   ./nightingale-emulation.sh --extract        Extract files from Tiger
#   ./nightingale-emulation.sh --clean          Remove all files
#
# UTILITIES:
#   ./nightingale-emulation.sh --prepare-ngl <file.ngl>    Score → zip
#   ./nightingale-emulation.sh --ps2pdf <in.ps> <out.pdf>  PostScript → PDF
#
# REQUIREMENTS:
#   macOS 10.11+, Homebrew, QEMU, wget, p7zip, Ruby 2.1+
#   Optional: Xcode CLT (SetFile), Ghostscript
#
# DIRECTORIES:
#   nightingale_emu/                  Working directory
#   nightingale_emu/disk_images/      Tiger OS X image (~5 GB)
#   nightingale_emu/shared/           HTTP file server
#   nightingale_emu/tiger_user_files/ Extracted files
#
# TIGER LOGIN: Tim Cook / password
# HTTP SERVER: http://10.0.2.2:8000 (from inside emulator)
#
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR/nightingale_emu"

# =============================================================================
# Handle flags
# =============================================================================

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat << 'HELP'
Nightingale 5.6 - QEMU PowerPC Emulator for macOS

COMMANDS:
  nightingale-emulation.sh              Full setup & launch Tiger
  nightingale-emulation.sh --run-only   Launch (skip downloads)
  nightingale-emulation.sh --clean      Remove all files

DISK OPERATIONS:
  nightingale-emulation.sh --mount      Mount Tiger disk (browse in Finder)
  nightingale-emulation.sh --extract    Mount & sync Documents/Downloads/Desktop

NIGHTINGALE UTILITIES:
  nightingale-emulation.sh --prepare-ngl <file.ngl>
                           Create distributable score (zip with metadata)
  nightingale-emulation.sh --ps2pdf <in.ps> <out.pdf>
                           Convert PostScript to PDF (fonts embedded)

REQUIREMENTS:
  • macOS 10.11 or newer
  • Homebrew (https://brew.sh)
  • QEMU: brew install qemu
  • wget: brew install wget
  • p7zip: brew install p7zip
  • Ruby 2.1+ (built-in)

  Optional:
  • Xcode CLT: xcode-select --install (for SetFile)
  • Ghostscript: brew install ghostscript (for --ps2pdf)

QUICKSTART:
  1. chmod +x nightingale-emulation.sh
  2. ./nightingale-emulation.sh            (downloads ~6GB, launches Tiger)
  3. Inside Tiger:
     - Open Safari → http://10.0.2.2:8000 (or try localhost:8000)
     - Download Nightingale.app.zip → /Applications
     - Download Sonata.ttf → /Library/Fonts
     - RESTART TIGER (critical for fonts!)
     - Launch Nightingale from Applications

TIGER LOGIN:
  Username: Tim Cook
  Password: password

DIRECTORIES:
  nightingale_emu/                      Working directory
  nightingale_emu/disk_images/          Tiger OS X image (~5 GB)
  nightingale_emu/shared/               HTTP file server
  nightingale_emu/tiger_user_files/     Extracted files

FILES SERVED:
  From inside Tiger: http://10.0.2.2:8000 (default QEMU gateway)
  If that doesn't work, try: http://localhost:8000

For details, see README.md
HELP
    exit 0
fi
fi

if [ "$1" = "--clean" ]; then
    echo -e "${YELLOW}Cleaning up old installation...${NC}"
    if [ -d "$WORK_DIR" ]; then
        rm -rf "$WORK_DIR"
        echo -e "${GREEN}✓ Removed $WORK_DIR${NC}"
    fi
    exit 0
fi

if [ "$1" = "--mount" ]; then
    QCOW_IMG="$WORK_DIR/disk_images/osx-tiger_10.4.11_installed.qcow2"
    RAW_IMG="$WORK_DIR/disk_images/tiger.img"

    if [ ! -f "$QCOW_IMG" ]; then
        echo -e "${RED}ERROR: Tiger image not found${NC}"
        echo "Run: ./nightingale-emulation.sh"
        exit 1
    fi

    # Convert QCOW2 to raw (reuse existing or create fresh)
    if [ ! -f "$RAW_IMG" ]; then
        echo "Converting Tiger image to raw format (one time, may take 1-2 minutes)..."
        qemu-img convert -f qcow2 -O raw "$QCOW_IMG" "$RAW_IMG" || exit 1
    fi

    echo "Mounting Tiger disk..."
    open "$RAW_IMG"
    echo -e "${GREEN}✓ Disk mounted in Finder${NC}"
    echo "To unmount: eject from Finder"
    exit 0
fi

if [ "$1" = "--extract" ]; then
    QCOW_IMG="$WORK_DIR/disk_images/osx-tiger_10.4.11_installed.qcow2"
    RAW_IMG="$WORK_DIR/disk_images/tiger.img"

    if [ ! -f "$QCOW_IMG" ]; then
        echo -e "${RED}ERROR: Tiger image not found${NC}"
        echo "Run: ./nightingale-emulation.sh"
        exit 1
    fi

    # Always reconvert to get latest files
    echo "Converting Tiger image to raw (syncing from guest)..."
    rm -f "$RAW_IMG"
    qemu-img convert -f qcow2 -O raw "$QCOW_IMG" "$RAW_IMG" || exit 1

    echo "Mounting..."
    open "$RAW_IMG"
    sleep 2

    echo ""
    echo -e "${GREEN}✓ Tiger disk mounted in Finder${NC}"
    echo ""
    echo "Your files are now accessible at:"
    echo "  /Volumes/Macintosh\\ HD\\ 1/Users/Tim\\ Cook/Documents"
    echo "  /Volumes/Macintosh\\ HD\\ 1/Users/Tim\\ Cook/Downloads"
    echo "  /Volumes/Macintosh\\ HD\\ 1/Users/Tim\\ Cook/Desktop"
    echo ""
    echo "(Or check Finder for the mounted volume name)"
    echo ""
    echo "Eject from Finder when done"
    echo ""
    exit 0
fi

if [ "$1" = "--prepare-ngl" ]; then
    if [ -z "$2" ]; then
        echo -e "${RED}ERROR: Missing argument${NC}"
        echo "Usage: $0 --prepare-ngl <file.ngl>"
        exit 1
    fi

    INPUT="$2"

    if [ ! -f "$INPUT" ]; then
        echo -e "${RED}ERROR: File not found: $INPUT${NC}"
        exit 1
    fi

    # Get directory and filename
    INPUT_DIR=$(cd "$(dirname "$INPUT")" && pwd)
    BASENAME=$(basename "$INPUT" .ngl)
    OUTPUT_ZIP="$WORK_DIR/${BASENAME}_ready.zip"

    echo "Preparing Nightingale file for distribution..."
    echo "Input: $INPUT"
    echo ""

    # Step 1: Add resource forks
    echo "Step 1: Setting file type and creator..."
    if command -v SetFile &> /dev/null; then
        # From Nightingale source code:
        # DOCUMENT_TYPE_NORMAL = 'SCOR' (score document)
        # CREATOR_TYPE_NORMAL = 'BYRD' (Don Byrd's creator signature)
        SetFile -t "SCOR" -c "BYRD" "$INPUT" 2>/dev/null || true
        echo -e "${GREEN}✓ File type: SCOR (Nightingale Score)${NC}"
        echo -e "${GREEN}✓ Creator: BYRD (Don Byrd)${NC}"
    else
        echo -e "${YELLOW}⚠ SetFile not found (install Xcode Command Line Tools)${NC}"
    fi

    # Preserve extended attributes
    xattr -p com.apple.ResourceFork "$INPUT" > /dev/null 2>&1 || true

    FILE_SIZE=$(stat -f%z "$INPUT" 2>/dev/null || stat -c%s "$INPUT" 2>/dev/null)
    echo "✓ File size: $FILE_SIZE bytes"
    echo ""

    # Step 2: Create zip archive with preserved forks
    echo "Step 2: Creating zip archive with preserved resource forks..."

    # Remove any existing zip file or directory
    rm -rf "$OUTPUT_ZIP"

    # Create work directory if needed
    mkdir -p "$WORK_DIR"

    # Zip the file using ditto (handles Mac resource forks properly)
    ditto -c -k --sequesterRsrc "$INPUT" "$OUTPUT_ZIP" 2>/dev/null
    RESULT=$?

    if [ $RESULT -eq 0 ] && [ -f "$OUTPUT_ZIP" ]; then
        ZIP_SIZE=$(ls -lh "$OUTPUT_ZIP" | awk '{print $5}')
        echo -e "${GREEN}✓ Created archive: $OUTPUT_ZIP ($ZIP_SIZE)${NC}"
    else
        echo -e "${RED}ERROR: Failed to create zip (exit code: $RESULT)${NC}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}✓ Nightingale file ready for distribution!${NC}"
    echo ""
    echo "Summary:"
    echo "  Original: $INPUT ($FILE_SIZE bytes)"
    echo "  Archive: $OUTPUT_ZIP ($ZIP_SIZE)"
    echo "  • Resource forks preserved"
    echo "  • File type: SCOR (Nightingale Score)"
    echo "  • Creator: BYRD (Don Byrd)"
    exit 0
fi

if [ "$1" = "--ps2pdf" ]; then
    if [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${RED}ERROR: Missing arguments${NC}"
        echo "Usage: $0 --ps2pdf <input.ps> <output.pdf>"
        exit 1
    fi

    INPUT="$2"
    OUTPUT="$3"

    if [ ! -f "$INPUT" ]; then
        echo -e "${RED}ERROR: Input file not found: $INPUT${NC}"
        exit 1
    fi

    if ! command -v ps2pdf &> /dev/null; then
        echo -e "${RED}ERROR: ps2pdf not found. Install with: brew install ghostscript${NC}"
        exit 1
    fi

    echo "Converting PostScript to PDF (embedding all fonts)..."
    echo "Input: $INPUT"
    echo "Output: $OUTPUT"

    ps2pdf -dEmbedAllFonts=true -dSubsetFonts=false "$INPUT" "$OUTPUT"

    if [ -f "$OUTPUT" ]; then
        SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
        echo -e "${GREEN}✓ Conversion successful ($SIZE)${NC}"
        exit 0
    else
        echo -e "${RED}ERROR: Conversion failed${NC}"
        exit 1
    fi
fi

if [ "$1" = "--run-only" ]; then
    if [ ! -f "$WORK_DIR/disk_images/osx-tiger_10.4.11_installed.qcow2" ]; then
        echo -e "${RED}ERROR: Tiger image not found. Run without --run-only${NC}"
        exit 1
    fi
    echo "Launching Tiger..."
    LAUNCH=1
fi

# =============================================================================
# Check dependencies
# =============================================================================

echo -e "${YELLOW}Checking dependencies...${NC}"
echo ""

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${RED}ERROR: Homebrew not installed${NC}"
    echo ""
    echo "Install Homebrew from: https://brew.sh"
    echo "Then run this script again."
    exit 1
fi

MISSING=()
OPTIONAL=()

# Required tools
for cmd in qemu-system-ppc wget 7z; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING+=("$cmd")
    fi
done

# Optional but recommended
if ! command -v SetFile &> /dev/null; then
    OPTIONAL+=("SetFile (Xcode CLT: xcode-select --install)")
fi

if ! command -v ps2pdf &> /dev/null; then
    OPTIONAL+=("ps2pdf (Ghostscript: brew install ghostscript)")
fi

# Report and install missing required
if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing missing dependencies...${NC}"
    for cmd in "${MISSING[@]}"; do
        case "$cmd" in
            qemu-system-ppc)
                echo "  → Installing QEMU..."
                brew install qemu
                ;;
            wget)
                echo "  → Installing wget..."
                brew install wget
                ;;
            7z)
                echo "  → Installing p7zip..."
                brew install p7zip
                ;;
        esac
    done
    echo ""
fi

# Warn about optional dependencies
if [ ${#OPTIONAL[@]} -gt 0 ]; then
    echo -e "${YELLOW}Optional dependencies:${NC}"
    for opt in "${OPTIONAL[@]}"; do
        echo "  ⚠ $opt"
    done
    echo ""
fi

echo -e "${GREEN}✓ All required dependencies OK${NC}"
echo ""

# =============================================================================
# Setup directories
# =============================================================================

mkdir -p "$WORK_DIR"/{downloads,disk_images,shared}

# =============================================================================
# Download Tiger image (if needed)
# =============================================================================

TIGER_IMAGE="$WORK_DIR/disk_images/osx-tiger_10.4.11_installed.qcow2"

if [ "$LAUNCH" = "1" ]; then
    # Skip downloads if --run-only
    true
elif [ -f "$TIGER_IMAGE" ]; then
    echo -e "${GREEN}✓ Tiger image already present${NC}"
else
    echo ""
    echo -e "${YELLOW}Downloading Mac OS X Tiger 10.4.11 (1.9 GB compressed)...${NC}"
    TIGER_ZIP="$WORK_DIR/downloads/osx-tiger_10.4.11_installed.qcow2.7z"

    if [ ! -f "$TIGER_ZIP" ]; then
        wget -q --show-progress -O "$TIGER_ZIP" \
            "http://dn721207.ca.archive.org/0/items/mac-osx-tiger-10.4-ppc-installed-qcow2-image/osx-tiger_10.4.11_installed.qcow2.7z" || \
        wget -q --show-progress -O "$TIGER_ZIP" \
            "http://archive.org/download/mac-osx-tiger-10.4-ppc-installed-qcow2-image/osx-tiger_10.4.11_installed.qcow2.7z"
    fi

    if [ -f "$TIGER_ZIP" ]; then
        echo "Decompressing Tiger image (4.8 GB)..."
        7z x -y -o"$WORK_DIR/disk_images/" "$TIGER_ZIP" > /dev/null 2>&1
        echo -e "${GREEN}✓ Tiger ready${NC}"
    fi
fi

# =============================================================================
# Download Nightingale app (if needed)
# =============================================================================

NIGHTINGALE_APP="$WORK_DIR/shared/Nightingale.app"

if [ "$LAUNCH" != "1" ] && [ ! -f "$WORK_DIR/shared/Nightingale.app.zip" ]; then
    if [ ! -d "$NIGHTINGALE_APP" ]; then
        echo ""
        echo -e "${YELLOW}Downloading Nightingale 5.6...${NC}"
        NGALE_ZIP="$WORK_DIR/downloads/Nightingale5p6.app.zip"

        if [ ! -f "$NGALE_ZIP" ]; then
            wget -q --show-progress -O "$NGALE_ZIP" \
                "https://github.com/AMNS/Nightingale/raw/develop/Nightingale5p6.app.zip"
        fi

        if [ -f "$NGALE_ZIP" ]; then
            echo "Extracting Nightingale..."
            unzip -q "$NGALE_ZIP" -d "$WORK_DIR/shared/"

            # Find and detect app name
            if [ -d "$WORK_DIR/shared/Nightingale5p6.app" ]; then
                mv "$WORK_DIR/shared/Nightingale5p6.app" "$NIGHTINGALE_APP"
            elif [ -d "$WORK_DIR/shared/Nightingale.app" ]; then
                true
            fi

            echo -e "${GREEN}✓ Nightingale ready${NC}"
        fi
    fi

    # Create zip for Tiger download
    if [ -d "$NIGHTINGALE_APP" ]; then
        echo "Creating Nightingale.app.zip for Tiger..."
        cd "$WORK_DIR/shared"
        zip -r -q "Nightingale.app.zip" "Nightingale.app"
        SIZE=$(ls -lh Nightingale.app.zip | awk '{print $5}')
        echo -e "${GREEN}✓ Created zip ($SIZE)${NC}"
    fi
fi

# =============================================================================
# Sonata font (user-provided)
# =============================================================================

echo ""
echo -e "${YELLOW}Sonata font${NC}"
if [ -f "$WORK_DIR/shared/Sonata.ttf" ]; then
    SIZE=$(ls -lh "$WORK_DIR/shared/Sonata.ttf" | awk '{print $5}')
    echo -e "${GREEN}✓ Sonata.ttf ready ($SIZE)${NC}"
else
    echo "⚠ Place Sonata.ttf in: nightingale_emu/shared/"
    echo "  (will be served via HTTP at http://10.0.2.2:8000)"
fi

# =============================================================================
# Launch Tiger
# =============================================================================

echo ""
echo -e "${YELLOW}Before launching - prepare Sonata font (on your computer)${NC}"
echo "  1. Obtain Sonata.ttf"
echo "  2. Save to: nightingale_emu/shared/"
echo ""

echo -e "${GREEN}=== Launching Mac OS X Tiger ===${NC}"
echo ""
echo "HTTP Server: http://10.0.2.2:8000"
echo "Serving files from: nightingale_emu/shared/"
echo ""
echo "Setup in Tiger (inside emulator):"
echo "  1. Open Safari → http://10.0.2.2:8000"
echo "  2. Download Nightingale.app.zip"
echo "     → Extract to Applications folder"
echo "  3. Download Sonata.ttf"
echo "     → Copy to /Library/Fonts folder (may require Terminal)"
echo "  4. RESTART TIGER"
echo "  5. Launch Nightingale"
echo ""
echo "Tips:"
echo "  - Login: Tim Cook / password"
echo "  - Font works after restart"
echo "  - Exit: File → Shut Down"
echo "  - Grab mouse: Ctrl+Alt+G"
echo ""
echo "Starting HTTP server (port 8000)..."
echo ""

cd "$WORK_DIR/shared"
ruby -run -ehttpd . -p8000 &
HTTP_PID=$!

cleanup() {
    kill $HTTP_PID 2>/dev/null || true
}
trap cleanup EXIT

sleep 1
echo "HTTP server running (PID: $HTTP_PID)"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}HTTP FILE SERVER READY${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Inside Tiger, open Safari and go to:"
echo ""
echo -e "  ${YELLOW}http://10.0.2.2:8000${NC}"
echo ""
echo "(This is the default QEMU gateway address)"
echo "If that doesn't work, try: http://localhost:8000"
echo ""
echo "Files available:"
echo "  • Nightingale.app.zip"
echo "  • Sonata.ttf (if placed in nightingale_emu/shared/)"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Launch Tiger
TIGER_IMAGE="$WORK_DIR/disk_images/osx-tiger_10.4.11_installed.qcow2"

qemu-system-ppc \
    -L pc-bios \
    -M mac99,via=pmu \
    -cpu G4 \
    -m 1024 \
    -drive file="$TIGER_IMAGE",if=ide,media=disk,format=qcow2 \
    -boot c \
    -netdev user,id=mynet \
    -device rtl8139,netdev=mynet \
    -display cocoa \
    -device usb-kbd \
    -device usb-mouse \
    -prom-env 'auto-boot?=true' \
    -prom-env 'vga-ndrv?=true'
