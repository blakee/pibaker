#!/bin/bash

set -x

mount -t proc none /proc
wget http://archive.raspberrypi.org/debian/raspberrypi.gpg.key -O - | apt-key add -
apt-get update

apt-get -y install libraspberrypi-bin firmware-atheros firmware-brcm80211 firmware-libertas firmware-ralink firmware-realtek fake-hwclock git ca-certificates ifplugd curl module-init-tools psmisc telnet file ntp openssh-server less wpasupplicant 

wget https://raw.github.com/Hexxeh/rpi-update/master/rpi-update -O /usr/bin/rpi-update
chmod +x /usr/bin/rpi-update

/etc/init.d/fake-hwclock stop #save the time

rm -f /etc/wpa_supplicant/wpa_supplicant.conf
ln -s /boot/wifi_config.txt /etc/wpa_supplicant/wpa_supplicant.conf

echo "root:changethis" | chpasswd

echo "test it all, now.  spawning bash:"
bash

echo -e "deb http://archive.raspbian.org/raspbian wheezy main contrib non-free\ndeb http://archive.raspberrypi.org/debian wheezy main" > /etc/apt/sources.list

rm -f /etc/cron.daily/{man-db,apt,samba,ntp,aptitude,bsdmainutils,passwd,dpkg} /etc/cron.weekly/man-db
umount /proc
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /usr/sbin/policy-rc.d
cd /
rm -f root/.bash_history
rm -rf usr/share/doc/*
rm -rf usr/share/man/*
rm -rf usr/share/info/*
rm -rf root/.ssh/known_hosts
rm -rf var/lib/dhcp/*.leases
rm -f var/log/* 2>/dev/null
rm -rf tmp/*
rm -rf var/tmp/*
:> etc/resolv.conf

