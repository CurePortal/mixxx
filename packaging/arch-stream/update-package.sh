#!/usr/bin/env bash
#
# Regenerate the prebuilt file tree tarball for the Arch package after the
# fork has been rebuilt. Run this from anywhere.
#
#   bash packaging/arch-stream/update-package.sh
#
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"          # mixxx/packaging/arch-stream
REPO_ROOT="$(cd "${PKG_DIR}/../../.." && pwd)"                  # mixxx-stream/
BUILD_DIR="${REPO_ROOT}/build"
STAGE="$(mktemp -d)"

cleanup() { rm -rf "${STAGE}"; }
trap cleanup EXIT

if [[ ! -x "${BUILD_DIR}/mixxx" ]]; then
    echo "ERROR: ${BUILD_DIR}/mixxx not found. Build the fork first." >&2
    exit 1
fi

echo "== Staging install to /opt/mixxx-stream =="
DESTDIR="${STAGE}" cmake --install "${BUILD_DIR}" --prefix /opt/mixxx-stream

echo "== Packing prebuilt tree =="
tar -I zstd -cf "${PKG_DIR}/mixxx-stream-files.tar.zst" -C "${STAGE}" opt

echo "== Recording binary checksum =="
sha256sum "${BUILD_DIR}/mixxx" | awk '{print $1}' > "${PKG_DIR}/binary.sha256"

echo "== Updating pkgver =="
cd "${PKG_DIR}/../.."                                           # mixxx/
base_ref="cureportal/main"
if ! git rev-parse --verify --quiet "${base_ref}" >/dev/null; then
    base_ref="main"
fi
commits=$(git rev-list --count "${base_ref}..HEAD" 2>/dev/null || echo 0)
hash=$(git rev-parse --short HEAD)
base=$(grep -m1 '^project(mixxx VERSION' CMakeLists.txt | awk '{print $3}')
pre=""
if grep -q 'MIXXX_VERSION_PRERELEASE "alpha"' CMakeLists.txt; then pre=".alpha"; fi
newver="${base}${pre}.r${commits}.g${hash}"
sed -i "s/^pkgver=.*/pkgver=${newver}/" "${PKG_DIR}/PKGBUILD"
echo "   pkgver -> ${newver}"
echo "   sha256 -> $(cat "${PKG_DIR}/binary.sha256")"

echo
echo "Now run: bash packaging/arch-stream/make-repo.sh"
