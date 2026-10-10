#!/bin/sh
# Migrate a running Recalbox (booted from USB/SATA SSD) to the internal NVMe of the Dragon Q6A.
#
# Run as root ON THE RECALBOX, booted from the external SSD (so the NVMe Linux partition is not in use).
# It shrinks the last (Linux) partition of the NVMe by SHRINK_GIB and creates three new partitions in the
# freed space, with the same layout the Recalbox first-boot creates:
#     p5 RECALBOX (5 GiB, vfat, ESP)   p6 SHARE (exfat, rest)   p7 OVERLAY (1 GiB, ext4)
# then copies /boot, the SHARE content and the overlay from the running system.
#
# DESTRUCTIVE if interrupted mid-way (power loss during the ext4 shrink). Everything it touches is printed first.
# A copy of the partition table is saved to /tmp/nvme-gpt.backup (restore: sgdisk --load-backup=...).
#
# Usage: migrate-to-nvme.sh [--yes]      env: DISK=/dev/nvme0n1 PART=4 SHRINK_GIB=64 RESIZE2FS="<cmd>"
set -eu

DISK=${DISK:-/dev/nvme0n1}
PART=${PART:-4}
SHRINK_GIB=${SHRINK_GIB:-64}
BOOT_GIB=5
OVERLAY_MIB=1024
P="${DISK}p"
# resize2fs is not in the Recalbox image: use the one from the Ubuntu rootfs via its own loader (see README)
RESIZE2FS=${RESIZE2FS:-"/tmp/ubtools/ld.so --library-path /tmp/ubtools/lib /tmp/ubtools/resize2fs"}

die() { echo "ERROR: $*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "run as root"
[ -b "$DISK" ] || die "$DISK not found"
case "$(cat /proc/cmdline)" in *label=RECALBOX*) ;; *) die "not running from Recalbox" ;; esac
# the running Recalbox must NOT be on the NVMe
BOOTDEV=$(awk '$2=="/boot"{print $1}' /proc/mounts)
case "$BOOTDEV" in "$DISK"*) die "Recalbox is running from $DISK; boot it from the external SSD first" ;; esac
[ -x /tmp/ubtools/resize2fs ] || die "missing /tmp/ubtools/resize2fs (copy resize2fs + libs from the Ubuntu rootfs, see docs/PLAN.md)"

# the partition we shrink must be the LAST one and an ext4 labelled as Linux
LAST=$(sgdisk -p "$DISK" | awk '/^ +[0-9]+ /{n=$1} END{print n}')
[ "$LAST" = "$PART" ] || die "partition $PART is not the last on $DISK (last is $LAST)"
sgdisk -i "$PART" "$DISK" | grep -q "0FC63DAF-8483-4772-8E79-3D69D8477DE4" || die "partition $PART is not a Linux filesystem"
TYPE=$(blkid -o value -s TYPE "${P}${PART}")
[ "$TYPE" = ext4 ] || die "partition $PART is $TYPE, expected ext4"

START=$(sgdisk -i "$PART" "$DISK" | awk '/First sector/{print $3}')
END=$(sgdisk -i "$PART" "$DISK" | awk '/Last sector/{print $3}')
GUID=$(sgdisk -i "$PART" "$DISK" | awk '/Partition unique GUID/{print $4}')
NAME=$(sgdisk -i "$PART" "$DISK" | sed -n "s/^Partition name: '\(.*\)'/\1/p")
WANT=$((SHRINK_GIB * 1024 * 1024 * 1024 / 512))
FREE_START=$(( (END - WANT + 1) / 2048 * 2048 ))
NEW_END=$((FREE_START - 1))
NEW_SECTORS=$((NEW_END - START + 1))
FS_BLOCKS=$((NEW_SECTORS * 512 / 4096 - 8))

echo "Disk:            $DISK"
echo "Shrinking:       ${P}${PART} ($NAME)  sectors $START-$END  ->  $START-$NEW_END"
echo "Freed region:    $FREE_START-$END  (~$(( (END - FREE_START + 1) * 512 / 1073741824 )) GiB)"
echo "ext4 target:     $FS_BLOCKS blocks of 4 KiB"
echo "New partitions:  ${P}$((LAST+1)) RECALBOX ${BOOT_GIB}G | ${P}$((LAST+2)) SHARE | ${P}$((LAST+3)) OVERLAY ${OVERLAY_MIB}M"
echo
if [ "${1:-}" != "--yes" ]; then
	printf 'Type SHRINK to continue: '; read -r ans; [ "$ans" = SHRINK ] || die "aborted"
fi

# make sure nothing on the NVMe is mounted
for m in $(awk -v d="$DISK" 'index($1,d)==1{print $2}' /proc/mounts); do umount "$m"; done
grep -q "^$DISK" /proc/mounts && die "NVMe still mounted"

sgdisk --backup=/tmp/nvme-gpt.backup "$DISK" >/dev/null
echo "GPT backup: /tmp/nvme-gpt.backup (copy it somewhere safe now)"

echo "== fsck"; e2fsck -f -y "${P}${PART}"
echo "== shrink ext4"; $RESIZE2FS "${P}${PART}" "$FS_BLOCKS"
e2fsck -f -n "${P}${PART}"

echo "== repartition (same start and GUID)"
sgdisk -d "$PART" -n "$PART:$START:$NEW_END" -t "$PART:8300" -c "$PART:$NAME" -u "$PART:$GUID" "$DISK"
N5=$((LAST+1)); N6=$((LAST+2)); N7=$((LAST+3))
BOOT_SECT=$((BOOT_GIB * 1024 * 1024 * 1024 / 512))
OV_SECT=$((OVERLAY_MIB * 1024 * 1024 / 512))
OV_START=$(( (END - OV_SECT + 1) / 2048 * 2048 ))
B_START=$FREE_START
B_END=$((B_START + BOOT_SECT - 1))
S_START=$(( (B_END + 1 + 2047) / 2048 * 2048 ))
S_END=$((OV_START - 1))
sgdisk -n "$N5:$B_START:$B_END" -t "$N5:EF00" -c "$N5:boot" \
       -n "$N6:$S_START:$S_END"  -t "$N6:0700" -c "$N6:primary" \
       -n "$N7:$OV_START:$END"   -t "$N7:8300" -c "$N7:primary" "$DISK"
partprobe "$DISK"; sleep 2
$RESIZE2FS "${P}${PART}"          # grow fs to fill the (slightly larger) partition
e2fsck -f -n "${P}${PART}"

echo "== format"
mkfs.vfat -F 32 -n RECALBOX "${P}${N5}"
mkfs.exfat -L SHARE "${P}${N6}"
mkfs.ext4 -F -L OVERLAY "${P}${N7}"

echo "== copy"
mkdir -p /tmp/nv_boot /tmp/nv_share /tmp/nv_overlay
mount "${P}${N5}" /tmp/nv_boot
# running /boot without the rollback copy
(cd /boot && find . -path ./boot/recalbox.old -prune -o -type f -print) | while read -r f; do
	mkdir -p "/tmp/nv_boot/$(dirname "$f")"; cp "/boot/$f" "/tmp/nv_boot/$f"
done
sync; umount /tmp/nv_boot

mount "${P}${N6}" /tmp/nv_share
cp -a /recalbox/share/. /tmp/nv_share/
sync; umount /tmp/nv_share

mount "${P}${N7}" /tmp/nv_overlay
cp -a /overlay/. /tmp/nv_overlay/ 2>/dev/null || true
sync; umount /tmp/nv_overlay

echo
echo "Done. Power off, UNPLUG the external SSD (both boot partitions carry the label RECALBOX) and boot"
echo "the NVMe entry from rEFInd. The previous Ubuntu data is intact in ${P}${PART} (now ~$(( NEW_SECTORS * 512 / 1073741824 )) GiB)."
