# NOTICE / AVISO LEGAL

## English

**This is an unofficial, community port.** It is not made, endorsed or supported by the Recalbox team, by Radxa or by Qualcomm.
"Recalbox" is the name of a project owned by its authors; "Radxa", "Dragon" and "Qualcomm" are trademarks of their owners.
Please do **not** report problems with this image to the Recalbox team; use this repository's issues.

**Non-commercial use only.** The image is built from Recalbox, whose licence ([LICENSE-RECALBOX.md](LICENSE-RECALBOX.md), reproduced
unchanged from upstream) states that redistributions *may not be sold without authorization, nor used in a commercial product or
activity*. Do not sell this image or devices/cards preloaded with it. Ask the Recalbox team for authorisation if you need that.

**Complete source code.** Recalbox requires modified redistributions to ship the complete source of everything in the binary.
This repository holds the Q6A delta (the [`patches/`](patches) series and the board files); `scripts/bootstrap.sh` clones upstream Recalbox
at the exact commit recorded in the series, and each release ships `legal-info` (the per-package licences, the source list and `show-info.json` with every package's version, licence and source URL, produced
by Buildroot's `make legal-info`). Everything needed to rebuild the image is therefore either in this repository, in that manifest or
fetched from the upstream project at the versions listed there.

**What is in the image, and under which licence.**

| Component | Licence |
|---|---|
| Recalbox (Buildroot external tree, EmulationStation, scripts) | Recalbox licence (non-commercial, see above) |
| Buildroot | GPL-2.0-or-later |
| Linux kernel 7.2.9 (plus the DRM mode-limit patch in this repo) | GPL-2.0 |
| `aic8800` Wi-Fi/Bluetooth driver (out of tree) | GPL-2.0 |
| Qualcomm DSP / GPU / audio firmware, AIC8800 firmware (downloaded from [radxa-pkg](https://github.com/radxa-pkg) at build time) | Proprietary firmware: **not** in this repository; redistributed in the image under the vendors' firmware terms |
| Mesa, SDL2, PulseAudio, ffmpeg, RetroArch, libretro cores, standalone emulators | Each project's own licence, listed per package in `legal-info` (several emulators are non-commercial too) |
| The Q6A scripts, installers and documents in this repository | MIT ([LICENSE](LICENSE)) |

**Games and BIOS files are not included and not provided.** Use only ROMs and BIOS images you are legally entitled to use.

**No warranty.** See the disclaimer in [LICENSE-RECALBOX.md](LICENSE-RECALBOX.md). Writing the image erases the target disk: you do it at your own risk.

## Português

**Este é um port da comunidade, não oficial.** Não é feito, endossado nem suportado pela equipe do Recalbox, pela Radxa ou pela Qualcomm.
"Recalbox" é o nome de um projeto de seus autores; "Radxa", "Dragon" e "Qualcomm" são marcas de seus donos.
**Não** reporte problemas desta imagem à equipe do Recalbox; use as issues deste repositório.

**Somente uso não comercial.** A imagem é construída a partir do Recalbox, cuja licença ([LICENSE-RECALBOX.md](LICENSE-RECALBOX.md), reproduzida
sem alterações do upstream) diz que as redistribuições *não podem ser vendidas sem autorização, nem usadas em produto ou atividade comercial*.
Não venda esta imagem nem aparelhos/cartões já gravados com ela. Peça autorização à equipe do Recalbox se precisar disso.

**Código-fonte completo.** O Recalbox exige que redistribuições modificadas incluam o código completo de tudo o que está no binário.
Este repositório contém o delta da Q6A (a série em [`patches/`](patches) e os arquivos da placa); o `scripts/bootstrap.sh` clona o Recalbox
upstream no commit exato registrado na série, e cada release traz o `legal-info` (licenças e lista de fontes por pacote, gerados pelo
`make legal-info` do Buildroot). Tudo o que é preciso para recompilar a imagem está, portanto, neste repositório, nesse manifesto ou
no projeto upstream, nas versões ali listadas.

**O que há na imagem e sob qual licença:** a tabela acima vale igualmente (Recalbox: licença própria não comercial; Buildroot, kernel e driver
`aic8800`: GPL; firmwares da Qualcomm/AIC8800: proprietários, **não** estão neste repositório e vêm da [radxa-pkg](https://github.com/radxa-pkg)
na hora da build; Mesa, SDL2, emuladores etc.: cada um com sua licença, em `legal-info`; scripts, instaladores e documentos deste repositório: MIT).

**Jogos e BIOS não estão incluídos nem são fornecidos.** Use apenas ROMs e BIOS que você tem o direito de usar.

**Sem garantia.** Veja o aviso em [LICENSE-RECALBOX.md](LICENSE-RECALBOX.md). Gravar a imagem apaga o disco de destino: por sua conta e risco.
