#!/bin/sh
# Default init for the mt76x8-router image.
#
# Runs ONCE on first boot then deletes itself (OpenWrt uci-defaults
# convention). Sets minimum sensible defaults without any peer-, key-,
# or operator-identifying data.

# Hostname — change post-flash to suit.
uci set system.@system[0].hostname='mt76x8-router'

# Timezone — UTC is the safe public default. Users can re-set via LuCI.
uci set system.@system[0].timezone='UTC'
uci set system.@system[0].zonename='UTC'

uci commit system

# GPIO usb-power assertion: assert at first-boot so the external USB-A
# port has VBUS without a reboot. rc.local handles every subsequent boot.
[ -e /sys/class/gpio/usb-power/value ] && echo 1 > /sys/class/gpio/usb-power/value 2>/dev/null

exit 0
