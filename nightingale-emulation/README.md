# Nightingale - QEMU PowerPC Emulator

Run classic Mac music notation software on modern macOS via QEMU emulation.

## Quick Start

```bash
./nightingale-emulation.sh
```

Inside Tiger:
1. Safari → `http://10.0.2.2:8000`
2. Download `Nightingale.app.zip` → `/Applications`
3. Download `Sonata.ttf` → `/Library/Fonts`
4. Restart Tiger
5. Launch Nightingale

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
- **Sonata not working** → Did you restart Tiger?
- **"ps2pdf not found"** → `brew install ghostscript`

---

Last updated: March 2026
