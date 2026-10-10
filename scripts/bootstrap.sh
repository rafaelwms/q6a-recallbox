#!/usr/bin/env bash
# Clone upstream Recalbox into ./recalbox and overlay the Q6A delta from this repo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM="${RECALBOX_REPO:-https://gitlab.com/recalbox/recalbox.git}"
BRANCH="${RECALBOX_BRANCH:-master}"

if [ ! -d "$ROOT/recalbox/.git" ]; then
  git clone --branch "$BRANCH" --recurse-submodules "$UPSTREAM" "$ROOT/recalbox"
fi

cp -v "$ROOT"/configs/*_defconfig "$ROOT/recalbox/configs/" 2>/dev/null || true
mkdir -p "$ROOT/recalbox/board/recalbox/qualcomm"
cp -a "$ROOT/board/recalbox/qualcomm/." "$ROOT/recalbox/board/recalbox/qualcomm/"
echo "Done. Next: cd recalbox && make recalbox-q6a_defconfig (once M1 lands)"
