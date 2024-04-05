#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

#GENTOO_MIRROR=https://mirror.yandex.ru/gentoo-distfiles/

STAGE3_BALL_URL=https://distfiles.gentoo.org/releases/amd64/autobuilds/20240317T170433Z/stage3-amd64-systemd-mergedusr-20240317T170433Z.tar.xz

#Check error mount
mount_check() {
     if ! mountpoint -q "$1"; then
        echo "Error: Did not mounted $1"
        exit 1
     else
	echo "$1 Success mounted"
     fi
}

#Making partitions of disk

echo "Mounting partitions..."
echo -ne "label:gpt\nsize=1GiB,type=\"EFI System\"\nsize=4GiB,type=\"Linux swap\"\nsize=+,type=\"Linux root(x86-64)\"\n" | sfdisk /dev/vda

echo "Making filesystem...formatting partition"
mkfs.vfat -F 32 /dev/vda1
mkfs.ext4 /dev/vda3
mkswap /dev/vda2
swapon /dev/vda2

echo "Making mountpoint and mounting /mnt/gentoo/efi"

mkdir --parents /mnt/gentoo/
mount /dev/vda3 /mnt/gentoo/
mount_check "/mnt/gentoo"


mkdir --parents /mnt/gentoo/efi
mount /dev/vda1 /mnt/gentoo/efi
mount_check "/mnt/gentoo/efi"

cd /mnt/gentoo

wget "$STAGE3_BALL_URL"
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner


echo "Setting up make.conf..."
echo -ne "COMMON_FLAGS=\"-O2 -march=znver3 -pipe\"\nCFLAGS=\"\${COMMON_FLAGS}\"\nCXXFLAGS=\"\${COMMON_FLAGS}\"\nMAKEOPTS=\"-j3 -l3\"\nACCEPT_LICENSE=\"*\"\n" > /mnt/gentoo/etc/portage/make.conf

cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

#We also can use "arch-chroot /mnt/gentoo" for mounting,
#if using Gentoo's install media

echo "Mounting filesystems for chroot..."
mount --types proc /proc /mnt/gentoo/proc
mount_check "/mnt/gentoo/proc"

mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount_check "/mnt/gentoo/sys"

mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount_check "/mnt/gentoo/dev"

mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
mount_check "/mnt/gentoo/run"

chroot /mnt/gentoo /bin/bash 
source /etc/profile
export PS1="(chroot) ${PS1}"



