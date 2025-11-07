#!/bin/bash

# === Beállítások ===
PKG_LIST="$HOME/answeros-localrepo/aur-packages.txt"
BUILD_DIR="$HOME/answeros-localrepo/aur-builds"
REPO_DIR="$HOME/answeros-localrepo/x86_64"
REPO_NAME="answeros"
REPO_DB="$REPO_DIR/$REPO_NAME.db.tar.gz"

mkdir -p "$BUILD_DIR" "$REPO_DIR"
cd "$BUILD_DIR" || exit 1

declare -A DEP_GRAPH
declare -A VISITED
SORTED=()

# === Függőségek lekérése ===
get_deps() {
  local pkg="$1"
  local deps=()
  rm -rf "$BUILD_DIR/$pkg"
  git clone --depth=1 "https://aur.archlinux.org/$pkg.git" "$BUILD_DIR/$pkg" &>/dev/null
  if [[ ! -d "$BUILD_DIR/$pkg" ]]; then
    echo "❌ Nem sikerült klónozni: $pkg"
    return
  fi
  cd "$BUILD_DIR/$pkg" || return
  while read -r line; do
    dep=$(echo "$line" | cut -d ':' -f2 | tr -d ' ' | cut -d '>' -f1 | cut -d '=' -f1)
    [[ -n "$dep" ]] && deps+=("$dep")
  done < <(makepkg --printsrcinfo | grep -E 'depends|makedepends')
  DEP_GRAPH["$pkg"]="${deps[*]}"
}

# === Topológiai rendezés ===
dfs() {
  local pkg="$1"
  [[ "${VISITED[$pkg]}" == "1" ]] && return
  VISITED["$pkg"]=1
  for dep in ${DEP_GRAPH["$pkg"]}; do
    if grep -q "^$dep$" "$PKG_LIST"; then
      dfs "$dep"
    fi
  done
  SORTED+=("$pkg")
}

# === Csomaglista feldolgozása ===
while read -r pkg; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
  get_deps "$pkg"
done < "$PKG_LIST"

# === Topológiai sorrend generálása ===
while read -r pkg; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
  dfs "$pkg"
done < "$PKG_LIST"

# === Fordítás és másolás ===
for pkg in "${SORTED[@]}"; do
  echo "➡️ Fordítás: $pkg"
  cd "$BUILD_DIR/$pkg" || continue
  makepkg -s --noconfirm
  cp ./*.pkg.tar.zst "$REPO_DIR/"
done

# === Repo frissítése ===
cd "$REPO_DIR" || exit 1
rm -f "$REPO_DB"
repo-add "$REPO_DB" ./*.pkg.tar.zst

# === Függőségek ellenőrzése ===
echo "🔍 Függőségek ellenőrzése..."
for FILE in "$REPO_DIR"/*.pkg.tar.zst; do
  for DEP in $(pacman -Qip "$FILE" | grep "Depends On" | cut -d ':' -f2 | tr -d ' ' | tr -s ' ' | tr ' ' '\n'); do
    BASE_DEP=$(echo "$DEP" | cut -d'>' -f1 | cut -d'=' -f1)
    if ! pacman -Si "$BASE_DEP" &>/dev/null && ! ls "$REPO_DIR"/"$BASE_DEP"-*.pkg.tar.zst &>/dev/null; then
      echo "⚠️ Hiányzó AUR függőség: $BASE_DEP → nem szerepel a aur-packages.txt fájlban!"
    fi
  done
done

# Symlinkek törlése
echo "Symlinkek törlése..."
rm -f $REPO_DIR/$REPO_NAME.db
rm -f $REPO_DIR/$REPO_NAME.files
mv $REPO_DIR/$REPO_NAME.db.tar.gz $REPO_DIR/$REPO_NAME.db
mv $REPO_DIR/$REPO_NAME.files.tar.gz $REPO_DIR/$REPO_NAME.files

echo "✅ Kész: $REPO_NAME frissítve itt: $REPO_DIR"
