#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"

mkdir -p "$PROJECT_DIR/downloads"
if [[ ! -f "$ZIP" ]] || ! printf '%s  %s\n' "$ZIP_SHA256" "$ZIP" | sha256sum --check --status; then
  curl --fail --location --retry 3 --output "$ZIP.part" "$ZIP_URL"
  mv -- "$ZIP.part" "$ZIP"
fi
printf '%s  %s\n' "$ZIP_SHA256" "$ZIP" | sha256sum --check || die 'ZIP hash mismatch.'
unzip -tq "$ZIP" || die 'ZIP integrity check failed.'
[[ "$(unzip -Z1 "$ZIP")" == 'sd.img' ]] || die 'Unexpected ZIP contents.'
unzip -p "$ZIP" sd.img > "$IMAGE.part"
mv -- "$IMAGE.part" "$IMAGE"
check_image
printf 'Validated image:\n'
sha256sum "$IMAGE"
fdisk -l "$IMAGE"
