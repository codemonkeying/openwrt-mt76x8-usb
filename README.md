# openwrt-mt76x8-usb

Vanilla OpenWrt 25.12.4 for the Hak5 WiFi Pineapple Mk7 (`ramips/mt76x8`), with the USB drivers stock builds leave out and a fix for the dead external USB-A port.

## What's added

- USB Ethernet: asix, ax88179, rtl8152, cdc-ether/ncm/mbim/eem, rndis
- USB wifi: rt2800-usb, rtw88-8821au, the mt76 family (mt76x2u, mt76x0u, mt7601u)
- USB HID and storage (ext4, vfat, exfat, ntfs3)
- LuCI, nano, htop, mtr, tcpdump, aircrack-ng, hcxdumptool

The external USB-A port's power is gated by GPIO 5. Some boots leave it off, so `overlay/etc/rc.local` switches it on every boot.

## Build

Uses the official ImageBuilder (no compiling):

```sh
wget https://downloads.openwrt.org/releases/25.12.4/targets/ramips/mt76x8/openwrt-imagebuilder-25.12.4-ramips-mt76x8.Linux-x86_64.tar.zst
tar --use-compress-program=unzstd -xf openwrt-imagebuilder-*.tar.zst && cd openwrt-imagebuilder-*/
cp -r ../overlay files
PKGS=$(python3 -c 'import json;print(" ".join(json.load(open("../build/asu-build-req.json"))["packages"]))')
make image PROFILE=hak5_wifi-pineapple-mk7 PACKAGES="$PKGS" FILES=files
```

Image lands in `bin/targets/ramips/mt76x8/`.

## Flash

```sh
scp openwrt-*-sysupgrade.bin root@192.168.1.1:/tmp/
ssh root@192.168.1.1 'sysupgrade -n /tmp/openwrt-*-sysupgrade.bin'
```

From stock Hak5 firmware, upload it on the firmware page or use recovery (hold reset while powering on).

Defaults are stock OpenWrt: LAN 192.168.1.1, no root password, hostname `mt76x8-router`.

Not affiliated with Hak5. No Hak5 firmware or code is included; WiFi Pineapple is their trademark.

## License

Copyright (c) 2026 codemonkeying. All rights reserved.
