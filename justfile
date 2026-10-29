set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

devices:
    @lsblk -b -o NAME,PATH,SIZE,TYPE,RM,TRAN,MODEL,SERIAL,MOUNTPOINTS

fetch:
    @bash scripts/fetch.sh

flash disk:
    @bash scripts/flash.sh "{{disk}}"

verify disk:
    @bash scripts/verify.sh "{{disk}}"

backup camera_id source:
    @bash scripts/backup.sh "{{camera_id}}" "{{source}}"

check:
    @shellcheck -x -P . scripts/backup.sh scripts/fetch.sh scripts/flash.sh scripts/verify.sh
    @bash -n scripts/*.sh
