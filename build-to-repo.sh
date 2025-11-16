#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="aur-builds"
REPO_DIR="x86_64"
REPO_NAME="answeros"

# Létrehozza a repo könyvtárat, ha nem létezik
mkdir -p "$REPO_DIR"

# Végigmegy az összes csomagkönyvtáron
for pkgdir in "$BUILD_DIR"/*; do
    [[ -d "$pkgdir" ]] || continue
    echo "Fordítás: $(basename "$pkgdir")"

    pushd "$pkgdir" > /dev/null

    # Fordítás és csomagkészítés (interaktív kérdések nélkül)
    makepkg -sf --noconfirm --clean --cleanbuild

    # A legutóbb elkészült csomag bemásolása a repo könyvtárba
    for pkgfile in ./*.pkg.tar.zst; do
        cp -v "$pkgfile" "../../$REPO_DIR/"
    done

    popd > /dev/null
done

# Repo adatbázis frissítése
repo-add "$REPO_DIR/$REPO_NAME.db.tar.gz" "$REPO_DIR"/*.pkg.tar.zst

# Symlinkek törlése
echo "Symlinkek törlése..."
rm -f $REPO_DIR/$REPO_NAME.db
rm -f $REPO_DIR/$REPO_NAME.files
mv $REPO_DIR/$REPO_NAME.db.tar.gz $REPO_DIR/$REPO_NAME.db
mv $REPO_DIR/$REPO_NAME.files.tar.gz $REPO_DIR/$REPO_NAME.files
echo "Minden kész! Az $REPO_NAME repo frissítve!"
