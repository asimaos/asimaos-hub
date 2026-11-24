#!/usr/bin/env bash
# Runs inside the build container (see build.sh).
set -euo pipefail
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release > build-configure.log 2>&1 \
    || { cat build-configure.log; exit 1; }
rm -f build-configure.log
grep -q '<message' i18n/asimaos_bn.ts 2>/dev/null || cmake --build build --target update_translations > /dev/null
cmake --build build

case ${1:-} in
    test)
        export QT_QPA_PLATFORM=offscreen
        rc=0
        bash tests/hub-feed-e2e.sh build/asimaos-hub || rc=1
        bash tests/hub-get-e2e.sh build/asimaos-hub || rc=1
        exit ${rc}
        ;;
    translations)
        cmake --build build --target update_translations
        exit 0
        ;;
    screenshots) ;;
    *) exit 0 ;;
esac

export XDG_RUNTIME_DIR=/tmp/xdg-runtime && mkdir -p -m 0700 "${XDG_RUNTIME_DIR}"
export LIBGL_ALWAYS_SOFTWARE=1 QT_QPA_PLATFORM=xcb DISPLAY=:99
Xvfb :99 -screen 0 1920x1200x24 -nolisten tcp >/dev/null 2>&1 &
XVFB=$!
trap 'kill ${XVFB} 2>/dev/null || true' EXIT
sleep 1
OUT=screenshots
mkdir -p "${OUT}"
rm -f "${OUT}"/*.png

# PAGE[:STATE][@WxH] → screenshots/asimaos-hub-PAGE[-last part of STATE]-THEME.png
SHOTS="updates updates:downloading updates:downloaded updates:installing updates:installed updates:empty
       updates:unset get get:iso-downloading get:iso-downloaded get:writing@1320x1560 get:written@1320x1560
       news help report:report"
for theme in light dark; do
    for shot in ${SHOTS}; do
        size=1320x860
        if [[ ${shot} == *@* ]]; then size=${shot##*@}; shot=${shot%@*}; fi
        page=${shot%%:*} state=""
        [[ ${shot} == *:* ]] && state=${shot#*:}
        name="asimaos-hub-${page}${state:+-${state##*-}}-${theme}.png"
        build/asimaos-hub --demo --theme "${theme}" --page "${page}" ${state:+--state "${state}"} \
            --size "${size}" --screenshot "${OUT}/${name}" 2>&1 | grep -vE 'propagateSizeHints|XDG_RUNTIME_DIR' || true
        echo "  ${name}"
    done
done
