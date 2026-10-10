# Recalbox for the Radxa Dragon Q6A

Port of [Recalbox](https://gitlab.com/recalbox/recalbox) (the Buildroot-based retro-gaming OS) to the
[Radxa Dragon Q6A](https://docs.radxa.com/en/dragon/q6a) (Qualcomm QCS6490: 4x Cortex-A78 + 4x Cortex-A55, Adreno 643).

**Status: working on real hardware.** Boots straight into EmulationStation from a USB/SATA SSD (UEFI + GRUB),
Mesa Freedreno (OpenGL ES) for the emulators, mainline Linux 7.2.9.

## What works

| | |
|---|---|
| Boot, EmulationStation, 8/16-bit games | yes |
| HDMI video | yes (see the resolution note below) |
| HDMI audio and 3.5 mm headphone jack | yes |
| Wi-Fi (onboard AIC8800) | yes |
| Bluetooth (audio devices and gamepads) | yes |
| USB gamepads / keyboard / mouse | yes |
| Gigabit Ethernet | yes |
| PS1 (`pcsx_rearmed`), Dreamcast (`flycast`), MAME 2015, N64, etc. | cores build and load; performance not benchmarked yet |

Not done yet: Kodi, Vulkan (Turnip is not in this Buildroot), a few minor cores
(`vircon32`, `flycast-next`), an installer, and a faster boot (a few seconds of white screen while the GPU firmware loads).
See [docs/PLAN.md](docs/PLAN.md) for the full status log and roadmap.

## Attention: video resolution

The Dragon Q6A HDMI output is limited to **4K at 30 Hz** ([Radxa specs](https://docs.radxa.com/en/dragon/q6a)). That is a hardware limit, not something the
system can change. If you plug the board into a 4K/120 Hz TV or monitor, Recalbox may pick a mode that looks
sluggish. Set the global video mode to **1080p at the highest refresh rate your display supports**
(for example 1080p120 on a 120 Hz TV) in *Menu -> System settings -> Video*. The board was tested like this on
a QHD 144 Hz monitor (smooth) and on a 4K 120 Hz TV (1080p120).

## How the port is built

This repository contains only the Q6A-specific delta. Upstream Recalbox is cloned unmodified and the series in
[`patches/`](patches) is applied on top.

```bash
./scripts/bootstrap.sh          # clone upstream into ./recalbox and apply patches/
cd recalbox
make recalbox-q6a_defconfig
make -j"$(nproc)"               # first build takes ~90 min on 20 cores; later ones a few minutes (ccache)
```

The result is `recalbox/output/images/recalbox/recalbox-q6a.img.xz` (GPT disk with one FAT32 `RECALBOX` partition:
GRUB arm64-EFI, kernel, initramfs and the squashfs root). Write it to a USB or SATA SSD, boot the board from it
(UEFI boot menu or rEFInd), and Recalbox creates the share partition on first start.

### Build host notes

Upstream Buildroot is old; a very new host (Ubuntu 26.04) needs a few workarounds. They are collected in
[docs/PLAN.md](docs/PLAN.md): GCC 14 for host tools (GCC 15 defaults to C23), CMake 3.31 first in `PATH`
(CMake 4 rejects old projects), `CMAKE_POLICY_VERSION_MINIMUM=3.5`, `LC_ALL=C`, `TERM` set, and
`dpkg-deb` + `rsync` installed. `gitlab.com/.../-/archive/` tarballs return 403; fetch them through the REST API
with [`scripts/fetch_gitlab.py`](scripts/fetch_gitlab.py).

### Updating a running board without re-flashing

Copy `output/images/boot-data/boot/recalbox` to `/boot/boot/recalbox.new` on the board (remount `/boot`
read-write), rename it over `recalbox` (keep the old one as `recalbox.old` to roll back) and reboot.

## Firmware and licences

The board needs Qualcomm DSP firmware, the AudioReach topology and the AIC8800 Wi-Fi/Bluetooth firmware. The build
downloads Radxa's packages ([radxa-pkg](https://github.com/radxa-pkg)) and does not redistribute them in this
repository. The `aic8800` out-of-tree driver is GPL-2.0 (taken from Radxa's DKMS package).

## Related projects

- `ubuntu-26.04.1-dragon-q6a`: custom Ubuntu 26.04 image for the same board; source of the hardware recipe
  (kernel, firmware, UCM, AIC8800).

License: MIT (see [LICENSE](LICENSE)). Upstream Recalbox and the emulators keep their own licenses.
