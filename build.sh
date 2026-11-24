#!/usr/bin/env bash
# Asima Hub's development build, in a rootless Podman container (no sudo):
#   ./build.sh               configure and build into build/
#   ./build.sh test          build, then the end-to-end tests (tests/)
#   ./build.sh screenshots   build, then render every screen, light and dark, into screenshots/
#   ./build.sh translations  collect new strings into i18n/*.ts
# The Flatpak bundle: packaging/flatpak.sh (on the host).
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
HASH=$(sha256sum Containerfile | cut -c1-8)
IMAGE="localhost/asimaos-hub-builder:${HASH}"
podman image exists "${IMAGE}" || podman build -t "${IMAGE}" -f Containerfile .

# Asima UI: this repository's ui/, or the OS's apps/ui next to it (../asimaos, where it is developed).
mounts=(-v "${PWD}:/work/asimaos-hub:Z")
if [[ ! -f ui/CMakeLists.txt ]]; then
    [[ -f ../asimaos/apps/ui/CMakeLists.txt ]] || { echo "build.sh: Asima UI not found (ui/ or ../asimaos/apps/ui)" >&2; exit 1; }
    mounts+=(-v "$(readlink -f ../asimaos/apps/ui):/work/asimaos/apps/ui:ro,z")
fi

# One compile job per 1.5 GB of free memory, at most one per core. ASIMAOS_JOBS=N overrides it.
free_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
jobs=$(( free_kb / 1572864 )); (( jobs < 1 )) && jobs=1; (( jobs > $(nproc) )) && jobs=$(nproc)
podman run --rm -e CMAKE_BUILD_PARALLEL_LEVEL="${ASIMAOS_JOBS:-${jobs}}" "${mounts[@]}" -w /work/asimaos-hub \
    "${IMAGE}" bash scripts/in-container.sh "$@"
