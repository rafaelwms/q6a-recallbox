## Recalbox for the Radxa Dragon Q6A — v0.1.1 (Linux 7.2.9)

Second release of the [Recalbox](https://gitlab.com/recalbox/recalbox) port for the [Radxa Dragon Q6A](https://radxa.com/products/dragon/q6a/) (Qualcomm QCS6490). Boots straight into EmulationStation from a USB 3.0/SATA SSD or from the internal NVMe, with **video, audio (HDMI and headphone jack), Wi-Fi and Bluetooth working** on a mainline Linux 7.2.9 kernel. **Every emulator and PC port included in the image was opened and run on real hardware**; PS1 (`pcsx_rearmed`) and Dreamcast (`flycast`) were tested in particular.

Built from upstream Recalbox `master` (commit `27224c1`) plus the patch series in [`patches/`](../../blob/main/patches). Full story and status: [README](../../blob/main/README.md) and [docs/PLAN.md](../../blob/main/docs/PLAN.md).

### What's new in v0.1.1

- **No more slow-motion games on 4K TVs.** A 4K TV advertises 4K as its preferred mode, and the board can only send 4K@30 Hz, so 60 fps games (NES, SNES, Mega Drive, MAME) ran at half speed with wobbling audio. The kernel now **hides modes above 1440p, modes wider than 1080p above 60 Hz and modes below 50 Hz**, and the default video mode is **1080p**. The limits are kernel parameters (`msm.dp_max_width`, `msm.dp_max_height`, `msm.dp_hires_max_refresh`, `msm.dp_min_refresh`), see the README.
- **System settings show the real data:** VERSION is `0.1.1` (it used to say `development`) and BOARD is **Radxa Dragon Q6A 64bits** (it used to say `unknown`). EmulationStation now shows the device tree model of boards it does not know.
- **Master volume works out of the box:** the default audio device used to be a Raspberry Pi one that does not exist on this board; it now points to the board's HDMI output.
- **Official Recalbox updates are disabled by default:** they would install an image that does not run on this board. Update with a new release (see below).
- New optional settings in `recalbox.conf` (commented out): `system.cpu.governor=performance`, `global.runahead=1` and `global.reducelatency=1` for lower input latency. Turn on your TV's game mode (ALLM) too.

### What's in this release

| | Status |
|---|---|
| Kernel | 7.2.9 (mainline, config derived from the Q6A Ubuntu image) |
| Boot | UEFI + GRUB (arm64), USB 3.0/SATA SSD or internal NVMe |
| HDMI video | ✅ up to 1440p60 / 1080p120+ (4K@30 is hidden, see above) |
| Audio | ✅ HDMI and 3.5 mm headphone jack |
| Wi-Fi + Bluetooth | ✅ onboard AIC8800 (audio devices and gamepads) |
| GPU | Mesa Freedreno (OpenGL ES) |
| Emulators and PC ports | ✅ all opened and run on real hardware by the maintainer; **PS1** and **Dreamcast** tested in particular |

Default SSH login: user `root`, password `recalboxroot` — **change it** in `recalbox.conf`. The `SHARE` and `OVERLAY` partitions are created on the first boot, in the free space of the disk.

### Known limitations

- The HDMI hardware tops out at 4K@30 Hz: that is why those modes are hidden.
- A few seconds of white screen at boot while the GPU firmware loads (cosmetic).
- Not included yet: Kodi, Vulkan (Turnip), and a few minor cores (`vircon32`, `flycast-next`).
- Some games can hang the EmulationStation list view (still being investigated).
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
cat recalbox-radxa-dragon-q6a_v0.1.1.img.xz.part* > image.img.xz
sha256sum -c SHA256SUMS-full.txt --ignore-missing
xzcat image.img.xz | sudo dd of=/dev/YOUR_DEVICE bs=4M status=progress conv=fsync
```

⚠️ Triple-check the target device with `lsblk` first — this erases it completely.

**Already have other systems on the NVMe?** Don't erase it: add a 5 GiB boot partition in the free space at the end of the disk and copy the image's contents into it — see [the README](../../blob/main/README.md#install-on-the-internal-nvme-next-to-other-systems).

### Upgrading from v0.1.0 without re-flashing

Your `SHARE` (ROMs, saves, settings) is not touched. Replace the three boot files on the `RECALBOX` partition with the ones from the new image (kernel `linux`, `initrd.gz` and the root filesystem `recalbox`), keeping the old ones as `.old`, then reboot. Existing installs keep their own `recalbox.conf`, so also set `global.videomode=1920x1080`, `system.es.videomode=1920x1080`, `audio.device=alsa_card.0:[Out] HDMI:HiFi` and `updates.enabled=0` yourself (or use the menus). Re-flashing is simpler if you have nothing to preserve.

### Checksums (SHA-256)

```
64641a227974be62b7a308aa87cedc8dfef1e2030ca34f9dd7d625fea8e74dc2  recalbox-radxa-dragon-q6a_v0.1.1.img.xz.part00
2053e6759bb6671cd18116a8a6e5082386f826fe5eca52d339bba1ade33a85de  recalbox-radxa-dragon-q6a_v0.1.1.img.xz.part01
876986653d4a0e1f1013c37c2f5158c8ffe4c47e10491c58ba3ed637decd8ba5  recalbox-radxa-dragon-q6a_v0.1.1.img.xz   (after joining the parts)
```

---

## Recalbox para a Radxa Dragon Q6A — v0.1.1 (Linux 7.2.9)

Segunda release do port do [Recalbox](https://gitlab.com/recalbox/recalbox) para a [Radxa Dragon Q6A](https://radxa.com/products/dragon/q6a/) (Qualcomm QCS6490). Dá boot direto no EmulationStation a partir de um SSD USB 3.0/SATA ou do NVMe interno, com **vídeo, áudio (HDMI e conector de fone), Wi-Fi e Bluetooth funcionando** num kernel Linux 7.2.9 mainline. **Todos os emuladores e ports de PC incluídos na imagem foram abertos e executados no hardware real**; PS1 (`pcsx_rearmed`) e Dreamcast (`flycast`) foram testados com atenção especial.

Construída a partir do Recalbox oficial `master` (commit `27224c1`) mais a série de patches em [`patches/`](../../blob/main/patches). História completa e situação: [README](../../blob/main/README.md) e [docs/PLAN.md](../../blob/main/docs/PLAN.md) (em inglês).

### O que mudou na v0.1.1

- **Acabou o jogo em câmera lenta em TV 4K.** Uma TV 4K anuncia o 4K como modo preferido, e a placa só consegue enviar 4K@30 Hz, então jogos de 60 fps (NES, SNES, Mega Drive, MAME) rodavam na metade da velocidade e com o áudio oscilando. O kernel agora **esconde modos acima de 1440p, modos mais largos que 1080p acima de 60 Hz e modos abaixo de 50 Hz**, e o modo de vídeo padrão é **1080p**. Os limites são parâmetros do kernel (`msm.dp_max_width`, `msm.dp_max_height`, `msm.dp_hires_max_refresh`, `msm.dp_min_refresh`), veja o README.
- **As configurações do sistema mostram os dados reais:** VERSION é `0.1.1` (antes dizia `development`) e BOARD é **Radxa Dragon Q6A 64bits** (antes dizia `unknown`). O EmulationStation agora mostra o modelo do device tree de placas que ele não conhece.
- **O volume master funciona de fábrica:** o dispositivo de áudio padrão era o de um Raspberry Pi, que não existe nesta placa; agora aponta para a saída HDMI da placa.
- **As atualizações oficiais do Recalbox vêm desligadas:** instalariam uma imagem que não roda nesta placa. Atualize por uma nova release (veja abaixo).
- Novas opções no `recalbox.conf` (comentadas): `system.cpu.governor=performance`, `global.runahead=1` e `global.reducelatency=1`, para menor latência de entrada. Ligue também o modo jogo (ALLM) da sua TV.

### O que tem nesta release

| | Situação |
|---|---|
| Kernel | 7.2.9 (mainline, config derivada da imagem Ubuntu da Q6A) |
| Boot | UEFI + GRUB (arm64), SSD USB 3.0/SATA ou NVMe interno |
| Vídeo HDMI | ✅ até 1440p60 / 1080p120+ (o 4K@30 fica escondido, veja acima) |
| Áudio | ✅ HDMI e conector de fone 3,5 mm |
| Wi-Fi + Bluetooth | ✅ AIC8800 onboard (dispositivos de áudio e controles) |
| GPU | Mesa Freedreno (OpenGL ES) |
| Emuladores e ports de PC | ✅ todos abertos e executados no hardware real pelo mantenedor; **PS1** e **Dreamcast** testados com atenção especial |

Login SSH padrão: usuário `root`, senha `recalboxroot` — **troque** no `recalbox.conf`. As partições `SHARE` e `OVERLAY` são criadas no primeiro boot, no espaço livre do disco.

### Limitações conhecidas

- O hardware HDMI chega no máximo a 4K@30 Hz: por isso esses modos ficam escondidos.
- Alguns segundos de tela branca no boot enquanto o firmware da GPU carrega (estético).
- Ainda não incluídos: Kodi, Vulkan (Turnip) e alguns núcleos menores (`vircon32`, `flycast-next`).
- Alguns jogos podem travar a lista do EmulationStation (ainda em investigação).
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
cat recalbox-radxa-dragon-q6a_v0.1.1.img.xz.part* > imagem.img.xz
sha256sum -c SHA256SUMS-full.txt --ignore-missing
xzcat imagem.img.xz | sudo dd of=/dev/SEU_DISPOSITIVO bs=4M status=progress conv=fsync
```

⚠️ Confira bem o dispositivo de destino com `lsblk` antes — isso apaga tudo nele.

**Já tem outros sistemas no NVMe?** Não apague: crie uma partição de boot de 5 GiB no espaço livre do fim do disco e copie o conteúdo da imagem pra ela — veja [o README](../../blob/main/README.md#instalar-no-nvme-interno-junto-com-outros-sistemas).

### Atualizando da v0.1.0 sem regravar

O seu `SHARE` (ROMs, saves, configurações) não é tocado. Troque os três arquivos de boot da partição `RECALBOX` pelos da nova imagem (o kernel `linux`, o `initrd.gz` e o sistema de arquivos raiz `recalbox`), guardando os antigos como `.old`, e reinicie. Instalações existentes mantêm o seu próprio `recalbox.conf`, então ajuste você mesmo `global.videomode=1920x1080`, `system.es.videomode=1920x1080`, `audio.device=alsa_card.0:[Out] HDMI:HiFi` e `updates.enabled=0` (ou use os menus). Regravar é mais simples se você não tem nada a preservar.

### Checksums (SHA-256)

Os mesmos da seção em inglês acima.
