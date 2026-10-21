#!/usr/bin/env bash
# Check prerequisites/artifacts only. This script never executes kexec.
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <capture-directory> <prepared-payload-directory>" >&2
  exit 2
fi
CAPTURE=$1
PAYLOAD=$2
LOADER="${QKX_LOADER_MODULE:-}"

fail() { echo "FAIL: $*" >&2; exit 1; }
check_file() { [ -s "$1" ] || fail "missing or empty file: $1"; }

check_file "$CAPTURE/uname.txt"
check_file "$CAPTURE/cmdline.txt"
check_file "$CAPTURE/iomem.txt"
check_file "$CAPTURE/runtime.dtb"
check_file "$CAPTURE/android.config"
check_file "$PAYLOAD/Image"
check_file "$PAYLOAD/initramfs"
check_file "$PAYLOAD/boot.dtb"
[ -n "$LOADER" ] || fail 'set QKX_LOADER_MODULE to the loader built for this exact Android kernel'
check_file "$LOADER"

command -v adb >/dev/null || fail 'adb is not installed'
adb get-state 2>/dev/null | grep -qx device || fail 'ADB device is not connected'

echo "Captured Android kernel:"
cat "$CAPTURE/uname.txt"
echo
echo "Loader module:"
modinfo "$LOADER" 2>/dev/null | grep -E '^(filename|vermagic|depends):' || {
  echo "warning: modinfo could not inspect module metadata; verify vermagic manually" >&2
}
echo
echo "Payload checksums:"
sha256sum "$PAYLOAD/Image" "$PAYLOAD/initramfs" "$PAYLOAD/boot.dtb" "$LOADER"
echo
echo "Preflight only: no module loaded, no payload pushed, no handoff attempted."
echo "Before any execution, independently verify module vermagic against the captured kernel release,"
echo "audit the loader's Quest 2-specific physical addresses and transition code, and confirm recovery."
