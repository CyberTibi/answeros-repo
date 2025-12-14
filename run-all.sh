#!/usr/bin/env bash
set -euo pipefail

echo "=== 1. AUR csomagok klónozása ==="
./clone-aur-packages.sh

# echo "=== 2. Calamares PKGBUILD javítása ==="
# ./fix-calameres.sh

echo "=== 3. Csomagok fordítása és repo építés ==="
./build-to-repo.sh

echo "=== Kész! A lokális repo az x86_64 könyvtárban található. ==="
