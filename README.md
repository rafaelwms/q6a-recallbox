# Recalbox for the Radxa Dragon Q6A

Port of [Recalbox](https://gitlab.com/recalbox/recalbox) (Buildroot-based retro-gaming OS) to the
Radxa Dragon Q6A (Qualcomm QCS6490, Adreno 643).

Status: **planning / scaffolding**. See [docs/PLAN.md](docs/PLAN.md).

This repo holds only the Q6A-specific delta (defconfig, board files, patches, overlay). `scripts/bootstrap.sh`
clones upstream Recalbox into `./recalbox/` and applies the delta on top, so upstream stays untouched.

Hardware groundwork (kernel, firmware, Wi-Fi, audio) is shared with the sibling project
`ubuntu-26.04.1-dragon-q6a`.

License: MIT (see LICENSE). Upstream Recalbox has its own license.
