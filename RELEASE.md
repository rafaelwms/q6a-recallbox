## Recalbox for the Radxa Dragon Q6A — v0.1.2 (Linux 7.2.9) — pre-release

> **Unofficial community port, pre-release.** Not affiliated with or supported by the Recalbox team, Radxa or Qualcomm. **Non-commercial use only**
> (see [NOTICE.md](../../blob/main/NOTICE.md) and [LICENSE-RECALBOX.md](../../blob/main/LICENSE-RECALBOX.md)). We need the community's help to test it: please open an issue with what you find.

Third release of the [Recalbox](https://gitlab.com/recalbox/recalbox) port for the [Radxa Dragon Q6A](https://radxa.com/products/dragon/q6a/) (Qualcomm QCS6490). Boots straight into EmulationStation from a USB 3.0/SATA SSD or from the internal NVMe, with **video, audio (HDMI and headphone jack), Wi-Fi and Bluetooth working** on a mainline Linux 7.2.9 kernel. The previous release (v0.1.1) ran for more than 24 hours on real hardware, including long gaming sessions, without a freeze; this one adds the fixes below and was verified on a booted board (version, video mode, watcher and diagnostics active).

Built from upstream Recalbox `master` at commit `27224c1` plus the patch series in [`patches/`](../../blob/main/patches). Anyone can rebuild it with `./scripts/build-all.sh v0.1.2`. Full story and status: [README](../../blob/main/README.md) and [docs/PLAN.md](../../blob/main/docs/PLAN.md).

![System Settings showing VERSION 0.1.2 and BOARD Radxa Dragon Q6A 64bits](https://raw.githubusercontent.com/rafaelwms/q6a-recallbox/main/docs/img/q6a-system-settings.png)

![EmulationStation, Favorites system, running on the Dragon Q6A](https://raw.githubusercontent.com/rafaelwms/q6a-recallbox/main/docs/img/q6a-favorites.png)

### What's new in v0.1.2

- **No more games frozen on their first frame.** The DSP sometimes fails to start the HDMI audio port, and the game blocks forever waiting for audio. A small watcher now restarts the port within seconds (`q6a.audiofix=0` in `recalbox.conf` turns it off).
- **1080p60 from the very first frame** (`video=HDMI-A-1:1920x1080@60` on the kernel command line). It also avoids the cut-off interface seen after leaving some games when the TV was negotiated at a different mode.
- **Fixed two EmulationStation bugs:** the *Output Device* list showed every output twice (and selecting a duplicate could crash the frontend), and sliding the master volume quickly could restart it.
- **Built-in diagnostics for bug reports:** a kernel log + heartbeat in `/recalbox/share/system/logs/q6a-kernel.log` (≤ 50 MB per boot; `q6a.diaglog=0` turns it off).
- Windows installer (`install.ps1`) next to the Linux and macOS ones, and a one-command reproducible build (`scripts/build-all.sh`) with the licence manifest (`q6a-legal-info_v0.1.2.tar.gz`).
- SSH key login is supported (`/recalbox/share/system/.ssh/authorized_keys`).

### What's in this release

| | Status |
|---|---|
| Kernel | 7.2.9 (mainline, config derived from the Q6A Ubuntu image) |
| Boot | UEFI + GRUB (arm64), USB 3.0/SATA SSD or internal NVMe |
| HDMI video | ✅ up to 1440p60 / 1080p120+ (4K@30 is hidden), 1080p60 by default |
| Audio | ✅ HDMI and 3.5 mm headphone jack |
| Wi-Fi + Bluetooth | ✅ onboard AIC8800 (audio devices and gamepads) |
| GPU | Mesa Freedreno (OpenGL ES) |
| Emulators and PC ports | ✅ all opened and run on real hardware by the maintainer; **PS1** and **Dreamcast** tested in particular |
| Install media | ✅ USB 3.0/SATA SSD and NVMe tested; ⚠️ microSD and USB sticks not tested |

Default SSH login: user `root`, password `recalboxroot` — **change it**. The `SHARE` and `OVERLAY` partitions are created on the first boot, in the free space of the disk.

### Known limitations

- The HDMI hardware tops out at 4K@30 Hz: that is why those modes are hidden.
- The root cause of the DSP audio port failure and of the occasional HDMI EDID read failure is still open; the image works around both (audio watcher, 1080p60 forced) instead of fixing the driver.
- A few seconds of white screen at boot while the GPU firmware loads (cosmetic).
- Not included yet: Kodi, Vulkan (Turnip), and a few minor cores (`vircon32`, `flycast-next`).
- The board can brown out under heavy NVMe + USB load: use a good USB-C PD power supply.
- The first boot takes 1–2 minutes (partition creation): do not power off.
- Official Recalbox updates are disabled (they would install an image that does not run here): update with a new release.
- The Windows installer has not yet been run on real Windows hardware; the manual steps in the README always work.

### How to install

**Storage:** USB 3.0/SATA SSD or NVMe in a USB case (tested), microSD or USB stick (not tested), **16 GB or more** (32 GB+ recommended). The installer **erases the target completely**.

The image is split into parts (≤ 1.4 GB each) to fit GitHub's release asset limits — download **all parts** plus both `SHA256SUMS-*.txt` files (or let the installer download them), then use the interactive installer for your OS (it verifies the checksums, reassembles the image and flashes it, asking you to confirm the exact target device first). English and pt-BR are both offered:

```bash
git clone https://github.com/rafaelwms/q6a-recallbox.git && cd q6a-recallbox
./install.sh       # Linux   (needs curl, xz, sudo)
./install_mac.sh   # macOS   (needs curl, xz)
```
```powershell
# Windows 10/11, PowerShell as Administrator (needs 7-Zip: winget install 7zip.7zip)
Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1
```

**Or by hand (Linux):**
```bash
sha256sum -c SHA256SUMS-parts.txt --ignore-missing
cat recalbox-radxa-dragon-q6a_v0.1.2.img.xz.part* > image.img.xz
sha256sum -c SHA256SUMS-full.txt --ignore-missing
xzcat image.img.xz | sudo dd of=/dev/YOUR_DEVICE bs=4M status=progress conv=fsync
```

macOS and Windows manual steps, and the guide to install on the internal NVMe **next to other systems**, are in [the README](../../blob/main/README.md#install-a-pre-built-image). ⚠️ Triple-check the target device first — this erases it completely.

### Upgrading from v0.1.0 / v0.1.1 without re-flashing

Your `SHARE` (ROMs, saves, settings) is not touched. On the board, remount `/boot` read-write (`mount -o remount,rw /boot`); it only has room for **two** system files, so remove the oldest `recalbox.old` first. Copy the new `linux`, `initrd.gz` and `recalbox` from the image's first partition (`/boot/boot/`) next to the old ones, keeping the old ones as `.old`, check the `md5sum`, and reboot. Existing installs keep their own `recalbox.conf`, so also set `global.videomode=1920x1080`, `system.es.videomode=1920x1080`, `audio.device=alsa_card.0:[Out] HDMI:HiFi` and `updates.enabled=0` yourself, **delete** `/recalbox/share/system/custom.sh` if you installed the old watcher (the image now has its own), and add `video=HDMI-A-1:1920x1080@60` to the kernel line in `/boot/grub/grub.cfg`. Re-flashing is simpler if you have nothing to preserve.

### Checksums (SHA-256)

```
b214692df2671fc1ba9f9722fa728ced267db1823887f32cf0205a54dc29aea1  recalbox-radxa-dragon-q6a_v0.1.2.img.xz.part00
ab71a58b95f672f8ad55ef3dd51608a5664d090889b0085ba7b82f8e5b3b9512  recalbox-radxa-dragon-q6a_v0.1.2.img.xz.part01
5963cb1d90868259ff7ba2490339574f2c9351d8cd836610f9bd4a25c2fa6473  q6a-legal-info_v0.1.2.tar.gz
8c35d9717f20f246517ab894131c10ab6b52cbba0f94a8ea9fd4c38d3c070bb0  recalbox-radxa-dragon-q6a_v0.1.2.img.xz   (after joining the parts)
```

---

## Recalbox para a Radxa Dragon Q6A — v0.1.2 (Linux 7.2.9) — pré-release

> **Port não oficial da comunidade, pré-release.** Sem vínculo ou suporte da equipe do Recalbox, da Radxa ou da Qualcomm. **Somente uso não comercial**
> (veja o [NOTICE.md](../../blob/main/NOTICE.md) e o [LICENSE-RECALBOX.md](../../blob/main/LICENSE-RECALBOX.md)). Precisamos da ajuda da comunidade para testar: abra uma issue com o que encontrar.

Terceira release do port do [Recalbox](https://gitlab.com/recalbox/recalbox) para a [Radxa Dragon Q6A](https://radxa.com/products/dragon/q6a/) (Qualcomm QCS6490). Dá boot direto no EmulationStation a partir de um SSD USB 3.0/SATA ou do NVMe interno, com **vídeo, áudio (HDMI e conector de fone), Wi-Fi e Bluetooth funcionando** num kernel Linux 7.2.9 mainline. A release anterior (v0.1.1) rodou por mais de 24 horas no hardware real, com longas sessões de jogo, sem nenhum travamento; esta traz as correções abaixo e foi verificada numa placa já iniciada (versão, modo de vídeo, vigia e diagnóstico ativos).

Construída a partir do Recalbox oficial `master` no commit `27224c1` mais a série de patches em [`patches/`](../../blob/main/patches). Qualquer pessoa pode recompilar com `./scripts/build-all.sh v0.1.2`. História completa e situação: [README](../../blob/main/README.md) e [docs/PLAN.md](../../blob/main/docs/PLAN.md) (em inglês).

![Configurações do sistema mostrando VERSION 0.1.2 e BOARD Radxa Dragon Q6A 64bits](https://raw.githubusercontent.com/rafaelwms/q6a-recallbox/main/docs/img/q6a-system-settings.png)

![EmulationStation, sistema Favoritos, rodando na Dragon Q6A](https://raw.githubusercontent.com/rafaelwms/q6a-recallbox/main/docs/img/q6a-favorites.png)

### O que mudou na v0.1.2

- **Acabaram os jogos congelados no primeiro quadro.** O DSP às vezes não consegue iniciar a porta de áudio HDMI, e o jogo fica bloqueado esperando o áudio. Agora um pequeno vigia reinicia a porta em segundos (`q6a.audiofix=0` no `recalbox.conf` desliga).
- **1080p60 desde o primeiro quadro** (`video=HDMI-A-1:1920x1080@60` na linha de comando do kernel). Isso também evita a interface cortada vista ao sair de alguns jogos quando a TV negociava outro modo.
- **Corrigidos dois bugs do EmulationStation:** a lista *Output Device* mostrava cada saída duas vezes (e escolher uma repetida podia derrubar o frontend), e deslizar o volume master rápido podia reiniciá-lo.
- **Diagnóstico embutido para relatos de bug:** log do kernel + pulsação em `/recalbox/share/system/logs/q6a-kernel.log` (≤ 50 MB por boot; `q6a.diaglog=0` desliga).
- Instalador para Windows (`install.ps1`) ao lado dos de Linux e macOS, e build reprodutível com um comando (`scripts/build-all.sh`) com o manifesto de licenças (`q6a-legal-info_v0.1.2.tar.gz`).
- Login por chave SSH suportado (`/recalbox/share/system/.ssh/authorized_keys`).

### O que tem nesta release

| | Situação |
|---|---|
| Kernel | 7.2.9 (mainline, config derivada da imagem Ubuntu da Q6A) |
| Boot | UEFI + GRUB (arm64), SSD USB 3.0/SATA ou NVMe interno |
| Vídeo HDMI | ✅ até 1440p60 / 1080p120+ (4K@30 fica escondido), 1080p60 por padrão |
| Áudio | ✅ HDMI e conector de fone 3,5 mm |
| Wi-Fi + Bluetooth | ✅ AIC8800 onboard (dispositivos de áudio e controles) |
| GPU | Mesa Freedreno (OpenGL ES) |
| Emuladores e ports de PC | ✅ todos abertos e executados no hardware real pelo mantenedor; **PS1** e **Dreamcast** testados com atenção especial |
| Mídias de instalação | ✅ SSD USB 3.0/SATA e NVMe testados; ⚠️ microSD e pendrives não testados |

Login SSH padrão: usuário `root`, senha `recalboxroot` — **troque**. As partições `SHARE` e `OVERLAY` são criadas no primeiro boot, no espaço livre do disco.

### Limitações conhecidas

- O hardware HDMI chega no máximo a 4K@30 Hz: por isso esses modos ficam escondidos.
- A causa raiz da falha da porta de áudio do DSP e da falha ocasional de leitura do EDID do HDMI continua em aberto; a imagem contorna as duas (vigia de áudio, 1080p60 forçado) em vez de corrigir o driver.
- Alguns segundos de tela branca no boot enquanto o firmware da GPU carrega (estético).
- Ainda não incluídos: Kodi, Vulkan (Turnip) e alguns núcleos menores (`vircon32`, `flycast-next`).
- A placa pode ter queda de tensão sob carga pesada de NVMe + USB: use uma boa fonte USB-C PD.
- O primeiro boot leva 1–2 minutos (criação das partições): não desligue.
- As atualizações oficiais do Recalbox vêm desligadas (instalariam uma imagem que não roda aqui): atualize por uma nova release.
- O instalador do Windows ainda não foi executado num Windows real; os passos manuais do README sempre funcionam.

### Como instalar

**Armazenamento:** SSD USB 3.0/SATA ou NVMe em case USB (testados), microSD ou pendrive (não testados), com **16 GB ou mais** (recomendado 32 GB+). O instalador **apaga totalmente o destino**.

A imagem é dividida em partes (≤ 1,4 GB cada) pra caber no limite de tamanho de asset do GitHub — baixe **todas as partes** mais os dois `SHA256SUMS-*.txt` (ou deixe o instalador baixar) e use o instalador interativo do seu sistema (ele confere os checksums, reconstrói a imagem e grava, pedindo que você confirme o dispositivo de destino antes). Inglês e pt-BR são oferecidos:

```bash
git clone https://github.com/rafaelwms/q6a-recallbox.git && cd q6a-recallbox
./install.sh       # Linux   (precisa de curl, xz, sudo)
./install_mac.sh   # macOS   (precisa de curl, xz)
```
```powershell
# Windows 10/11, PowerShell como Administrador (precisa do 7-Zip: winget install 7zip.7zip)
Set-ExecutionPolicy -Scope Process Bypass -Force; .\install.ps1
```

**Ou na mão (Linux):**
```bash
sha256sum -c SHA256SUMS-parts.txt --ignore-missing
cat recalbox-radxa-dragon-q6a_v0.1.2.img.xz.part* > imagem.img.xz
sha256sum -c SHA256SUMS-full.txt --ignore-missing
xzcat imagem.img.xz | sudo dd of=/dev/SEU_DISPOSITIVO bs=4M status=progress conv=fsync
```

Os passos manuais de macOS e Windows, e o guia para instalar no NVMe interno **junto com outros sistemas**, estão no [README](../../blob/main/README.md#instalar-uma-imagem-pronta). ⚠️ Confira bem o dispositivo de destino antes — isso apaga tudo nele.

### Atualizando da v0.1.0 / v0.1.1 sem regravar

O seu `SHARE` (ROMs, saves, configurações) não é tocado. Na placa, remonte o `/boot` como leitura e escrita (`mount -o remount,rw /boot`); só cabem **dois** arquivos de sistema, então apague antes o `recalbox.old` mais antigo. Copie o novo `linux`, `initrd.gz` e `recalbox` da primeira partição da imagem (`/boot/boot/`) ao lado dos antigos, guardando os antigos como `.old`, confira o `md5sum` e reinicie. Instalações existentes mantêm o seu próprio `recalbox.conf`, então ajuste você mesmo `global.videomode=1920x1080`, `system.es.videomode=1920x1080`, `audio.device=alsa_card.0:[Out] HDMI:HiFi` e `updates.enabled=0`, **apague** o `/recalbox/share/system/custom.sh` se instalou o vigia antigo (a imagem agora tem o seu próprio) e acrescente `video=HDMI-A-1:1920x1080@60` na linha do kernel em `/boot/grub/grub.cfg`. Regravar é mais simples se você não tem nada a preservar.

### Checksums (SHA-256)

Os mesmos da seção em inglês acima.
