# Thingino Wyze Cam v3 installer card

This repository prepares a microSD installer for a **Wyze Cam v3 with WYZEC3-compatible hardware**. It does not install firmware into a camera. Identify each camera's actual hardware before inserting the card: a WYZEC3 label may identify a swappable base, while a v4 camera needs a different installation path. The [Thingino camera guide](https://github.com/themactep/thingino-firmware/wiki/Camera:-Wyze-v3) describes the square v3 face versus the circular v4 face; the SoC marking is definitive if the case is opened.

## Pinned installer

Source: [`wltechblog/thingino-installers` commit `d3017aff4989a6b63cef6d680993b08b42261675`](https://github.com/wltechblog/thingino-installers/tree/d3017aff4989a6b63cef6d680993b08b42261675/wyze-cam-3). The selected file is `wyze-cam-3-sd.zip`, the no-tools WYZEC3 SD installer. The installer is intended for a camera still running factory firmware, not a later Thingino upgrade. Upstream says each camera produces a unique factory backup and the card must be freshly imaged before another camera.

| File | SHA-256 | Size |
| --- | --- | ---: |
| `wyze-cam-3-sd.zip` | `972d2e5698f9685c6105d9be3c47774f396e2ea60f18feb41a6ecb8f14ed572f` | 24,752,204 bytes |
| `sd.img` | `ee798cae4fcc4b8e37a253c0d4a4402ff7581fc651bef0ffad8508fba37ca3b6` | 125,829,120 bytes (120 MiB) |

The ZIP must contain only `sd.img`. `just fetch` verifies the ZIP hash, ZIP CRC, member name, image size, and image hash. The image has an MBR with one FAT32 LBA partition starting at sector 2048.

## Environment and card preparation

Run `direnv allow` in this directory, then `just devices` and `just fetch`. The flake pins the command versions through `flake.lock`. If direnv is unavailable, `nix develop` enters the same environment.

Use a stable whole-disk path from `/dev/disk/by-id/`, without a `-partN` suffix. For the card attached during preparation, it was:

```text
/dev/disk/by-id/usb-Prolific_Technology_Inc._SD_Card_Reader_ABCDEF0123456789AB-0:0
```

Check `just devices` each time. Device names such as `/dev/sda` can change after reinsertion. The flash script resolves and checks the requested path twice, rejects partitions, non-removable and non-USB disks, checks image fit, displays identity and mounts, and asks you to type `ERASE /dev/sdX` for the resolved disk. It unmounts target partitions before writing and compares all 125,829,120 written bytes with the image.

```sh
sudo just flash /dev/disk/by-id/usb-Prolific_Technology_Inc._SD_Card_Reader_ABCDEF0123456789AB-0:0
sudo just verify /dev/disk/by-id/usb-Prolific_Technology_Inc._SD_Card_Reader_ABCDEF0123456789AB-0:0
```

The verification command is read-only. After flashing, expect a 120 MiB MBR image at the front of the 14.8 GiB card, with one approximately 119 MiB FAT32 partition and the rest unallocated. Eject cleanly before inserting it into a camera. Flash again before camera two; never reuse the first camera's altered card contents.

## Camera first boot and factory backups

With the camera powered off and its hardware variant confirmed, insert the card and power on. The [installer instructions](https://github.com/wltechblog/thingino-installers/blob/d3017aff4989a6b63cef6d680993b08b42261675/wyze-cam-3/README.md) say to allow about 3–4 minutes for the camera's wireless provisioning network. After joining that network, open the camera's web interface, complete provisioning, and then perform a full Thingino firmware update through **Tools → Flash Operations**. That camera step is outside this card-preparation phase.

After each camera's installer run, remove the card and locate `WYZE_BACKUP_xxxxx/combined_backup.bin` on its mounted partition. Give each physical camera a distinct ID and copy its backup into its own ignored directory:

```sh
just backup camera-1 /run/media/$USER/INSTALLER/WYZE_BACKUP_xxxxx/combined_backup.bin
sha256sum --check backups/camera-1/combined_backup.bin.sha256
```

Replace the example mount path with the actual path from `lsblk -f`. The backup command refuses to overwrite an existing backup and records its SHA-256. Keep an additional copy outside this repository. Factory backups are unique to each camera; do not swap them.

## Diagnostics

Before camera insertion, check the card and recent kernel messages:

```sh
just devices
sudo fdisk -l /dev/disk/by-id/usb-Prolific_Technology_Inc._SD_Card_Reader_ABCDEF0123456789AB-0:0
sudo just verify /dev/disk/by-id/usb-Prolific_Technology_Inc._SD_Card_Reader_ABCDEF0123456789AB-0:0
journalctl -k -n 80 --no-pager
```

After a camera run, inspect the card's `WYZE_BACKUP_xxxxx` directory and installer log files on the mounted card. Use `lsblk -f` to find the current mount path, then set `CARD_MOUNT` to that path and run:

```sh
find "$CARD_MOUNT" -maxdepth 3 -type f -printf '%p (%s bytes)\n'
find "$CARD_MOUNT" -maxdepth 3 -type f -iname '*log*' -print
```

To save diagnostic output locally without tracking it, use `mkdir -p logs` and redirect command output there; `logs/` is Git-ignored. If the card is absent or unreadable, inspect `journalctl -k -n 80 --no-pager` for reader and filesystem errors. If the camera boots stock and repeatedly says “Ready to connect,” revisit the hardware identification: Thingino notes that v4 hardware can sit on a v3-labeled base.

For initial network checks after camera insertion, look for the camera's provisioning SSID after 3–4 minutes (`nmcli device wifi rescan; nmcli device wifi list`), confirm the client receives an address (`ip address`), then test the web interface with `curl -I http://CAMERA_IP/` once provisioned. Check the router's DHCP leases if the camera is not at the expected address. Avoid assuming an IP before it is provisioned.

## License

The scripts and documentation in this repository are available under the [MIT License](LICENSE). The downloaded Thingino installer remains subject to its upstream license.
