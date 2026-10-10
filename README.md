# Recalbox for the Radxa Dragon Q6A

Port of [Recalbox](https://gitlab.com/recalbox/recalbox) (the Buildroot-based retro-gaming OS) to the
[Radxa Dragon Q6A](https://docs.radxa.com/en/dragon/q6a) (Qualcomm QCS6490: 4x Cortex-A78 + 4x Cortex-A55, Adreno 643).
Boots straight into EmulationStation from a USB 3.0 / SATA SSD or from the internal NVMe, with video, audio, Wi-Fi and
Bluetooth working, on a mainline Linux 7.2.9 kernel.

Sibling project of [ubuntu-26.04.1-dragon-q6a](https://github.com/rafaelwms/ubuntu-26.04.1-dragon-q6a), which provided the
hardware recipe (firmware, audio UCM, AIC8800 Wi-Fi/BT).

🇧🇷 **[Leia em português mais abaixo](#português)**

---

## English

### What works

| | Status |
|---|---|
| Boot (UEFI + GRUB), EmulationStation | ✅ |
| HDMI video | ✅ (see the resolution note below) |
| Audio: HDMI **and** 3.5 mm headphone jack | ✅ |
| Wi-Fi (onboard AIC8800) | ✅ |
| Bluetooth: speakers/headphones and gamepads | ✅ |
| USB gamepads, keyboard, mouse | ✅ |
| Gigabit Ethernet | ✅ |
| Tested emulators | NES, **PS1** (`pcsx_rearmed`), **Dreamcast** (`flycast`) |
| Other cores (N64, MAME 2015, ...) | build and load; performance not benchmarked yet |

### Known limitations

- **Video is limited to 4K@30 Hz** by the board's HDMI output ([Radxa specs](https://docs.radxa.com/en/dragon/q6a)). On a
  4K/120 Hz TV or monitor, set the global video mode to **1080p at the highest refresh rate** your display supports
  (*Menu → System settings → Video*; e.g. 1080p120). Tested on a QHD 144 Hz monitor and on a 4K 120 Hz TV at 1080p120.
- A few seconds of white screen at boot, while the GPU firmware loads. Cosmetic.
- Not included yet: Kodi, Vulkan (Turnip is not in this Buildroot), and a few minor cores (`vircon32`, `flycast-next`).
- Power: the board can brown out under heavy NVMe + USB load. Use a good USB-C PD supply.

See [docs/PLAN.md](docs/PLAN.md) for the full status log, the dead ends and the roadmap.

### Install a pre-built image

1. Go to [Releases](../../releases) and download **all** `.part*` files plus the two `SHA256SUMS-*.txt` files.
2. Run the interactive installer for your OS — it verifies the checksums, reassembles the image and flashes it, asking you
   to confirm the exact target device before writing anything:

   ```bash
   ./install.sh       # Linux
   ./install_mac.sh   # macOS
   ```

   Or by hand (Linux):

   ```bash
   sha256sum -c SHA256SUMS-parts.txt --ignore-missing
   cat recalbox-radxa-dragon-q6a_<version>.img.xz.part* > image.img.xz
   sha256sum -c SHA256SUMS-full.txt --ignore-missing
   xzcat image.img.xz | sudo dd of=/dev/YOUR_DEVICE bs=4M status=progress conv=fsync
   ```

   ⚠️ Triple-check the target with `lsblk` first: this erases the whole device.

3. Boot the board from it (UEFI boot menu, or rEFInd). The **first boot takes 1–2 minutes**: Recalbox creates its `SHARE`
   (exFAT) and `OVERLAY` (ext4) partitions in the free space of the disk. Do not power off during this step.
4. SSH is enabled: user `root`, password `recalboxroot` (change it in `recalbox.conf`).

### Install on the internal NVMe next to other systems

If the NVMe already holds other systems (e.g. Ubuntu, Windows) you do **not** need to erase it. Leave ≥ 8 GiB of free space at
the end of the disk, then add a 5 GiB boot partition there and copy the image's contents into it:

```bash
xzcat recalbox-radxa-dragon-q6a_<version>.img.xz > recalbox.img
sudo sgdisk -n 5:0:+5GiB -t 5:EF00 -c 5:boot /dev/nvme0n1     # adjust the partition number
sudo mkfs.vfat -F 32 -n RECALBOX /dev/nvme0n1p5
sudo losetup -rfP --show recalbox.img                          # prints /dev/loopN
sudo mount -o ro /dev/loopNp1 /mnt/img && sudo mount /dev/nvme0n1p5 /mnt/rb
sudo cp -r /mnt/img/. /mnt/rb/ && sync
```

Leave the rest unallocated: the first boot creates `SHARE` and `OVERLAY` there. rEFInd / the firmware lists the new entry
automatically. Boot partitions are found by the label `RECALBOX`: unplug any other disk carrying that label first.

### Build it yourself from source

This repository contains only the Q6A-specific delta; upstream Recalbox is cloned unmodified and the series in
[`patches/`](patches) is applied on top.

```bash
./scripts/bootstrap.sh          # clone upstream into ./recalbox and apply patches/
cd recalbox
make recalbox-q6a_defconfig
make -j"$(nproc)"               # ~90 min on 20 cores the first time; a few minutes afterwards (ccache)
../scripts/make-release.sh v0.1.0 output/images/recalbox/recalbox-q6a.img.xz ../release   # split into release assets
```

Very new hosts (e.g. Ubuntu 26.04) need a few workarounds for the old Buildroot (GCC 14 for host tools, CMake 3.31 in
`PATH`, `CMAKE_POLICY_VERSION_MINIMUM=3.5`, `LC_ALL=C`, `TERM`, `dpkg-deb`, `rsync`, and `scripts/fetch_gitlab.py` for the
gitlab.com tarballs that return 403). They are listed in [docs/PLAN.md](docs/PLAN.md).

**Updating a running board without re-flashing:** copy `output/images/boot-data/boot/recalbox` to `/boot/boot/recalbox.new`
(remount `/boot` read-write), rename it over `recalbox` (keep the old one as `recalbox.old`) and reboot.

### Firmware and licences

The build downloads Radxa's firmware packages ([radxa-pkg](https://github.com/radxa-pkg): DSP firmware, AudioReach topology,
`alsa-ucm-conf`, AIC8800) and does not redistribute them in this repository. The `aic8800` driver is GPL-2.0.

### Credits

🤖 Part of this project was built pair-programming with [Claude Code](https://claude.com/claude-code).

### License

[MIT](LICENSE). Upstream Recalbox and the emulators keep their own licenses.

---

## Português

### O que funciona

| | Situação |
|---|---|
| Boot (UEFI + GRUB), EmulationStation | ✅ |
| Vídeo HDMI | ✅ (veja a nota de resolução abaixo) |
| Áudio: HDMI **e** conector de fone 3,5 mm | ✅ |
| Wi-Fi (AIC8800 onboard) | ✅ |
| Bluetooth: caixas/fones e controles | ✅ |
| Controles USB, teclado, mouse | ✅ |
| Ethernet Gigabit | ✅ |
| Emuladores testados | NES, **PS1** (`pcsx_rearmed`), **Dreamcast** (`flycast`) |
| Outros núcleos (N64, MAME 2015, ...) | compilam e carregam; desempenho ainda não medido |

### Limitações conhecidas

- **O vídeo é limitado a 4K@30 Hz** pela saída HDMI da placa ([especificações da Radxa](https://docs.radxa.com/en/dragon/q6a)). Numa
  TV ou monitor 4K/120 Hz, ajuste o modo de vídeo global para **1080p na maior taxa de atualização** que o seu display suporta
  (*Menu → Configurações do sistema → Vídeo*; por ex. 1080p120). Testado num monitor QHD 144 Hz e numa TV 4K 120 Hz a 1080p120.
- Alguns segundos de tela branca no boot, enquanto o firmware da GPU carrega. Só estético.
- Ainda não incluídos: Kodi, Vulkan (o Turnip não existe neste Buildroot) e alguns núcleos menores (`vircon32`, `flycast-next`).
- Energia: a placa pode ter queda de tensão sob carga pesada de NVMe + USB. Use uma boa fonte USB-C PD.

Veja o [docs/PLAN.md](docs/PLAN.md) para o registro completo, os becos sem saída e o roteiro (em inglês).

### Instalar uma imagem pronta

1. Vá em [Releases](../../releases) e baixe **todos** os arquivos `.part*` mais os dois `SHA256SUMS-*.txt`.
2. Rode o instalador interativo do seu sistema — ele confere os checksums, reconstrói a imagem e grava, pedindo pra você
   confirmar o dispositivo de destino antes de escrever qualquer coisa:

   ```bash
   ./install.sh       # Linux
   ./install_mac.sh   # macOS
   ```

   Ou na mão (Linux):

   ```bash
   sha256sum -c SHA256SUMS-parts.txt --ignore-missing
   cat recalbox-radxa-dragon-q6a_<versao>.img.xz.part* > imagem.img.xz
   sha256sum -c SHA256SUMS-full.txt --ignore-missing
   xzcat imagem.img.xz | sudo dd of=/dev/SEU_DISPOSITIVO bs=4M status=progress conv=fsync
   ```

   ⚠️ Confira o dispositivo de destino com `lsblk` antes: isso apaga o dispositivo inteiro.

3. Dê boot na placa por ele (menu de boot do UEFI, ou rEFInd). O **primeiro boot leva 1–2 minutos**: o Recalbox cria as partições
   `SHARE` (exFAT) e `OVERLAY` (ext4) no espaço livre do disco. Não desligue durante essa etapa.
4. O SSH vem ligado: usuário `root`, senha `recalboxroot` (troque no `recalbox.conf`).

### Instalar no NVMe interno junto com outros sistemas

Se o NVMe já tem outros sistemas (Ubuntu, Windows...), você **não** precisa apagar nada. Deixe ≥ 8 GiB livres no fim do disco,
crie ali uma partição de boot de 5 GiB e copie o conteúdo da imagem pra ela:

```bash
xzcat recalbox-radxa-dragon-q6a_<versao>.img.xz > recalbox.img
sudo sgdisk -n 5:0:+5GiB -t 5:EF00 -c 5:boot /dev/nvme0n1     # ajuste o número da partição
sudo mkfs.vfat -F 32 -n RECALBOX /dev/nvme0n1p5
sudo losetup -rfP --show recalbox.img                          # imprime /dev/loopN
sudo mount -o ro /dev/loopNp1 /mnt/img && sudo mount /dev/nvme0n1p5 /mnt/rb
sudo cp -r /mnt/img/. /mnt/rb/ && sync
```

Deixe o resto sem alocar: o primeiro boot cria o `SHARE` e o `OVERLAY` ali. O rEFInd / o firmware lista a nova entrada sozinho.
A partição de boot é encontrada pelo rótulo `RECALBOX`: desconecte antes qualquer outro disco com esse rótulo.

### Compilar você mesmo, a partir do código

Este repositório contém só a parte específica da Q6A; o Recalbox oficial é clonado sem modificações e a série em
[`patches/`](patches) é aplicada por cima.

```bash
./scripts/bootstrap.sh          # clona o upstream em ./recalbox e aplica patches/
cd recalbox
make recalbox-q6a_defconfig
make -j"$(nproc)"               # ~90 min em 20 núcleos na primeira vez; alguns minutos depois (ccache)
../scripts/make-release.sh v0.1.0 output/images/recalbox/recalbox-q6a.img.xz ../release   # gera os arquivos da release
```

Hosts muito novos (ex.: Ubuntu 26.04) precisam de alguns contornos para o Buildroot antigo (GCC 14 para as ferramentas do host,
CMake 3.31 no `PATH`, `CMAKE_POLICY_VERSION_MINIMUM=3.5`, `LC_ALL=C`, `TERM`, `dpkg-deb`, `rsync` e o `scripts/fetch_gitlab.py`
para os tarballs do gitlab.com que retornam 403). Estão listados no [docs/PLAN.md](docs/PLAN.md).

**Atualizar uma placa já rodando sem regravar:** copie `output/images/boot-data/boot/recalbox` para `/boot/boot/recalbox.new`
(remonte o `/boot` como leitura e escrita), renomeie por cima de `recalbox` (guarde o antigo como `recalbox.old`) e reinicie.

### Firmware e licenças

O build baixa os pacotes de firmware da Radxa ([radxa-pkg](https://github.com/radxa-pkg): firmware dos DSPs, topologia AudioReach,
`alsa-ucm-conf`, AIC8800) e não os redistribui neste repositório. O driver `aic8800` é GPL-2.0.

### Créditos

🤖 Parte deste projeto foi construída em pair-programming com o [Claude Code](https://claude.com/claude-code).

### Licença

[MIT](LICENSE). O Recalbox oficial e os emuladores mantêm suas próprias licenças.
