#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"

[[ $# == 1 ]] || die 'Usage: just verify /dev/disk/by-id/usb-…'
check_image
disk=$(check_disk "$1")
show_disk "$disk"
cmp -n "$IMAGE_BYTES" "$IMAGE" "$disk" || die 'Read-back comparison failed.'
printf 'Verified %s bytes match %s.\n' "$IMAGE_BYTES" "$IMAGE"
