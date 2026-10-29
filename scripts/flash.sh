#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"

[[ $# == 1 ]] || die 'Usage: just flash /dev/disk/by-id/usb-…'
check_image
requested=$1
disk=$(check_disk "$requested")
(( EUID == 0 )) || die 'Run this command as root: sudo just flash /dev/disk/by-id/usb-…'
identity=$(disk_identity "$disk")
printf 'Installer: %s (%s bytes)\nTarget: %s\n' "$IMAGE" "$IMAGE_BYTES" "$disk"
show_disk "$disk"
printf 'Disk identity: %s\n' "$identity"
printf 'Type ERASE %s to erase this entire disk: ' "$disk"
IFS= read -r confirmation
[[ "$confirmation" == "ERASE $disk" ]] || die 'Erase confirmation did not match.'

# Unmount all target partitions, including any mounted below nested paths.
while IFS= read -r part; do
  while IFS= read -r mountpoint; do
    [[ -z "$mountpoint" ]] && continue
    printf 'Unmounting %s (%s)\n' "$part" "$mountpoint"
    umount -- "$mountpoint"
  done < <(findmnt -nro TARGET -S "$part" || true)
done < <(lsblk -nrpo NAME,TYPE -- "$disk" | awk '$2 == "part" { print $1 }')

# Resolve and validate again immediately before the write.
fresh=$(check_disk "$requested")
[[ "$fresh" == "$disk" && "$(disk_identity "$fresh")" == "$identity" ]] || die 'Disk identity changed; start again.'
if lsblk -nro MOUNTPOINTS -- "$fresh" | grep -q '[^[:space:]]'; then
  die 'Target still has mounted filesystems.'
fi
printf 'Writing %s to %s…\n' "$IMAGE" "$fresh"
dd if="$IMAGE" of="$fresh" bs=4M iflag=fullblock conv=fsync status=progress
sync
printf 'Comparing written bytes…\n'
cmp -n "$IMAGE_BYTES" "$IMAGE" "$fresh" || die 'Read-back comparison failed.'
blockdev --rereadpt "$fresh" || true
show_disk "$fresh"
printf 'Verified %s installer bytes on %s.\n' "$IMAGE_BYTES" "$fresh"
