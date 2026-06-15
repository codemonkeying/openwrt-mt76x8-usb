# Building the firmware

Two reproduction paths are supported. Either gives the same result for
the supplied `build/asu-build-req.json`.

## Option A — ASU server (no local build environment)

This is the OpenWrt project's hosted Attended Sysupgrade service.

```sh
curl -X POST -H 'Content-Type: application/json' \
     --data @build/asu-build-req.json \
     https://sysupgrade.openwrt.org/api/v1/build
```

The server returns a JSON body with a `request_hash`. Poll the build
state and download the image from:

```
https://sysupgrade.openwrt.org/store/<request_hash>/openwrt-25.12.4-ramips-mt76x8-hak5_wifi-pineapple-mk7-squashfs-sysupgrade.bin
```

ASU is convenient but does not let you ship a `files/` overlay. If you
need the overlay in the image (you do, for the GPIO usb-power assertion
and the hostname default), use Option B.

## Option B — local ImageBuilder (recommended)

ImageBuilder is OpenWrt's official offline image generator. It pulls the
prebuilt package set from the official feed and packs them into an
image; it does not compile from source.

### Prerequisites

A Linux x86_64 host with `wget`, `tar`, `gawk`, `make`, `gcc`, and the
usual OpenWrt prereqs. See
[https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem](https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem)
for the full list.

### Fetch ImageBuilder

```sh
wget https://downloads.openwrt.org/releases/25.12.4/targets/ramips/mt76x8/openwrt-imagebuilder-25.12.4-ramips-mt76x8.Linux-x86_64.tar.zst
tar --use-compress-program=unzstd -xf openwrt-imagebuilder-25.12.4-ramips-mt76x8.Linux-x86_64.tar.zst
cd openwrt-imagebuilder-25.12.4-ramips-mt76x8.Linux-x86_64
```

### Stage the overlay

The repository's `overlay/` directory is the `files/` tree the
ImageBuilder will copy into `/`.

```sh
cp -r /path/to/openwrt-mt76x8-usb/overlay/* files/
```

### Build

Extract the package list from the build recipe:

```sh
PKGS=$(python3 -c 'import json,sys; print(" ".join(json.load(open("/path/to/openwrt-mt76x8-usb/build/asu-build-req.json"))["packages"]))')
```

Then run:

```sh
make image PROFILE=hak5_wifi-pineapple-mk7 PACKAGES="$PKGS" FILES=files
```

Build takes ~5 minutes on a modest machine. The output is at:

```
bin/targets/ramips/mt76x8/openwrt-25.12.4-ramips-mt76x8-hak5_wifi-pineapple-mk7-squashfs-sysupgrade.bin
```

### Verify

A `manifest`, a `sha256sums` file, and a CycloneDX SBOM
(`bom.cdx.json`) are produced alongside the image. The manifest lists
every package and its version; check that it contains the kmods this
image's README promises.

```sh
grep -E '^(dropbear|kmod-usb-net-asix|kmod-rt2800-usb|kmod-rtw88-8821au|kmod-mt76x2u|kmod-leds-gpio) ' \
     bin/targets/ramips/mt76x8/openwrt-25.12.4-ramips-mt76x8-hak5_wifi-pineapple-mk7.manifest
```

### Customising

* Add or remove packages by editing `build/asu-build-req.json`.
* Change the default hostname or timezone by editing
  `overlay/etc/uci-defaults/99-mt76x8-init.sh`.
* Drop a key into `overlay/etc/dropbear/authorized_keys` (mode 600) to
  pre-seed SSH access — **don't** commit it.
* If you want to ship the image with dropbear replaced by openssh-server
  for ed25519 support: add `-dropbear openssh-server openssh-client
  openssh-keygen openssh-sftp-server` to the package list. Note this
  changes the first-boot SSH behaviour — openssh defaults to pubkey-only
  for root and you'll need to seed a key in
  `overlay/etc/dropbear/authorized_keys` (still that path — the package
  `openssh-server` reads it on OpenWrt).

## SHA256 of the reference build

See `RELEASE-SHA256.txt` (added to each release).
