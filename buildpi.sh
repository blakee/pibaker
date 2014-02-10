#!/bin/bash
# Based on https://kmp.or.at/~klaus/raspberry/build_rpi_sd_card.sh 
#set -x

relative_path=`dirname $0`
base=`cd ${relative_path}; pwd`

bootsize="64M"
totalsize="2500" # MB
image="$base/img/pi.img"
rootfs="$base/rootfs"

rootfsbase="$base/rootfsbase"
hostname="Rasp"

###########################
###########################

mkdir -p `dirname "$image"`
dd if=/dev/zero of=${image} bs=1MB seek=${totalsize} count=0
device=`losetup -f --show ${image}`
echo "image ${image} created and mounted as ${device}"

fdisk ${device} << EOF
n
p
1

+${bootsize}
t
c
n
p
2


w
EOF

until losetup -d ${device}; do
	sleep 1
done

device=`kpartx -va ${image} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"
bootp=${device}p1
rootp=${device}p2

mkfs.vfat -n BOOT ${bootp}
mkfs.ext4 -L ROOT ${rootp}

mkdir -p ${rootfs} >/dev/null
mount "$rootp" "$rootfs" || { echo "couldn't mount partition 2" >&2; exit 1; }

mkdir -p "$rootfs/boot" >/dev/null
mount "$bootp" "$rootfs/boot" || { echo "couldn't mount partition 1" >&2; exit 1; }

mkdir -p ${rootfs}/proc
mkdir -p ${rootfs}/sys
mkdir -p ${rootfs}/dev

mount -t proc none ${rootfs}/proc
mount -t sysfs none ${rootfs}/sys
mount -o bind /dev ${rootfs}/dev

cp -Rp $rootfsbase/* "$rootfs"

cd "$rootfs"

ip=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)

deb_local_mirror="http://$ip:3142/archive.raspbian.org/raspbian"
deb_local_mirror_2="http://$ip:3142/archive.raspberrypi.org/debian"
deb_release="wheezy"

LANG=C debootstrap --no-check-gpg --foreign --arch armhf ${deb_release} . ${deb_local_mirror}
cp /usr/bin/qemu-arm-static usr/bin
LANG=C chroot . /debootstrap/debootstrap --second-stage

umount "$rootfs/proc" # in case it's still mounted, usually it gets unmounted during the bootstrap process
umount "$rootfs/sys" # same

echo "deb ${deb_local_mirror} ${deb_release} main contrib non-free" > etc/apt/sources.list
echo "deb ${deb_local_mirror_2} ${deb_release} main" >> etc/apt/sources.list

echo "$hostname" > etc/hostname
echo "127.0.0.1 localhost $hostname" > etc/hosts
rm -f etc/mtab
ln -s /proc/mounts etc/mtab

if [ -e "$rootfs/root/provision.sh" ]; then
	LANG=C chroot "$rootfs" /root/provision.sh
fi

sync

cd -

until umount ${bootp}; do
        sleep 1
done

until umount ${rootfs}/dev; do
        sleep 1
done

until umount ${rootp}; do
        sleep 1
done

until dmsetup remove ${bootp}; do
        sleep 1
done

until dmsetup remove ${rootp}; do
        sleep 1
done

until kpartx -d ${image}; do
        sleep 1
done

echo "done."
