#!/usr/bin/env bash
set -euo pipefail

readonly UPSTREAM_COMMIT=d3017aff4989a6b63cef6d680993b08b42261675
readonly ZIP_SHA256=972d2e5698f9685c6105d9be3c47774f396e2ea60f18feb41a6ecb8f14ed572f
readonly IMAGE_SHA256=ee798cae4fcc4b8e37a253c0d4a4402ff7581fc651bef0ffad8508fba37ca3b6
readonly IMAGE_BYTES=125829120
readonly ZIP_URL="https://raw.githubusercontent.com/wltechblog/thingino-installers/${UPSTREAM_COMMIT}/wyze-cam-3/wyze-cam-3-sd.zip"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PROJECT_DIR
readonly ZIP="$PROJECT_DIR/downloads/wyze-cam-3-sd.zip"
readonly IMAGE="$PROJECT_DIR/downloads/sd.img"

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

check_image() {
  [[ -f "$ZIP" && -f "$IMAGE" ]] || die 'Run just fetch first.'
  printf '%s  %s\n' "$ZIP_SHA256" "$ZIP" | sha256sum --check --status || die 'ZIP hash mismatch.'
  unzip -tq "$ZIP" >/dev/null || die 'ZIP integrity check failed.'
  [[ "$(unzip -Z1 "$ZIP")" == 'sd.img' ]] || die 'Unexpected ZIP contents.'
  [[ "$(stat -c %s "$IMAGE")" == "$IMAGE_BYTES" ]] || die 'Image size mismatch.'
  printf '%s  %s\n' "$IMAGE_SHA256" "$IMAGE" | sha256sum --check --status || die 'Image hash mismatch.'
}

# Resolve the caller's path each time; do not retain a /dev/sdX name across operations.
check_disk() {
  local requested=$1 resolved type rm transport size name rootsource rootdisk
  [[ "$requested" == /dev/* ]] || die 'Pass an explicit whole-disk path under /dev.'
  resolved=$(readlink -f -- "$requested")
  [[ -b "$resolved" ]] || die "Not a block device: $requested"
  type=$(lsblk -dnro TYPE -- "$resolved")
  [[ "$type" == disk ]] || die "Refusing a $type; pass the whole disk."
  rm=$(lsblk -dnro RM -- "$resolved")
  transport=$(lsblk -dnro TRAN -- "$resolved")
  [[ "$rm" == 1 && "$transport" == usb ]] || die 'Disk must be removable and connected over USB.'
  name=$(basename "$resolved")
  [[ -e "/sys/class/block/$name" ]] || die 'Disk disappeared.'
  size=$(lsblk -dnbo SIZE -- "$resolved")
  (( size >= IMAGE_BYTES )) || die "Image ($IMAGE_BYTES bytes) exceeds disk ($size bytes)."
  rootsource=$(findmnt -nro SOURCE /)
  rootdisk=$(lsblk -no PKNAME "${rootsource%%\[*}" 2>/dev/null || true)
  [[ -z "$rootdisk" || "$name" != "$rootdisk" ]] || die 'Refusing the system disk.'
  if lsblk -nro MOUNTPOINTS -- "$resolved" | grep -Eq '^(/|/boot|/home)(/|$)'; then
    die 'Refusing a disk containing a system mount.'
  fi
  printf '%s\n' "$resolved"
}

disk_identity() {
  local disk=$1
  printf '%s|%s|%s|%s|%s\n' \
    "$(lsblk -dnro MAJ:MIN -- "$disk")" \
    "$(lsblk -dnbo SIZE -- "$disk")" \
    "$(lsblk -dnro MODEL -- "$disk" | xargs)" \
    "$(lsblk -dnro SERIAL -- "$disk" | xargs)" \
    "$(readlink -f "/sys/class/block/$(basename "$disk")/device")"
}

show_disk() {
  lsblk -b -o NAME,PATH,SIZE,TYPE,RM,TRAN,MODEL,SERIAL,MOUNTPOINTS -- "$1"
}
