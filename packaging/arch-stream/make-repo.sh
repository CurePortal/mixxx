#!/usr/bin/env bash
#
# Build the mixxx-stream package and add it to the local pacman repository.
#
# This never touches the official `mixxx` package: mixxx-stream installs under
# its own name at /opt/mixxx-stream, so it survives `pacman -Syu`.
#
#   bash packaging/arch-stream/make-repo.sh
#
# The repository ends up in dist/arch-repo/. It can be served over HTTP or
# added as a local file:// repository. See README.md.
#
set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${PKG_DIR}/../../.." && pwd)"
REPO_OUT="${REPO_ROOT}/dist/arch-repo"

mkdir -p "${REPO_OUT}"

# The prebuilt file tree is not tracked in git; regenerate it from the build
# directory if it is missing.
if [[ ! -f "${PKG_DIR}/mixxx-stream-files.tar.zst" ]]; then
    echo "== Prebuilt tree missing; regenerating =="
    bash "${PKG_DIR}/update-package.sh"
fi

echo "== Building package =="
cd "${PKG_DIR}"
makepkg -f --noconfirm

echo "== Adding to repository =="
shopt -s nullglob
pkgs=("${PKG_DIR}"/mixxx-stream-*.pkg.tar.zst)
if [[ ${#pkgs[@]} -eq 0 ]]; then
    echo "ERROR: no built package found in ${PKG_DIR}" >&2
    exit 1
fi
# Remove any previously published package/database so the repository only ever
# contains the current build (avoids repo-add failing on stale entries).
rm -f "${REPO_OUT}"/mixxx-stream-*.pkg.tar.zst \
      "${REPO_OUT}"/mixxx-stream.db* \
      "${REPO_OUT}"/mixxx-stream.files*
cp -f "${pkgs[@]}" "${REPO_OUT}/"

cd "${REPO_OUT}"
repo-add mixxx-stream.db.tar.zst mixxx-stream-*.pkg.tar.zst

echo
echo "Repository: ${REPO_OUT}"
ls -la "${REPO_OUT}"
echo
echo "Serve it, e.g.:  python3 -m http.server 8000 -d ${REPO_OUT}"
