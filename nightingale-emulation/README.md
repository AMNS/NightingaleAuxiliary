# Nightingale - QEMU PowerPC Emulator

Run classic Mac music notation software on modern macOS via QEMU emulation.

## Quick Start

```bash
./nightingale-emulation.sh
```

Inside Tiger:
1. Safari → `http://10.0.2.2:8000`
2. Download `Nightingale.app.zip` → `/Applications`
3. Download music font (`Briard.ttf` or `Sonata.ttf`) → install via Font Book
4. Download `BMPFileDistribution.zip` → unzip and copy 4 .bmp files to `/Library/Application Support/`
5. Restart Tiger
6. Launch Nightingale

## Requirements

- macOS 10.11+
- `brew install qemu wget p7zip`

Optional: `xcode-select --install`, `brew install ghostscript`

## Commands

```bash
./nightingale-emulation.sh                  # Setup & launch
./nightingale-emulation.sh --run-only       # Launch only
./nightingale-emulation.sh --clean          # Remove all

./nightingale-emulation.sh --mount          # Browse Tiger in Finder
./nightingale-emulation.sh --extract        # Mount & sync Documents/Downloads/Desktop

./nightingale-emulation.sh --prepare-ngl <file.ngl>   # Score → zip (preserves resource forks)
./nightingale-emulation.sh --ps2pdf <in.ps> <out.pdf> # PostScript → PDF
```

## Installing Music Fonts

Inside Tiger, download from `http://10.0.2.2:8000`:

**Briard font** (free, recommended):
1. Download `Briard.ttf`
2. Open **Font Book** application (in `/Applications`)
3. Right-click on "Computer" in left panel → "Add Fonts..."
4. Navigate to Downloads folder, select `Briard.ttf`
5. Click "Open"
6. Restart Nightingale

**Alternative (manual):** Copy `Briard.ttf` directly to `/Library/Fonts/`

**Sonata font** (optional, if available):
1. Download `Sonata.ttf`
2. Open **Font Book** application (in `/Applications`)
3. Right-click on "Computer" in left panel → "Add Fonts..."
4. Navigate to Downloads folder, select `Sonata.ttf`
5. Click "Open"
6. Restart Nightingale

**Alternative (manual):** Copy `Sonata.ttf` directly to `/Library/Fonts/`

(If Sonata has display issues, use Briard instead)

## Installing BMP Files (Nightingale 6)

Inside Tiger, from `http://10.0.2.2:8000`:

1. Download `BMPFileDistribution.zip`
2. Double-click to unzip
3. Copy the 4 .bmp files to `/Library/Application Support/`
   - `Duration_2dotsNB1b.bmp`
   - `DynamicsNB1b.bmp`
   - `NRModifierNB1b.bmp`
   - `ToolPaletteNB1b.bmp`
4. Restart Nightingale

## Getting Files from Tiger

```bash
./nightingale-emulation.sh --extract
```

Mounts the disk in Finder. Copy Documents/Downloads/Desktop folders to your computer, then eject from Finder.

## Tiger Login

- **User:** Tim Cook
- **Password:** password
- **HTTP:** `http://10.0.2.2:8000`
- **Mouse grab:** Ctrl+Alt+G

## Troubleshooting

- **"Tiger image not found"** → Run with no flags to download
- **Noteheads not displaying** → Use Briard font instead of Sonata
- **BMP files not working** → Are they in `/Library/Application Support/`? Restart Nightingale
- **"ps2pdf not found"** → `brew install ghostscript`

---

Last updated: March 2026
