pragma Singleton
import QtQuick

// Asima UI design tokens. Every colour, size and duration used by Asima OS apps comes from here.
// Light and dark palettes follow the desktop colour scheme unless an app forces a mode.
QtObject {
    id: theme

    // "system" follows Plasma's colour scheme; "light" / "dark" force one.
    property string mode: "system"
    readonly property bool dark: mode === "dark"
        || (mode === "system" && Qt.styleHints.colorScheme === Qt.ColorScheme.Dark)

    // ── Brand: "Asima Blue" ────────────────────────────────────────────────
    readonly property color brand: "#0A6CD6"          // 5.1:1 with white text
    readonly property color brandHover: "#085DBA"
    readonly property color brandPressed: "#064E9C"
    // Sky → blue → deep blue: fills of progress bars and sliders, the Asima OS mark.
    readonly property color brandFrom: "#38BDF8"
    readonly property color brandMid: "#2F80ED"
    readonly property color brandTo: "#1E3FAE"
    // Hero gradient (white text on top): a touch deeper than the brand fill, deeper still in dark
    // mode so it doesn't glare.
    readonly property color heroFrom: dark ? "#0675B8" : "#0A8FD9"
    readonly property color heroMid: dark ? "#1D4ED8" : "#2563EB"
    readonly property color heroTo: dark ? "#172554" : "#1E3A8A"

    // ── Surfaces ────────────────────────────────────────────────────────────
    readonly property color window: dark ? "#0E1015" : "#F3F4F7"
    readonly property color sidebar: dark ? "#12151B" : "#FAFAFC"
    readonly property color surface: dark ? "#171B22" : "#FFFFFF"
    readonly property color surfaceAlt: dark ? "#1D222B" : "#F5F6F8"
    readonly property color surfaceHover: dark ? "#232935" : "#EEF0F3"
    readonly property color track: dark ? "#2A313D" : "#E8EBEF"
    readonly property color border: dark ? "#262C37" : "#E4E7EC"
    readonly property color borderStrong: dark ? "#353D4B" : "#D0D5DD"
    readonly property color overlay: dark ? "#B3000000" : "#66101318"

    // ── Text ────────────────────────────────────────────────────────────────
    readonly property color text: dark ? "#EDF0F5" : "#12151B"
    readonly property color textMuted: dark ? "#A5ADBB" : "#5B6371"
    readonly property color textSubtle: dark ? "#717A8A" : "#8B929F"
    readonly property color textOnAccent: "#FFFFFF"

    // ── Accent usage ────────────────────────────────────────────────────────
    readonly property color accent: brand
    readonly property color accentText: dark ? "#5CB8FF" : "#0960BF"
    readonly property color accentSoft: dark ? "#10233A" : "#E6F2FD"

    // ── Status ──────────────────────────────────────────────────────────────
    readonly property color ok: dark ? "#4ADE80" : "#15803D"
    readonly property color okSoft: dark ? "#132A1D" : "#E6F6EC"
    // Warnings are yellow (not orange), so they never look like the old brand or like errors.
    readonly property color warn: dark ? "#FACC15" : "#A16207"
    readonly property color warnSoft: dark ? "#2B250C" : "#FEF7D6"
    readonly property color error: dark ? "#F87171" : "#C81E1E"
    readonly property color errorSoft: dark ? "#311719" : "#FDECEC"
    readonly property color errorFill: dark ? "#DC2626" : "#C81E1E"   // white text ≥ 4.8:1
    // Info is indigo, so it stays distinct from the blue accent.
    readonly property color info: dark ? "#A5B4FC" : "#4F46E5"
    readonly property color infoSoft: dark ? "#1B1D3A" : "#EEF0FE"

    function statusColor(tone) {
        switch (tone) {
        case "ok": return ok
        case "warn": return warn
        case "error": return error
        case "info": return info
        case "accent": return accentText
        default: return textMuted
        }
    }
    function statusSoft(tone) {
        switch (tone) {
        case "ok": return okSoft
        case "warn": return warnSoft
        case "error": return errorSoft
        case "info": return infoSoft
        case "accent": return accentSoft
        default: return surfaceAlt
        }
    }

    // ── Typography ──────────────────────────────────────────────────────────
    readonly property string fontFamily: "Noto Sans"
    readonly property int textXs: 12
    readonly property int textSm: 13
    readonly property int textMd: 14
    readonly property int textLg: 16
    readonly property int textXl: 20
    readonly property int text2xl: 26
    readonly property int text3xl: 32

    // ── Spacing (4 px grid), shape, motion ──────────────────────────────────
    readonly property int s1: 4
    readonly property int s2: 8
    readonly property int s3: 12
    readonly property int s4: 16
    readonly property int s5: 20
    readonly property int s6: 24
    readonly property int s8: 32
    readonly property int radiusS: 8
    readonly property int radiusM: 10
    readonly property int radiusL: 16
    readonly property int radiusXl: 22
    readonly property int fast: 120
    readonly property int normal: 200
    readonly property int slow: 360

    // ── Helpers ─────────────────────────────────────────────────────────────
    function hex(c) { return String(c).substring(1) }

    function bytes(n) {
        if (n === undefined || n === null || n < 0) return "–"
        const units = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        let v = n
        while (v >= 1000 && i < units.length - 1) { v /= 1000; i++ }
        return (v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i]
    }
}
