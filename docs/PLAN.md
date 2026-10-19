# Port plan: Recalbox -> Radxa Dragon Q6A

## Upstream model
Upstream (`gitlab.com/recalbox/recalbox`) is a Buildroot BR2_EXTERNAL tree: `configs/recalbox-<target>_defconfig`,
`board/recalbox/<family>/<board>/`, `package/`, plus a `BR2_PACKAGE_RECALBOX_TARGET_*` switch per target.
Existing aarch64 targets: rpi4_64, rpi5_64, rg353x (RK3566, U-Boot), odroidgo2. Also x86_64 (UEFI + grub2).

## Strategy
Hybrid of two existing targets:
- **rg353x**: aarch64 toolchain (glibc, GCC 14), custom mainline kernel + fragment, squashfs rootfs, genimage.
- **x86_64**: UEFI boot flow (no board U-Boot; the Q6A firmware is edk2/UEFI, DTB supplied by firmware).
  Sibling Ubuntu project confirmed: systemd-boot/BLS on the ESP works; grub2-efi (arm64) is the likely fit for Recalbox.

## Milestones
1. **M0 Bootstrap** - `scripts/bootstrap.sh` clones upstream, overlays our files. Build host: Linux VM.
2. **M1 Skeleton target** - `recalbox-q6a_defconfig`, `BR2_PACKAGE_RECALBOX_TARGET_Q6A` in upstream Config.in/package
   (small patch in `patches/`), genimage layout (ESP + boot + share), empty-ish image that builds.
3. **M2 Kernel** - mainline 7.2.x (as in Ubuntu project, Armbian edge patches for QCS6490 DP/DPU) + fragment:
   GPU (msm/a6xx), DPU/DP, UFS/NVMe/SD, USB3, PCIe, WCD938x/SoundWire/LPASS, FastRPC optional.
   Firmware blobs (adreno a660/a643 zap, venus, wcd, ath/aic) packaged into the rootfs.
4. **M3 Boot to console** - serial + HDMI console, SSH.
5. **M4 Graphics** - Mesa Freedreno/Turnip (GLES 3.x, Vulkan 1.3) for EmulationStation + libretro cores.
6. **M5 Peripherals** - Wi-Fi/BT (AIC8800 out-of-tree driver), audio, USB pads, HDMI-CEC.
7. **M6 Emulators** - enable aarch64 core set; benchmark A78 x4 + A55 x4 (big.LITTLE affinity tuning).
8. **M7 Release** - image + installer, upstream-ready patches.

## Risks
- Mainline kernel for QCS6490 still missing pieces (Wi-Fi/BT out-of-tree, some GPU/DP patches).
- Recalbox uses SysV init + its own boot scripts assuming rpi/x86/rockchip conventions (boot partition, `recalbox-boot.conf`).
- Upstream packages gated by target switch (e.g. Mesa drivers, emulator selection) need q6a entries.
- Full Buildroot build is hours; needs ~100GB disk, 16GB+ RAM recommended.

## Open items
- Linux build host access (ssh) - pending from user.
- Pick kernel source: vanilla + our patch queue vs. Armbian edge tree.

## Status log
### 2026-10-10 - M1 done: first image builds (`recalbox-q6a.img.xz`, ~1.6 GB)
Build host: Desktop (20c/61GB), ~87 min cold, ~7 min incremental (ccache). Notes to reproduce:
- Host needs: gcc-14 wrappers (Ubuntu 26.04 default GCC 15 / C23 breaks old host pkgs; `-std=gnu17`, `-Wno-error=incompatible-pointer-types`),
  cmake 3.31 first in PATH (CMake 4 rejects old policies), `CMAKE_POLICY_VERSION_MINIMUM=3.5`, `LC_ALL=C`, aclocal-1.16/automake-1.16 symlinks.
- gitlab.com `/-/archive/` tarballs return 403: fetch via REST API into `dl/` (scripts/fetch_gitlab.py).
- Patches carried: qemu `sched_attr` rename (glibc 2.41+), GCC 14.2 libsanitizer without linux/scc.h.
- Q6A added next to RG353X in the per-target emulator branches (generic arm64).

TODO re-enable / fix (disabled for the first image): Kodi, libretro-{emuscv,flycast,flycast-next,mame2015,pcsx_rearmed,vircon32}, wsd (upstream repo gone),
out-of-tree modules (xone, xpad-noone, xpadneo, rtl8812au, rtl88x2bu, rtw89).
Not yet verified on hardware: boot, squashfs/overlay in kernel, HDMI, Wi-Fi (AIC8800), audio, input.

### 2026-10-10 - First boot on hardware (USB SATA SSD): OK
Booted straight into EmulationStation; 8BitDo pad (USB) works; games run (NES confirmed; PS1 and Dreamcast confirmed later); Ethernet works.
Fixed after first boot (rootfs updated over the network, no reflash needed):
- No sound card / no Wi-Fi / no Bluetooth. Root cause: missing firmware, not the kernel. DSP firmware
  (`qcom/qcs6490/radxa/dragon-q6a/{adsp,cdsp}.mbn`), `qcom/qcm6490/qupv3fw.elf`, AudioReach topology and the Radxa
  alsa-ucm-conf backport come from the Radxa .deb packages (new package `q6a-firmware`); the AIC8800 USB Wi-Fi/BT
  driver is built out of tree from the Radxa DKMS source (new package `aic8800`).
- Result: ALSA card `QCS6490-Radxa-Dragon-Q6A` registered, PulseAudio+UCM exposes HDMI and Headphones sinks (PCM hw_ptr advances);
  `wlan0` scans, `hci0` UP; a Bluetooth speaker pairs and shows up as an A2DP sink.
Notes: the kernel/ADSP log lines `qcom-apm ... CMD timeout` and `SWR Port collision` also appear on the working Ubuntu image (benign).
Confirmed on hardware by the user: HDMI audio, headphone jack audio, Bluetooth audio + BT gamepad, Wi-Fi all work. `tsched=no` was not needed (not persisted).
Cosmetic: a few seconds of white screen at boot (GPU firmware loads after rootfs mount); could be fixed by embedding a660 firmware in the initramfs.
Update the board without reflashing: copy `output/images/boot-data/boot/recalbox` to `/boot/boot/recalbox.new` (remount /boot rw), rename, reboot.

### 2026-10-10 - Recalbox installed on the internal NVMe (free space after the Ubuntu partition)
Shrinking the Ubuntu ext4 from the running Recalbox was attempted and aborted: during heavy NVMe I/O the NVMe and the USB hub both
dropped (brown-out suspected; kernel logged `Host Aborted Command` and the NVMe node disappeared). Nothing was lost (fsck clean,
GPT unchanged) but it is not worth repeating: shrink offline / with a solid PD supply, or do it from a live system with the disk unmounted.
The user then freed ~70 GiB at the end of the disk. Installation is only:
1. `sgdisk -n 5:<aligned start>:+5GiB -t 5:EF00 -c 5:boot /dev/nvme0n1` in the free space (5 GiB), `mkfs.vfat -F 32 -n RECALBOX /dev/nvme0n1p5`.
2. `rsync` the whole `output/images/boot-data/` tree onto it (EFI/BOOT/bootaa64.efi = GRUB, boot/{linux,initrd.gz,recalbox}); verify with sha256.
3. Leave the rest unallocated: Recalbox's first boot (`S11share`) creates SHARE (exFAT) and OVERLAY (ext4, 1 GiB) in the LAST free
   space of the same disk and understands `nvme0n1pN` names. rEFInd (fallback install in the ESP) lists the new EFI entry automatically.
4. The kernel command line selects the boot partition by label `RECALBOX`: unplug any other disk carrying that label before the first boot.
Throughput note: copying ROMs from a Mac over Wi-Fi gave only ~3 MB/s; use a wired link or plug the SSD/SD directly.
Result: first boot from the NVMe worked on the first try. S11share created p6 SHARE (62.7 GiB exFAT) and p7 OVERLAY (1 GiB ext4);
/boot = nvme0n1p5, share = p6; wlan0, hci0 and the sound card are present; no I/O errors in dmesg. Note: after the very first boot
/overlay is still a tmpfs - reboot once so the OVERLAY partition is used. Settings (Wi-Fi, Bluetooth pairings, recalbox.conf) live in
the share, so a fresh install starts with defaults; copy `share/system` from the old install to keep them.

### 2026-10-10 - Hardware test of the shipped image (maintainer)
Every emulator and PC port included in the image was opened and ran on the board; PS1 and Dreamcast were tested in particular with
games copied from an R36S card. Exhaustive per-game compatibility and performance benchmarks are still not done.
Still not in the image: Kodi, vircon32, flycast-next, wsd.

### 2026-10-12 - v0.1.1 prepared
v0.1.0 (published 2026-10-11) shipped the earlier image: 4K30 as the default mode on 4K TVs (half-speed 60 fps games and wobbling audio),
VERSION `development`, BOARD `unknown`, an audio.device inherited from the Raspberry Pi and official updates enabled.
v0.1.1: kernel filters exposed HDMI modes (msm.dp_max_width/height, dp_hires_max_refresh, dp_min_refresh), ES shows the device tree model
for unknown boards, version 0.1.1, safer conf defaults, optional governor/run-ahead/reduce-latency settings. The assets live in
release/v0.1.1/ (git-ignored): 1.4 GB part00 + 321.7 MB part01 + SHA256SUMS. Not published yet.
Open: ES gamelist hang when opening some games (netconsole capture helper worked; no reproduction captured yet); optional update channel.

### 2026-10-19 - Root cause of the "game freezes on its first frame" bug
Captured live (persistent kernel log + heartbeat from custom.sh). RetroArch (MAME2003+) alive, ~1 s of CPU in 3+ minutes, all threads on futex, PulseAudio
`threaded-ml` in poll; the PulseAudio HDMI sink was RUNNING with the RetroArch stream attached; the kernel logged at the same second
`qcom-apm: DSP returned error[1001002]`, `Failed to start APM port 104`, `ASoC error (-22) at soc_dai_trigger() on DISPLAY_PORT_RX_0`
(`MultiMedia2 Playback: trigger FE cmd: 1 failed`). Nothing consumes the audio, the emulator blocks on it. `pactl suspend-sink <HDMI>`
1 then 0 re-triggers the port and the game resumed immediately (CPU 164 -> 260 -> 329 ticks). The same error was behind the ES freeze of 2026-10-11.
Earlier ES log signatures (12-13 Oct): after "Start in-game Hardware processes" the game exit never completes (no "Stop in-game", no "No error running").
Fix: extras/q6a-audiofix.sh (reads /dev/kmsg, cycles the HDMI sink, max 5 tries/min), installed on the board via custom.sh, to be shipped in the image
(fsoverlay init script) in the next release. Root cause (why the DSP port start fails, probably a DP audio / modeset race) is still open: candidates are
a kernel/driver fix or starting audio after the modeset.
