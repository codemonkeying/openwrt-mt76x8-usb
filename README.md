# openwrt-mt76x8-usb

Vanilla OpenWrt 25.12.6 for the Hak5 WiFi Pineapple Mk7 (`ramips/mt76x8`), with the USB drivers stock builds leave out and a fix for the dead external USB-A port.

## What's added

- USB Ethernet: asix, ax88179, rtl8152, cdc-ether/ncm/mbim/eem, rndis
- USB wifi: rt2800-usb, rtw88-8821au, the mt76 family (mt76x2u, mt76x0u, mt7601u)
- USB HID and storage (ext4, vfat, exfat, ntfs3)
- LuCI, nano, htop, mtr, tcpdump, aircrack-ng, hcxdumptool

The external USB-A port's power is gated by GPIO 5. Some boots leave it off, so `overlay/etc/rc.local` switches it on every boot.

## Build

Uses the official ImageBuilder (no compiling):

```sh
wget https://downloads.openwrt.org/releases/25.12.6/targets/ramips/mt76x8/openwrt-imagebuilder-25.12.6-ramips-mt76x8.Linux-x86_64.tar.zst
tar --use-compress-program=unzstd -xf openwrt-imagebuilder-*.tar.zst && cd openwrt-imagebuilder-*/
cp -r ../overlay files
PKGS=$(python3 -c 'import json;print(" ".join(json.load(open("../build/asu-build-req.json"))["packages"]))')
make image PROFILE=hak5_wifi-pineapple-mk7 PACKAGES="$PKGS" FILES=files
```

Image lands in `bin/targets/ramips/mt76x8/`.

### Recovery image (initramfs)

The ImageBuilder can't make it; it needs a full source build (about 15 GB disk, 1-4 hours):

```sh
git clone --depth 1 --branch v25.12.6 https://github.com/openwrt/openwrt.git && cd openwrt
./scripts/feeds update -a && ./scripts/feeds install -a
cp ../build/initramfs.config .config && make defconfig
make -j$(nproc) download && make -j$(nproc)
```

Output: `bin/targets/ramips/mt76x8/*-initramfs-kernel.bin`.

## Flash

Download both images from the [Releases](../../releases) page and check them against `sha256sums`:

- `...-squashfs-sysupgrade.bin`: the normal install/upgrade image.
- `...-initramfs-kernel.bin`: a recovery image that runs from RAM. Only needed if the box won't boot or you're coming from stock Hak5 firmware.

### Normal way (box already runs OpenWrt)

```sh
scp -O openwrt-*-sysupgrade.bin root@192.168.1.1:/tmp/
ssh root@192.168.1.1 'sysupgrade -n /tmp/openwrt-*-sysupgrade.bin'
```

`-n` wipes the config. Drop it to keep your settings. The box reboots on its own (about 3-4 minutes), then comes up on 192.168.1.1.

### If you're stuck (bricked, boot loop, or coming from Hak5 firmware)

The Mk7's bootloader has its own recovery web page, so you don't need to open the case or use a serial cable. It only flashes the OS area; the bootloader itself is never touched, so you can always come back here.

1. Plug the Mk7's USB-C into your computer. It shows up as a USB network adapter (ASIX AX88772B).
2. Give that adapter the static address `172.16.42.42/24`. On Linux, for example:
   ```sh
   sudo ip link set <iface> up
   sudo ip addr add 172.16.42.42/24 dev <iface>
   sudo ip addr add 192.168.1.2/24 dev <iface>   # for step 7
   ```
   The adapter disappears and comes back each time the Mk7 loses power, so re-run these after every replug.
3. Unplug the Mk7. Hold the reset button **firmly** and plug it back in while still holding it.
4. Let go after about 3 **red** flashes. The LED should blink fast and then stay **solid red**. If it goes blue, it's booting normally: unplug and try again.
5. Open `http://172.16.42.1` (port 80, no `:1471`). You'll see the "WiFi Pineapple Recovery" page.
6. Upload the **initramfs-kernel** image in the firmware/OS upload form and confirm. Use only the default form; don't touch any U-Boot or calibration (caldata) upload if your browser shows one. From the command line:
   ```sh
   curl -F "os=@openwrt-25.12.6-ramips-mt76x8-hak5_wifi-pineapple-mk7-initramfs-kernel.bin" http://172.16.42.1/
   ```
   Don't unplug it. It flashes and reboots by itself in about 2 minutes.
7. It now runs OpenWrt from RAM on `192.168.1.1` (no root password). Only some USB radios show up at this stage; that's expected.
8. Install the real image from there, same as the normal way:
   ```sh
   scp -O openwrt-*-sysupgrade.bin root@192.168.1.1:/tmp/
   ssh root@192.168.1.1 'sysupgrade -n /tmp/openwrt-*-sysupgrade.bin'
   ```
9. After about 3-4 minutes it boots from flash with everything working, all radios and the external USB-A port included.

Defaults are stock OpenWrt: LAN 192.168.1.1, no root password (set one in LuCI or with `passwd`), hostname `mt76x8-router`.

Both images were tested on real hardware: recovery page -> initramfs -> sysupgrade, and a direct sysupgrade.

### Going back to Hak5 firmware

Do steps 1-5 of "If you're stuck", but in step 6 upload Hak5's own recovery file from the [Hak5 Download Portal](https://downloads.hak5.org/pineapple) instead of the initramfs. Then follow Hak5's setup at `http://172.16.42.1:1471`.

## Source

The images are built from OpenWrt v25.12.6 (https://github.com/openwrt/openwrt, tag `v25.12.6`) plus this repo's `build/asu-build-req.json`, `build/initramfs.config` and `overlay/`. OpenWrt's source for that tag, including all GPL code in the images, is available from the OpenWrt project at that link.

Not affiliated with Hak5. No Hak5 firmware or code is included; WiFi Pineapple is their trademark.

## License

MIT, see `LICENSE`. OpenWrt and its packages keep their own licences (mostly GPL-2.0).
