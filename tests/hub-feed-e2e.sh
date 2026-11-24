#!/usr/bin/env bash
# Asima Hub's release feed: a feed is used only when the feed key signed it. A throwaway Ed25519 key
# (OpenSSL) signs a sample feed; Asima Hub must read it, and refuse it when a byte changed, the
# signature is missing, another key signed it or it is in the old format. No network: --check-feed
# reads files.
set -uo pipefail
HUB=${1:-build/asimaos-hub}
T=$(mktemp -d)
fails=0
check() { if eval "$2"; then echo "  ok    $1"; else echo "  FAIL  $1"; fails=$((fails + 1)); fi; }
export QT_QPA_PLATFORM=offscreen
hub() { "$HUB" --check-feed "$@" 2>/dev/null; }
keygen() { openssl genpkey -algorithm ed25519 -out "$1.pem" 2>/dev/null; }
pubhex() { openssl pkey -in "$1.pem" -pubout -outform DER | tail -c 32 | od -An -v -tx1 | tr -d ' \n'; }
sign() { openssl pkeyutl -sign -rawin -inkey "$T/test.pem" -in "$1" -out "$1.sig"; }

keygen "$T/test" && keygen "$T/other"
KEY=$(pubhex "$T/test")
OTHER=$(pubhex "$T/other")
SUM=$(printf 'a%.0s' {1..64})

cat > "$T/feed.json" <<EOF
{ "format": 2,
  "releases": [
    { "version": "2026.12.01.1", "channel": "beta", "date": "2026-12-01", "notes": ["One"],
      "update": { "url": "https://example.invalid/u.aosupd", "size": 10, "sha256": "$SUM" },
      "iso": { "url": "https://example.invalid/a.iso", "size": 20, "sha256": "$SUM" } },
    { "version": "2026.11.18.1", "channel": "beta", "date": "2026-11-18", "notes": ["Two"] },
    { "version": "not-a-version", "notes": ["ignored"] } ],
  "news": [ { "date": "2026-12-01", "title": "Out now", "text": "News.", "link": "https://example.invalid/n" },
            { "date": "no date", "title": "ignored" } ],
  "groups": [ { "id": "gaming", "title": "Gaming", "apps": [ { "id": "com.valvesoftware.Steam", "from": "flathub" } ] } ],
  "hub": { "version": "0.2.0" },
  "reports": { "email": "reports@example.invalid" } }
EOF
sign "$T/feed.json"

R=$(hub "$T/feed.json" --feed-key "$KEY")
check "a feed signed with the feed key is read"                 '[[ $R == *"\"ok\":true"* ]]'
check "…the newest release, its update file and its ISO"        '[[ $R == *"\"latest\":\"2026.12.01.1\""* && $R == *u.aosupd* && $R == *a.iso* ]]'
check "…only the valid releases and news"                       '[[ $R == *"\"releases\":2"* && $R == *"\"news\":1"* ]]'
check "…the app groups, the Hub's version and the report address" '[[ $R == *"\"groups\":1"* && $R == *"\"hub\":\"0.2.0\""* && $R == *"\"reports\":true"* ]]'

sed 's/Out now/Out NOW/' "$T/feed.json" > "$T/changed.json" && cp "$T/feed.json.sig" "$T/changed.json.sig"
R=$(hub "$T/changed.json" --feed-key "$KEY")
check "a feed changed after signing is refused"                 '[[ $? -ne 0 && $R == *"\"ok\":false"* && $R == *signed* ]]'
R=$(hub "$T/feed.json" --feed-key "$OTHER")
check "a feed signed with another key is refused"               '[[ $? -ne 0 && $R == *"\"ok\":false"* ]]'
R=$(hub "$T/feed.json")
check "the built-in key refuses a feed signed with a test key"  '[[ $? -ne 0 && $R == *"\"ok\":false"* ]]'
cp "$T/feed.json" "$T/unsigned.json"
R=$(hub "$T/unsigned.json" --feed-key "$KEY")
check "a feed without its signature is refused"                 '[[ $? -ne 0 && $R == *"\"ok\":false"* ]]'

sed 's#https://example.invalid/u.aosupd#http://example.invalid/u.aosupd#' "$T/feed.json" > "$T/http.json" && sign "$T/http.json"
R=$(hub "$T/http.json" --feed-key "$KEY")
check "an update file without https is not offered"             '[[ $R == *"\"ok\":true"* && $R == *"\"update\":\"\""* ]]'
printf '{ "format": 1, "releases": [] }\n' > "$T/old.json" && sign "$T/old.json"
R=$(hub "$T/old.json" --feed-key "$KEY")
check "the old format is refused, even when signed"             '[[ $? -ne 0 && $R == *"understand"* ]]'

rm -rf "$T"
if [[ $fails -eq 0 ]]; then echo "Asima Hub feed: all checks passed"; else echo "Asima Hub feed: $fails check(s) failed"; exit 1; fi
