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
