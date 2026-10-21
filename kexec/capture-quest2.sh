#!/usr/bin/env bash
# Capture runtime state needed to port kexec. Read-only on the headset.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUT_ROOT="${Q2KEXEC_OUT:-$ROOT/kexec/out}"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="${1:-$OUT_ROOT/capture-$STAMP}"

command -v adb >/dev/null || { echo "error: adb is required" >&2; exit 1; }
command -v dtc >/dev/null || { echo "error: dtc is required (device-tree-compiler)" >&2; exit 1; }
command -v sha256sum >/dev/null || { echo "error: sha256sum is required" >&2; exit 1; }
mkdir -p "$OUT"

adb get-state 2>/dev/null | grep -qx device || {
  echo "error: no ADB device; enable USB debugging and accept the host key" >&2; exit 1;
}
adb shell 'su -c id' 2>/dev/null | tr -d '\r' | grep -q 'uid=0' || {
  echo "error: root is required (adb shell su -c id must report uid=0)" >&2; exit 1;
}

su_cmd() { adb shell "su -c '$1'" | tr -d '\r'; }

echo "Capturing Quest runtime details into: $OUT"
su_cmd 'uname -a' > "$OUT/uname.txt"
su_cmd 'cat /proc/version' > "$OUT/proc-version.txt"
su_cmd 'cat /proc/cmdline' > "$OUT/cmdline.txt"
su_cmd 'cat /proc/iomem' > "$OUT/iomem.txt"
su_cmd 'cat /proc/partitions' > "$OUT/partitions.txt"
su_cmd 'getprop' > "$OUT/getprop.txt"
su_cmd 'cat /sys/devices/soc0/machine 2>/dev/null; cat /sys/devices/soc0/family 2>/dev/null; cat /sys/devices/soc0/soc_id 2>/dev/null' > "$OUT/soc.txt" || true
su_cmd 'zcat /proc/config.gz' > "$OUT/android.config" 2>"$OUT/config-error.txt" || {
  echo "warning: /proc/config.gz unavailable; see config-error.txt" >&2
}
adb shell 'su -c "tar -C /proc/device-tree -cf - ."' |
  tar --warning=no-timestamp -C "$OUT" -xf -
# Keep the flattened device-tree filesystem separate from the text diagnostics;
# dtc -I fs must point at a directory containing only device-tree nodes/files.
mkdir -p "$OUT/runtime-tree"
adb shell 'su -c "tar -C /proc/device-tree -cf - ."' |
  tar --warning=no-timestamp -C "$OUT/runtime-tree" -xf -
dtc -q -I fs -O dtb "$OUT/runtime-tree" -o "$OUT/runtime.dtb"
adb shell 'su -c "cat /sys/firmware/fdt"' > "$OUT/boot-fdt.bin" 2>/dev/null || true

(
  cd "$OUT"
  find . -maxdepth 1 -type f ! -name SHA256SUMS -print0 |
    sort -z | xargs -0 -r sha256sum > SHA256SUMS
)

echo
echo "Capture complete. Review:"
echo "  $OUT/uname.txt"
echo "  $OUT/cmdline.txt"
echo "  $OUT/iomem.txt"
echo "  $OUT/android.config"
echo "  $OUT/runtime.dtb"
echo
echo "No module was loaded and no reboot/flash was attempted."
