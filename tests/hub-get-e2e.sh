#!/usr/bin/env bash
# Asima Hub's "Get Asima OS" (D39), with no real hardware: "What you'll get on this PC" on fake
# /sys and /proc trees (it never refuses; only the physical limits are marked to fix first), and the
# USB writer on a plain file standing in for the stick (written, read back, compared).
set -uo pipefail
HUB=${1:-build/asimaos-hub}
T=$(mktemp -d)
fails=0
check() { if eval "$2"; then echo "  ok    $1"; else echo "  FAIL  $1"; fails=$((fails + 1)); fi; }
export QT_QPA_PLATFORM=offscreen
pc() { ASIMAOS_HUB_TEST_SYSROOT="$1" "$HUB" --pc-check 2>/dev/null; }
item() { python3 -c 'import json,sys; d=json.loads(sys.argv[1]); i=[x for x in d["items"] if x["id"]==sys.argv[2]][0]; print(i["tone"], i["value"], "blocks" if i["blocks"] else "")' "$1" "$2"; }
gpu() { mkdir -p "$1/sys/bus/pci/devices/0000:01:00.0" && echo 0x030000 > "$1/sys/bus/pci/devices/0000:01:00.0/class" \
        && echo "$2" > "$1/sys/bus/pci/devices/0000:01:00.0/vendor" && echo "$3" > "$1/sys/bus/pci/devices/0000:01:00.0/device"; }
disk() { mkdir -p "$1/sys/block/$2" && echo "$3" > "$1/sys/block/$2/size" && echo "$4" > "$1/sys/block/$2/removable"; }

# A gaming PC: UEFI with Secure Boot on, TPM 2.0, 16 GB, a 1 TB disk plus a USB stick, a new NVIDIA card.
A=$T/gaming
mkdir -p "$A/sys/firmware/efi/efivars" "$A/sys/class/tpm/tpm0" "$A/proc"
printf '\x06\x00\x00\x00\x01' > "$A/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c"
echo 2 > "$A/sys/class/tpm/tpm0/tpm_version_major"
echo "MemTotal:       16303384 kB" > "$A/proc/meminfo"
disk "$A" nvme0n1 1953525168 0 && disk "$A" sda 62521344 1 && disk "$A" loop0 999999999999 0
gpu "$A" 0x10de 0x2684
R=$(pc "$A")
check "a gaming PC: Asima OS will run"                    '[[ $R == *"will run on this PC"* ]]'
check "…UEFI, Secure Boot on, TPM 2.0, new NVIDIA"         '[[ $(item "$R" uefi) == "ok UEFI " && $(item "$R" secureboot) == "ok On " && $(item "$R" tpm) == "ok TPM 2.0 " && $(item "$R" graphics) == "ok NVIDIA " ]]'
check "…the fixed 1 TB disk, not the stick or a loop device" '[[ $(item "$R" disk) == "ok 1 TB " ]]'
check "…16 GB of memory reads as 16 GB"                    '[[ $(item "$R" memory) == "ok 16 GB " ]]'

# An old PC: legacy BIOS, no TPM, 3 GB, a 32 GB disk, an older NVIDIA card.
B=$T/old
mkdir -p "$B/sys/firmware/acpi" "$B/proc"
echo "MemTotal:        3020000 kB" > "$B/proc/meminfo"
disk "$B" sda 62521344 0
gpu "$B" 0x10de 0x1b80
R=$(pc "$B")
check "an old PC: two things to fix first, nothing refused" '[[ $R == *"fix this first"* && $R == *"start mode"* && $R == *"disk"* ]]'
check "…legacy BIOS and a small disk are what blocks"      '[[ $(item "$R" uefi) == "error Legacy BIOS blocks" && $(item "$R" disk) == *"blocks" ]]'
check "…no TPM, little memory, older NVIDIA: only notes"    '[[ $(item "$R" tpm) == "info No TPM 2.0 " && $(item "$R" memory) == warn* && $(item "$R" graphics) == "warn Older NVIDIA " ]]'

# Inside a sandbox nothing of the firmware can be read: said so, never guessed.
C=$T/sandbox && mkdir -p "$C"
R=$(pc "$C")
check "a sandbox: what can't be read is said, nothing blocks" '[[ $(item "$R" uefi) == "info Can"*"be read here " && $R == *"will run on this PC"* ]]'
# A container shows an empty /sys/firmware: not taken for legacy BIOS. A TPM 2.0 seen only through
# its resource manager (kernels before 5.6); a virtual machine's graphics card.
D=$T/container
mkdir -p "$D/sys/firmware" "$D/sys/class/tpmrm/tpmrm0" "$D/proc"
gpu "$D" 0x1234 0x1111
R=$(pc "$D")
check "a container: an empty /sys/firmware isn't legacy BIOS" '[[ $(item "$R" uefi) == "info Can"*"be read here " && $R == *"will run on this PC"* ]]'
check "…TPM 2.0 found through tpmrm0; other graphics noted"  '[[ $(item "$R" tpm) == "ok TPM 2.0 " && $(item "$R" graphics) == "info Other " ]]'
R=$(ASIMAOS_HUB_TEST_ARCH=aarch64 pc "$A")
check "a PC that isn't 64-bit x86 is told plainly"          '[[ $(item "$R" arch) == "error aarch64 blocks" ]]'

# The USB writer, on a file standing in for the stick.
head -c 23000000 /dev/urandom > "$T/asimaos.iso"
SUM=$(sha256sum "$T/asimaos.iso" | cut -d' ' -f1)
R=$(ASIMAOS_HUB_TEST_TARGET="$T/stick.img" "$HUB" --write-test "$T/asimaos.iso" --sha256 "$SUM" 2>/dev/null)
check "the ISO is written to the stick and checked"         '[[ $? -eq 0 && $R == *"\"state\":\"done\""* && $(sha256sum < "$T/stick.img" | cut -d" " -f1) == "$SUM" ]]'
printf 'old data that must go' > "$T/stick.img"
R=$(ASIMAOS_HUB_TEST_TARGET="$T/stick.img" "$HUB" --write-test "$T/asimaos.iso" --sha256 "$(printf 'b%.0s' {1..64})" 2>/dev/null)
check "an ISO that doesn't match the signed checksum is refused" '[[ $? -ne 0 && $R == *changed* ]]'
R=$(ASIMAOS_HUB_TEST_TARGET="$T/stick.img" "$HUB" --write-test "$T/missing.iso" --sha256 "$SUM" 2>/dev/null)
check "without a checked download nothing is written"       '[[ $? -ne 0 && $R == *"Download Asima OS first"* ]]'
R=$("$HUB" --write-test "$T/asimaos.iso" --sha256 "$SUM" 2>&1)
check "the test mode writes only to its test file"          '[[ $? -eq 2 ]]'

rm -rf "$T"
if [[ $fails -eq 0 ]]; then echo "Asima Hub Get Asima OS: all checks passed"; else echo "Asima Hub Get Asima OS: $fails check(s) failed"; exit 1; fi
