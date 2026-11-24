import QtQuick

// Text with Asima UI typography. variant: display | title | heading | body | small | caption | overline
// tone: default | muted | subtle | accent | ok | warn | error | info | onAccent
Text {
    id: label
    property string variant: "body"
    property string tone: "default"

    font.family: Theme.fontFamily
    font.pixelSize: {
        switch (variant) {
        case "display": return Theme.text3xl
        case "title": return Theme.text2xl
        case "subtitle": return Theme.textXl
        case "heading": return Theme.textLg
        case "small": return Theme.textSm
        case "caption":
        case "overline": return Theme.textXs
        default: return Theme.textMd
        }
    }
    font.weight: {
        switch (variant) {
        case "display": return Font.Bold
        case "title":
        case "subtitle":
        case "heading": return Font.DemiBold
        case "overline": return Font.Bold
        default: return Font.Normal
        }
    }
    font.letterSpacing: variant === "overline" ? 0.9 : (variant === "display" || variant === "title") ? -0.4 : 0
    font.capitalization: variant === "overline" ? Font.AllUppercase : Font.MixedCase
    lineHeight: (variant === "body" || variant === "small") ? 1.15 : 1.0
    color: {
        switch (tone) {
        case "muted": return Theme.textMuted
        case "subtle": return Theme.textSubtle
        case "accent": return Theme.accentText
        case "onAccent": return Theme.textOnAccent
        case "ok":
        case "warn":
        case "error":
        case "info": return Theme.statusColor(tone)
        default: return Theme.text
        }
    }
    textFormat: Text.PlainText
    verticalAlignment: Text.AlignVCenter
    Accessible.role: Accessible.StaticText
    Accessible.name: text
}
