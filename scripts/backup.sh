#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "$0")/common.sh"

[[ $# == 2 ]] || die 'Usage: just backup CAMERA_ID /path/to/WYZE_BACKUP_xxxxx/combined_backup.bin'
camera_id=$1
source_file=$2
[[ "$camera_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die 'Camera ID may contain only letters, digits, dots, dashes and underscores.'
[[ "$(basename "$source_file")" == combined_backup.bin && -f "$source_file" ]] || die 'Source must be an existing combined_backup.bin.'
dest_dir="$PROJECT_DIR/backups/$camera_id"
mkdir -p "$dest_dir"
[[ ! -e "$dest_dir/combined_backup.bin" ]] || die 'Backup already exists; refusing to overwrite it.'
install -m 0600 -- "$source_file" "$dest_dir/combined_backup.bin"
( cd "$dest_dir" && sha256sum combined_backup.bin > combined_backup.bin.sha256 && sha256sum --check combined_backup.bin.sha256 )
printf 'Stored factory backup in %s\n' "$dest_dir"
