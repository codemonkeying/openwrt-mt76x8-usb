#!/bin/sh
# First boot: neutral hostname and timezone, and power the external USB port.
uci set system.@system[0].hostname='mt76x8-router'
uci set system.@system[0].timezone='UTC'
uci set system.@system[0].zonename='UTC'
uci commit system
[ -e /sys/class/gpio/usb-power/value ] && echo 1 > /sys/class/gpio/usb-power/value 2>/dev/null
exit 0
