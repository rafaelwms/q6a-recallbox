## Recalbox for the Radxa Dragon Q6A — v0.1.0 (Linux 7.2.9)

First public release of the [Recalbox](https://gitlab.com/recalbox/recalbox) port for the [Radxa Dragon Q6A](https://radxa.com/products/dragon/q6a/) (Qualcomm QCS6490). Boots straight into EmulationStation from a USB 3.0/SATA SSD or from the internal NVMe, with **video, audio (HDMI and headphone jack), Wi-Fi and Bluetooth working** on a mainline Linux 7.2.9 kernel.

Built from upstream Recalbox `master` (commit `27224c1`) plus the patch series in [`patches/`](../../blob/main/patches). Hardware recipe shared with the sibling [Ubuntu project](https://github.com/rafaelwms/ubuntu-26.04.1-dragon-q6a). Full story and status: [README](../../blob/main/README.md) and [docs/PLAN.md](../../blob/main/docs/PLAN.md).

### What's in this release

| | Status |
|---|---|
| Kernel | 7.2.9 (mainline, config derived from the Q6A Ubuntu image) |
| Boot | UEFI + GRUB (arm64), USB 3.0/SATA SSD or internal NVMe |
| HDMI video | ✅ (limited to 4K@30 Hz by the hardware, see below) |
| Audio | ✅ HDMI and 3.5 mm headphone jack |
| Wi-Fi + Bluetooth | ✅ onboard AIC8800 (audio devices and gamepads) |
| GPU | Mesa Freedreno (OpenGL ES) |
| Emulators confirmed on hardware | NES, **PS1** (`pcsx_rearmed`), **Dreamcast** (`flycast`) |
| Other cores | N64, MAME 2015, etc. build and load; performance not benchmarked yet |

Default SSH login: user `root`, password `recalboxroot` — **change it** in `recalbox.conf`. The `SHARE` and `OVERLAY` partitions are created on the first boot, in the free space of the disk.

### Known limitations

- **Video is limited to 4K@30 Hz** by the board's HDMI output. On a 4K/120 Hz TV or monitor set the global video mode to **1080p at the highest refresh rate** (*Menu → System settings → Video*; e.g. 1080p120).
- A few seconds of white screen at boot while the GPU firmware loads (cosmetic).
- Not included yet: Kodi, Vulkan (Turnip), and a few minor cores (`vircon32`, `flycast-next`).
- The board can brown out under heavy NVMe + USB load: use a good USB-C PD power supply.
- The first boot takes 1–2 minutes (partition creation): do not power off.

### How to install

The image is split into parts (≤ 1.4 GB each) to fit GitHub's release asset limits — download **all parts** plus both `SHA256SUMS-*.txt` files, then either:

**Use the interactive installer for your OS** (recommended — verifies checksums, reassembles, and flashes for you, asking you to confirm the target device first):
```bash
git clone https://github.com/rafaelwms/q6a-recallbox.git
cd q6a-recallbox
./install.sh       # Linux
./install_mac.sh   # macOS
```

**Or do it by hand (Linux):**
```bash
sha256sum -c SHA256SUMS-parts.txt --ignore-missing
cat recalbox-radxa-dragon-q6a_v0.1.0.img.xz.part* > image.img.xz
sha256sum -c SHA256SUMS-full.txt --ignore-missing
xzcat image.img.xz | sudo dd of=/dev/YOUR_DEVICE bs=4M status=progress conv=fsync
```

⚠️ Triple-check the target device with `lsblk` first — this erases it completely.

**Already have other systems on the NVMe?** Don't erase it: add a 5 GiB boot partition in the free space at the end of the disk and copy the image's contents into it — see [the README](../../blob/main/README.md#install-on-the-internal-nvme-next-to-other-systems).

### Checksums (SHA-256)

```
2bab001cc1871936e9e4bf7d40c527809dc272299244b564d39ec58ebb1aadc7  recalbox-radxa-dragon-q6a_v0.1.0.img.xz.part00
643beebf01db8ac4e359d3ff2392e825dbaff08ef51dd4204ed30db3fdb4a6a5  recalbox-radxa-dragon-q6a_v0.1.0.img.xz.part01
3b09681ed433a2031b8e1d5f3b9786618deaca946b1a89a813b98ceacb519d0e  recalbox-radxa-dragon-q6a_v0.1.0.img.xz   (after joining the parts)
```

---

## Recalbox para a Radxa Dragon Q6A — v0.1.0 (Linux 7.2.9)

Primeira release pública do port do [Recalbox](https://gitlab.com/recalbox/recalbox) para a [Radxa Dragon Q6A](https://radxa.com/products/dragon/q6a/) (Qualcomm QCS6490). Dá boot direto no EmulationStation a partir de um SSD USB 3.0/SATA ou do NVMe interno, com **vídeo, áudio (HDMI e conector de fone), Wi-Fi e Bluetooth funcionando** num kernel Linux 7.2.9 mainline.

Construída a partir do Recalbox oficial `master` (commit `27224c1`) mais a série de patches em [`patches/`](../../blob/main/patches). A receita de hardware é compartilhada com o [projeto Ubuntu](https://github.com/rafaelwms/ubuntu-26.04.1-dragon-q6a) irmão. História completa e situação: [README](../../blob/main/README.md) e [docs/PLAN.md](../../blob/main/docs/PLAN.md) (em inglês).

### O que tem nesta release

| | Situação |
|---|---|
| Kernel | 7.2.9 (mainline, config derivada da imagem Ubuntu da Q6A) |
| Boot | UEFI + GRUB (arm64), SSD USB 3.0/SATA ou NVMe interno |
| Vídeo HDMI | ✅ (limitado a 4K@30 Hz pelo hardware, veja abaixo) |
| Áudio | ✅ HDMI e conector de fone 3,5 mm |
| Wi-Fi + Bluetooth | ✅ AIC8800 onboard (dispositivos de áudio e controles) |
| GPU | Mesa Freedreno (OpenGL ES) |
| Emuladores confirmados no hardware | NES, **PS1** (`pcsx_rearmed`), **Dreamcast** (`flycast`) |
| Outros núcleos | N64, MAME 2015 etc. compilam e carregam; desempenho ainda não medido |

Login SSH padrão: usuário `root`, senha `recalboxroot` — **troque** no `recalbox.conf`. As partições `SHARE` e `OVERLAY` são criadas no primeiro boot, no espaço livre do disco.

### Limitações conhecidas

- **O vídeo é limitado a 4K@30 Hz** pela saída HDMI da placa. Numa TV ou monitor 4K/120 Hz ajuste o modo de vídeo global para **1080p na maior taxa de atualização** (*Menu → Configurações do sistema → Vídeo*; por ex. 1080p120).
- Alguns segundos de tela branca no boot enquanto o firmware da GPU carrega (estético).
- Ainda não incluídos: Kodi, Vulkan (Turnip) e alguns núcleos menores (`vircon32`, `flycast-next`).
- A placa pode ter queda de tensão sob carga pesada de NVMe + USB: use uma boa fonte USB-C PD.
- O primeiro boot leva 1–2 minutos (criação das partições): não desligue.

### Como instalar

A imagem é dividida em partes (≤ 1,4 GB cada) pra caber no limite de tamanho de asset do GitHub — baixe **todas as partes** mais os dois arquivos `SHA256SUMS-*.txt`, e então:

**Use o instalador interativo do seu sistema** (recomendado — confere os checksums, reconstrói a imagem e grava, pedindo pra você confirmar o dispositivo de destino antes):
```bash
git clone https://github.com/rafaelwms/q6a-recallbox.git
cd q6a-recallbox
./install.sh       # Linux
./install_mac.sh   # macOS
```

**Ou na mão (Linux):**
```bash
sha256sum -c SHA256SUMS-parts.txt --ignore-missing
cat recalbox-radxa-dragon-q6a_v0.1.0.img.xz.part* > imagem.img.xz
sha256sum -c SHA256SUMS-full.txt --ignore-missing
xzcat imagem.img.xz | sudo dd of=/dev/SEU_DISPOSITIVO bs=4M status=progress conv=fsync
```

⚠️ Confira bem o dispositivo de destino com `lsblk` antes — isso apaga tudo nele.

**Já tem outros sistemas no NVMe?** Não apague: crie uma partição de boot de 5 GiB no espaço livre do fim do disco e copie o conteúdo da imagem pra ela — veja [o README](../../blob/main/README.md#instalar-no-nvme-interno-junto-com-outros-sistemas).

### Checksums (SHA-256)

Os mesmos da seção em inglês acima.
