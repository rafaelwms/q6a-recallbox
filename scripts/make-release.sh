#!/usr/bin/env bash
# Turn the image built by Buildroot into GitHub release assets:
#   - <name>_<version>.img.xz.partNN   parts of at most MAX_PART bytes (default 1,400,000,000)
#   - SHA256SUMS-parts.txt             checksums of every part
#   - SHA256SUMS-full.txt              checksum of the reassembled .img.xz
# and verifies that the parts concatenate back to the original file.
#
# Usage: scripts/make-release.sh <version> [image.img.xz] [outdir]
#   e.g. scripts/make-release.sh v0.1.0 recalbox/output/images/recalbox/recalbox-q6a.img.xz release
set -euo pipefail

VERSION="${1:?usage: $0 <version> [image.img.xz] [outdir]}"
SRC="${2:-recalbox/output/images/recalbox/recalbox-q6a.img.xz}"
OUT="${3:-release}"
NAME="recalbox-radxa-dragon-q6a_${VERSION}"
MAX_PART="${MAX_PART:-1400000000}"

[ -f "$SRC" ] || { echo "image not found: $SRC" >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then SUM="sha256sum"; else SUM="shasum -a 256"; fi

mkdir -p "$OUT"
rm -f "$OUT/${NAME}.img.xz"* "$OUT"/SHA256SUMS-*.txt
cp "$SRC" "$OUT/${NAME}.img.xz"

cd "$OUT"
echo ">>> full image checksum"
$SUM "${NAME}.img.xz" > SHA256SUMS-full.txt

echo ">>> splitting into parts of <= ${MAX_PART} bytes"
split -d -a 2 -b "$MAX_PART" "${NAME}.img.xz" "${NAME}.img.xz.part"
$SUM "${NAME}.img.xz.part"* > SHA256SUMS-parts.txt

echo ">>> verifying: parts -> concatenated -> checksum"
$SUM -c SHA256SUMS-parts.txt >/dev/null
rebuilt="$(cat "${NAME}.img.xz.part"* | $SUM | cut -d' ' -f1)"
expected="$(cut -d' ' -f1 SHA256SUMS-full.txt)"
[ "$rebuilt" = "$expected" ] || { echo "MISMATCH after reassembly" >&2; exit 1; }
xz -t "${NAME}.img.xz" && echo "xz integrity OK"

# the whole file is kept locally for convenience; only parts + sums go into the GitHub release
echo
echo "Release assets (upload these):"
ls -l "${NAME}.img.xz.part"* SHA256SUMS-*.txt | awk '{printf "  %-62s %10.1f MB\n", $9, $5/1000000}'
