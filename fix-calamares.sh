#!/usr/bin/env bash
set -euo pipefail

PKGDIR="aur-builds/calamares"
PKGBUILD="$PKGDIR/PKGBUILD"

if [[ ! -f "$PKGBUILD" ]]; then
    echo "Hiba: Nem található a $PKGBUILD fájl!"
    exit 1
fi

echo "PKGBUILD javítása a calamares csomaghoz..."

# Biztonsági mentés
cp "$PKGBUILD" "$PKGBUILD.bak"

# pkgname blokk teljes cseréje
awk '
    BEGIN {done=0}
    /^pkgname=\(/ {
        if (!done) {
            print "pkgname=(\x27calameres\x27)"
            done=1
        }
        next
    }
    done && /^\s*'\''/ { next }   # pkgname tömb további sorait átugorja
    { print }
' "$PKGBUILD.bak" > "$PKGBUILD"

# Ellenőrzés
echo "Ellenőrzés:"
grep "^pkgname" "$PKGBUILD"
