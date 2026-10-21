# Quest 2 kexec integration

This directory starts the kexec path for the Quest 2 port. It intentionally does **not** attempt the kernel handoff yet: a wrong handoff can hang or reboot the headset, and the upstream `machachu56/quest-kexec-q2` project documents Quest Pro-only testing.

## Current status

- [x] Create a separate integration path without changing the existing boot-image workflow.
- [x] Capture the *runtime* device tree and exact running-kernel details from a rooted headset.
- [x] Preflight the Android connection and build artifacts before any handoff.
- [ ] Port/build the loader module against the exact Android kernel running on the Quest 2.
- [ ] Adapt payload preparation to the Quest 2 runtime DTB, memory map and SteamOS kernel.
- [ ] Validate early boot, GPU/display, USB, SyncBoss/tracking and recovery on actual hardware.
- [ ] Add the kexec launch only after those checks pass.

## Prerequisites

On the Linux host: `adb`, `dtc`, `python3`, `sha256sum`, and a USB connection. On the headset: ADB enabled and a working root method (`su`). Kexec avoids an unlocked bootloader; it does **not** grant root access.

## Capture the headset state

From the repository root:

```sh
bash kexec/capture-quest2.sh
```

The script writes a timestamped directory under `kexec/out/`. It reads runtime information only; it does not flash, reboot, or load a module. Keep this output private before sharing because it can include device-specific configuration.

## Preflight a prepared payload

After a Quest 2-compatible loader has been built and a payload prepared, check the inputs:

```sh
bash kexec/preflight.sh kexec/out/capture-YYYYMMDD-HHMMSS /path/to/payload
```

The payload directory is expected to contain `Image`, `initramfs`, and `boot.dtb`; the loader module path is provided as `QKX_LOADER_MODULE`. This check does not prove that the handoff is safe and does not execute kexec.

## Important compatibility boundary

The existing SteamOS image is assembled around Meta's Quest 2 4.19 kernel and boot-time device tree. A kexec target cannot assume that bootloader-initialised devices will survive a warm handoff. In particular, preserve the live hardware state and validate memory reservations, Qualcomm/Meta display and GPU state, USB, SyncBoss/QMP and secure memory before enabling execution.

Do not use a Quest Pro kernel module or its hard-coded physical addresses on Quest 2 without auditing and adapting them. Never flash `abl` or `xbl`. Keep the stock boot image and a tested recovery route available.
