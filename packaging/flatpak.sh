#!/usr/bin/env bash
# Asima Hub's Flatpak bundle for GitHub Releases. Gathers the source (this repository and Asima UI:
# ui/ here, or the OS's apps/ui next to it), builds the manifest with flatpak-builder (the host's,
# or Flathub's org.flatpak.Builder) and makes build/flatpak/AsimaHub-x86_64.flatpak, which fetches
# the KDE runtime from Flathub by itself when it is installed.
#   packaging/flatpak.sh             build the bundle
#   packaging/flatpak.sh --install   also install it for this user, to try it
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
APP=io.github.asimaos.Hub
OUT=build/flatpak
FLATHUB=https://dl.flathub.org/repo/flathub.flatpakrepo

ui=ui
[[ -f ${ui}/CMakeLists.txt ]] || ui=../asimaos/apps/ui
[[ -f ${ui}/CMakeLists.txt ]] || { echo "flatpak.sh: Asima UI not found (ui/ or ../asimaos/apps/ui)" >&2; exit 1; }
rm -rf "${OUT}/source" && mkdir -p "${OUT}/source"
tar -c --exclude=./build --exclude=./.git --exclude=./ui --exclude=./screenshots . | tar -x -C "${OUT}/source"
cp -r "${ui}" "${OUT}/source/ui"

# One compile job per 1.5 GB of free memory, at most one per core.
free_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
jobs=$(( free_kb / 1572864 )); (( jobs < 1 )) && jobs=1; (( jobs > $(nproc) )) && jobs=$(nproc)
jobs=${ASIMAOS_JOBS:-${jobs}}

flatpak remote-add --user --if-not-exists flathub "${FLATHUB}"
if command -v flatpak-builder > /dev/null; then
    builder=(flatpak-builder)
else
    flatpak info org.flatpak.Builder > /dev/null 2>&1 || flatpak install --user -y --noninteractive flathub org.flatpak.Builder
    builder=(flatpak run org.flatpak.Builder)
fi
"${builder[@]}" --user --install-deps-from=flathub --force-clean --jobs="${jobs}" \
    --state-dir="${OUT}/state" --repo="${OUT}/repo" "${OUT}/app" "packaging/${APP}.yml"
flatpak build-bundle --runtime-repo="${FLATHUB}" "${OUT}/repo" "${OUT}/AsimaHub-x86_64.flatpak" "${APP}"
sha256sum "${OUT}/AsimaHub-x86_64.flatpak"
if [[ ${1:-} == --install ]]; then
    flatpak install --user -y --noninteractive --reinstall --bundle "${OUT}/AsimaHub-x86_64.flatpak"
fi
