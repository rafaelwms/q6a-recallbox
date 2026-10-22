#!/usr/bin/env bash
# One-shot, reproducible build of the Recalbox image for the Radxa Dragon Q6A and its release assets.
#
#   ./scripts/build-all.sh v0.1.2
#
# Steps: clone upstream Recalbox at the pinned commit and apply patches/  ->  build the image  ->  Buildroot legal-info
#        ->  split the image into parts <= 1.4 GB with checksums (release/<version>/)  ->  pack legal-info next to them.
# Needs a Linux x86_64 host (~60 GB free, ~90 min on 20 cores for the first build; a few minutes afterwards thanks to ccache).
# Very new distros (e.g. Ubuntu 26.04) need an older host toolchain: set HOSTCC14/HOSTCXX14 (wrappers for gcc-14/g++-14) and
# CMAKE3_BIN (a directory with CMake 3.x); see docs/PLAN.md. gitlab.com's archive URLs return 403: prefetch with scripts/fetch_gitlab.py.
set -euo pipefail
VERSION="${1:?usage: $0 <version>   e.g. $0 v0.1.2}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export LC_ALL=C
export CMAKE_POLICY_VERSION_MINIMUM=3.5
[ -n "${CMAKE3_BIN:-}" ] && export PATH="$CMAKE3_BIN:$PATH"
MAKE_ARGS=(-j"$(nproc)")
[ -n "${HOSTCC14:-}" ] && MAKE_ARGS+=("HOSTCC=$HOSTCC14")
[ -n "${HOSTCXX14:-}" ] && MAKE_ARGS+=("HOSTCXX=$HOSTCXX14")

echo ">>> 1/4 upstream Recalbox @ pinned commit + patches/"
./scripts/bootstrap.sh

echo ">>> 2/4 building the image"
cd "$ROOT/recalbox"
make recalbox-q6a_defconfig
make "${MAKE_ARGS[@]}"

echo ">>> 3/4 licences and source list (Buildroot legal-info)"
# Some upstream packages ship stale licence-file hashes and make `legal-info` fail on them: keep going (-k) and also dump
# `show-info`, which lists every package with its version, licence and source URL without needing the downloads.
make -k legal-info "${MAKE_ARGS[@]}" || echo "NOTE: legal-info reported errors on some packages (upstream licence hashes); show-info below covers all of them."
make -s show-info "${MAKE_ARGS[@]}" > output/legal-info/show-info.json

echo ">>> 4/4 release assets (parts <= 1.4 GB + SHA-256 sums)"
cd "$ROOT"
./scripts/make-release.sh "$VERSION" recalbox/output/images/recalbox/recalbox-q6a.img.xz "release/$VERSION"
# the downloaded sources (several GB) are left out: every URL and version is in manifest.csv / show-info.json
tar --exclude=legal-info/sources --exclude=legal-info/host-sources -C recalbox/output -czf "release/$VERSION/q6a-legal-info_${VERSION}.tar.gz" legal-info
( cd "release/$VERSION" && { sha256sum "q6a-legal-info_${VERSION}.tar.gz" 2>/dev/null || shasum -a 256 "q6a-legal-info_${VERSION}.tar.gz"; } >> SHA256SUMS-parts.txt )
echo
echo "Done. Upload release/$VERSION/*.part* SHA256SUMS-*.txt q6a-legal-info_*.tar.gz to a GitHub release (see RELEASE.md)."
