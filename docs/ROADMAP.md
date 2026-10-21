# Roadmap

Roughly in the order we expect to work on them.

## 1. Locked headsets through kexec

**Goal:** run SteamOS on a Quest 2 **without unlocking the bootloader**.

Kexec lets a running Linux kernel load and start another kernel directly, without going through the bootloader. [Quest-KeXec](https://github.com/machachu56/quest-kexec-q2) does this for Meta headsets. It's a kernel module, based on [kexec-at-home](https://github.com/provide-salad/kexec-at-home), that loads into the running Quest OS kernel and boots a custom kernel and initramfs from there. So far it has only been developed and tested on the Quest Pro.

The first integration scaffold is in [`kexec/`](../kexec/README.md). It adds a read-only runtime-state capture script and a preflight checker; neither attempts a handoff. The plan from here:

1. Capture runtime DTB, kernel config, release, command line and memory map with `bash kexec/capture-quest2.sh` on a rooted Quest 2.
2. Build/port the loader module against the exact Android kernel running on the headset; verify its `vermagic` and symbol CRCs.
3. Adapt payload preparation and the transition code to Quest 2-specific memory reservations and live hardware state (display/GPU, USB, SyncBoss/QMP and secure memory).
4. Boot the SteamOS kernel and initramfs through kexec instead of `fastboot flash boot`, while retaining the existing image-based route.
5. Validate logs and a recovery path on real hardware before enabling a one-command launch.

**Current status:** capture and preflight scaffolding only. There is not yet a Quest 2-validated loader or executable handoff in this repository. Root access on Quest OS is still required to load a kernel module; kexec removes the need to unlock the bootloader, not the need for root.

## 2. Sound

The Quest 2 uses Qualcomm's audio DSP (ADSP) for its speakers and microphones. In the kernel, no sound card registers ("ALSA device list:" is empty). The parts are Meta's audio drivers in the kernel tree, the DSP firmware from the vendor partition, and a mixer setup taken from Android's `mixer_paths.xml`. Until then, PipeWire has no output, and some games refuse to start. Adding a silent output (the `nonullsink` switch) didn't work yet, because PipeWire's pulse layer refused it ("Not supported").

## 3. A faster Steam interface

Steam's VR panels render at about 10 to 20 frames per second. The aim is 60. The next things to look at are the web interface's GPU process, and whole-panel redraws when only part of the panel changes.

## 4. Power menu, sleep and wake

The power button's short and long presses reach Steam (`steam://shortpowerpress`), but Steam's power menu doesn't open. Steam probably expects something from Valve's session manager that isn't running here. Sleep is turned off, because the panel and the GPU don't come back yet.

## 5. VRChat and Android apps

Lepton (Valve's Android container) starts Android, with networking and the GPU driver. VRChat doesn't run yet.

## Also on the list

- Testing x86 Linux games through FEX-Emu.
- KernelSU for the Quest 2 kernel.
- A GitHub workflow that builds the final boot image as well, so a fork can produce everything without a Linux PC.
- Reporting the Ruby problem to Valve, so the Proton fix becomes unnecessary.
