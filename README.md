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
| Emulators and PC ports included in the image | ✅ all opened and run on real hardware; **PS1** (`pcsx_rearmed`) and **Dreamcast** (`flycast`) tested in particular |

### Known limitations

- **The HDMI output is limited to 4K@30 Hz** by the hardware ([Radxa specs](https://docs.radxa.com/en/dragon/q6a)). A 4K TV
  that advertises 4K as its preferred mode used to make Recalbox pick it, halving the speed of 60 fps games (slow motion and
  wobbling audio). Since v0.1.1 the kernel **hides modes above 1440p, modes wider than 1080p above 60 Hz, and modes below 50 Hz**,
  and the default video mode is 1080p. See [Display modes](#display-modes-and-tuning) to change the limits.
- A few seconds of white screen at boot, while the GPU firmware loads. Cosmetic.
- Not included yet: Kodi, Vulkan (Turnip is not in this Buildroot), and a few minor cores (`vircon32`, `flycast-next`).
- Power: the board can brown out under heavy NVMe + USB load. Use a good USB-C PD supply.

See [docs/PLAN.md](docs/PLAN.md) for the full status log, the dead ends and the roadmap.

### Display modes and tuning

The kernel limits the modes the HDMI output exposes (so the board never ends up at 4K@30 by accident). The limits are kernel
parameters; to change them edit `grub.cfg` on the boot partition (the `RECALBOX` FAT partition, `boot/grub/grub.cfg`) and add them
to the `linux` line:

| Parameter | Default | Meaning |
|---|---|---|
| `msm.dp_max_width` / `msm.dp_max_height` | 2560 / 1440 | hide larger modes (0 = no limit) |
| `msm.dp_hires_max_refresh` | 60 | hide modes wider than 1920 above this refresh rate |
| `msm.dp_min_refresh` | 50 | hide modes of 1280 pixels or more below this refresh rate (24/25/30 Hz) |

Set `global.videomode` (and `system.es.videomode`) in `recalbox.conf`, or use *Menu → System settings → Video*. Other options in
`recalbox.conf` (commented out by default):

- `system.cpu.governor=performance` keeps the CPU at full speed: steadier frame times and less input jitter, a bit more power and heat.
- `global.runahead=1` and `global.reducelatency=1` lower input latency on 8/16-bit systems (NES, SNES, Mega Drive, Master System,
  Game Boy, Game Gear, FBNeo). If your TV has a game mode (ALLM / "Game Optimizer"), turn it on: it is the biggest single factor.
- Official Recalbox updates are **disabled** (`updates.enabled=0`): they would install an image that does not run on this board.
  Update by flashing a new release, or by replacing `boot/linux`, `boot/initrd.gz` and `boot/recalbox` on the boot partition.

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
| Emuladores e ports de PC incluídos na imagem | ✅ todos abertos e executados no hardware real; **PS1** (`pcsx_rearmed`) e **Dreamcast** (`flycast`) testados com atenção especial |

### Limitações conhecidas

- **A saída HDMI é limitada a 4K@30 Hz** pelo hardware ([especificações da Radxa](https://docs.radxa.com/en/dragon/q6a)). Uma TV 4K
  que anuncia o 4K como modo preferido fazia o Recalbox escolhê-lo, deixando os jogos de 60 fps na metade da velocidade (câmera
  lenta e áudio oscilando). Desde a v0.1.1 o kernel **esconde modos acima de 1440p, modos mais largos que 1080p acima de 60 Hz e
  modos abaixo de 50 Hz**, e o modo de vídeo padrão é 1080p. Veja [Modos de vídeo](#modos-de-vídeo-e-ajustes) para mudar os limites.
- Alguns segundos de tela branca no boot, enquanto o firmware da GPU carrega. Só estético.
- Ainda não incluídos: Kodi, Vulkan (o Turnip não existe neste Buildroot) e alguns núcleos menores (`vircon32`, `flycast-next`).
- Energia: a placa pode ter queda de tensão sob carga pesada de NVMe + USB. Use uma boa fonte USB-C PD.

Veja o [docs/PLAN.md](docs/PLAN.md) para o registro completo, os becos sem saída e o roteiro (em inglês).

### Modos de vídeo e ajustes

O kernel limita os modos que a saída HDMI expõe (assim a placa nunca cai no 4K@30 por acidente). Os limites são parâmetros do
kernel; para mudá-los, edite o `grub.cfg` da partição de boot (a partição FAT `RECALBOX`, `boot/grub/grub.cfg`) e acrescente à
linha `linux`:

| Parâmetro | Padrão | Significado |
|---|---|---|
| `msm.dp_max_width` / `msm.dp_max_height` | 2560 / 1440 | esconde modos maiores (0 = sem limite) |
| `msm.dp_hires_max_refresh` | 60 | esconde modos mais largos que 1920 acima dessa taxa de atualização |
| `msm.dp_min_refresh` | 50 | esconde modos de 1280 pixels ou mais abaixo dessa taxa (24/25/30 Hz) |

Defina `global.videomode` (e `system.es.videomode`) no `recalbox.conf`, ou use *Menu → Configurações do sistema → Vídeo*. Outras
opções do `recalbox.conf` (comentadas por padrão):

- `system.cpu.governor=performance` mantém a CPU em velocidade máxima: tempos de quadro mais estáveis e menos variação na entrada, com um pouco mais de consumo e calor.
- `global.runahead=1` e `global.reducelatency=1` reduzem a latência de entrada em sistemas de 8/16 bits (NES, SNES, Mega Drive,
  Master System, Game Boy, Game Gear, FBNeo). Se a sua TV tem modo jogo (ALLM / "Game Optimizer"), ligue: é o fator mais importante.
- As atualizações oficiais do Recalbox ficam **desligadas** (`updates.enabled=0`): instalariam uma imagem que não roda nesta placa.
  Atualize gravando uma nova release, ou trocando `boot/linux`, `boot/initrd.gz` e `boot/recalbox` na partição de boot.

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
