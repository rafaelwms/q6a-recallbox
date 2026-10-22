#!/usr/bin/env bash
# Clone upstream Recalbox into ./recalbox and overlay the Q6A delta from this repo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM="${RECALBOX_REPO:-https://gitlab.com/recalbox/recalbox.git}"
BRANCH="${RECALBOX_BRANCH:-master}"
# The patch series is made against this exact upstream commit (keeps the build reproducible even if upstream master moves on).
BASE="${RECALBOX_BASE:-27224c1}"

if [ ! -d "$ROOT/recalbox/.git" ]; then
  git clone --branch "$BRANCH" --recurse-submodules "$UPSTREAM" "$ROOT/recalbox"
fi

# The Q6A delta is kept as git patches against upstream (see patches/); apply them in order.
cd "$ROOT/recalbox"
git checkout -q -B q6a "$BASE"
git submodule update --init --recursive
for p in "$ROOT"/patches/*.patch; do
  git -c user.name=q6a -c user.email=q6a@localhost am --3way "$p"
done
echo "Done. Next: make recalbox-q6a_defconfig && make -j\$(nproc)"
