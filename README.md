# openwrt-mt76x8-usb

OpenWrt 25.12.4 firmware for the **Hak5 WiFi Pineapple Mark VII** (Mediatek
MT7628AN, `ramips/mt76x8` target) with broad USB hardware enablement and
a workaround for the external USB-A port VBUS GPIO.

This is **not** Hak5's stock Pineapple firmware — it is vanilla upstream
OpenWrt selected from `https://downloads.openwrt.org/` with a custom
package list and a small `files/` overlay.

## What's in the image

* OpenWrt 25.12.4, `ramips/mt76x8` target, profile `hak5_wifi-pineapple-mk7`
* Stock OpenWrt defaults: LAN at `192.168.1.1/24`, no root password, LuCI on port 80, dropbear SSH on LAN side
* `wpad-basic-mbedtls` (WPA2) wifi stack
* LuCI web UI (`luci`, `luci-app-firewall`, `luci-app-package-manager`)
* Wireguard kernel module + cryptographic primitives (no userspace `wireguard-tools` — `apk add` post-flash if needed)
* Wifi auditing helpers: `aircrack-ng`, `airmon-ng`, `hcxdumptool`, `tcpdump`
* Editors: `nano`
* Network helpers: `ethtool`, `htop`, `mtr-json`, `ip-full`

### Hardware enablement (the reason this exists)

The mainline OpenWrt mt76x8 builds usually ship without USB-Ethernet,
USB-HID, and several USB-wifi drivers. This image adds:

| Class | Kmods |
|---|---|
| USB Ethernet | `asix`, `asix-ax88179`, `rtl8152`, `cdc-ether`, `cdc-ncm`, `cdc-mbim`, `cdc-eem`, `rndis` |
| USB HID | `usb-hid`, `hid`, `hid-generic` |
| USB wifi | `rt2800-usb`+`rt2800-lib` (Ralink RT5370 etc.), `rtw88-8821au` (Realtek RTL8811AU/RTL8812AU), `mt76`+`mt76x2u`+`mt76x0u`+`mt7601u`+`mt7603` (full mt76 family for built-in 2.4 GHz + external 5 GHz MT7612U) |
| LEDs | `leds-gpio` |
| Filesystems for USB storage | `fs-ext4`, `fs-vfat`, `fs-exfat`, `fs-ntfs3`, `nls-cp437`, `nls-iso8859-1`, `nls-utf8` |

Plus `gpio-button-hotplug` for the front reset button.

### External USB-A VBUS workaround

The Pineapple Mk7's external USB-A port has its VBUS gated by GPIO 5
(active-low). The DTB declares this as a `gpio-export` node with default
output `1`, so the `gpio-export` package asserts it at boot. **Some
combinations of u-boot and OpenWrt early-init leave the GPIO unasserted
even when the DTB is correct.** The image's `/etc/rc.local` asserts it
unconditionally on every boot as belt-and-braces. The first-boot
`uci-defaults` script also asserts it once so the external port works
without a reboot.

## Default configuration

The boot uci-defaults script sets `hostname=mt76x8-router` and
`timezone=UTC`. Change them post-flash to suit your deployment.

## Verifying the build

The image manifest is in `bin/targets/ramips/mt76x8/` after a build (see
`BUILD.md`). The supplied [`build/asu-build-req.json`](build/asu-build-req.json)
is a complete `Attended Sysupgrade` (ASU) build request and can be POSTed
to any ASU server (the OpenWrt project hosts one at
`https://sysupgrade.openwrt.org/`) to reproduce the image. The local
ImageBuilder method in [`BUILD.md`](BUILD.md) reproduces it offline.

## Flashing

The image file is named
`openwrt-25.12.4-ramips-mt76x8-hak5_wifi-pineapple-mk7-squashfs-sysupgrade.bin`.

**On a Pineapple already running OpenWrt**:

```sh
scp openwrt-*.bin root@192.168.1.1:/tmp/
ssh root@192.168.1.1 'sysupgrade -n /tmp/openwrt-*.bin'
```

`-n` discards existing config and gives a clean baseline. Drop `-n` to
preserve `/etc/` across the flash.

**On stock Hak5 firmware**: this device's u-boot accepts standard OpenWrt
sysupgrade images. Either use the Hak5 PineappleOS web UI's "Upload
Firmware" page (it accepts custom files), or boot to OpenWrt recovery
(reset button held during boot for ~4 seconds) and TFTP the image. See
upstream OpenWrt's [Pineapple Mk7 device
page](https://openwrt.org/toh/hak5/wifi-pineapple-mk7) for the recovery
procedure. **Make a flash backup of `mtd3` first** if you want to be
able to return to PineappleOS.

## First-boot defaults

* LAN at `192.168.1.1/24`, DHCP server on
* No root password — initial dropbear SSH from LAN side accepts empty
  password (`ssh root@192.168.1.1`, hit Enter); set a password with
  `passwd` immediately, or load your own SSH key
* LuCI at `http://192.168.1.1/`
* No WAN configured (no WAN port on the Mk7 — bring up a wifi STA or
  the external USB-Ethernet adapter as your uplink)
* `hostname=mt76x8-router`, `timezone=UTC`

## Contributing

Issues + PRs welcome. The image content is fully driven by `build/asu-build-req.json` and the `overlay/` tree.

## Trademarks

"Hak5" and "WiFi Pineapple" are trademarks of Hak5 LLC. This project is
not affiliated with, endorsed by, or sponsored by Hak5. References to
hardware names are nominative use.

## License

* The contents of this repository (overlay scripts, build recipe,
  documentation) are MIT-licensed — see [`LICENSE`](LICENSE).
* The resulting firmware images contain components from OpenWrt, which
  are licensed under GPL-2.0 and compatible open-source licenses.
  Corresponding source code is available from the OpenWrt 25.12.4
  release sources at
  [https://downloads.openwrt.org/releases/25.12.4/source/](https://downloads.openwrt.org/releases/25.12.4/source/).
