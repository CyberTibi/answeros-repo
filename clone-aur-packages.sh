#!/usr/bin/env bash
set -euo pipefail

# Bemeneti fájl és célkönyvtár
PKG_LIST="aur-packages.txt"
DEST_DIR="aur-builds"

# Ha nincs meg a fájl, hibával kilép
if [[ ! -f "$PKG_LIST" ]]; then
    echo "Hiba: Nem található a $PKG_LIST fájl!"
    exit 1
fi

# Létrehozza a célkönyvtárat, ha nem létezik
mkdir -p "$DEST_DIR"

# Soronként beolvassa a csomagneveket
while IFS= read -r pkg; do
    # Üres sorokat és kommenteket (#) átugorja
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

    echo "Klónozás: $pkg"
    if [[ -d "$DEST_DIR/$pkg" ]]; then
        echo "  -> Már létezik, frissítés git pull-lal"
        git -C "$DEST_DIR/$pkg" pull --ff-only || true
    else
        git clone "https://aur.archlinux.org/${pkg}.git" "$DEST_DIR/$pkg"
    fi
done < "$PKG_LIST"
