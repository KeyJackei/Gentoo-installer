
#LOCALE_SET="en_US.utf8"
#LOCALE="en_US.UTF-8"

PROFILE="desktop/systemd/mergedusr (stable)"

INSTALL_KERNEL_PATH="/etc/portage/package.use/installkernel"

INSTALL_KERNEL="sys-kernel/installkernel dracut"

SYSTEMD_PATH="/etc/portage/package.use/systemd"

SYSTEMD_FLAG="sys-apps/systemd boot
sys-kernel/installkernel systemd-boot"

GRUB_KERNEL="sys-kernel/installkernel grub"


mkdir --parents /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf


#Checker for any trouble
script_error() {
     echo "gen_inst: Failing out"
     umount -l /dev
     umount -l /proc
     exit 1
}

check_fail() {
     if [ \$? -ne 0 ]; then
         script_error;
     else
         echo "gen_inst: command succeeded"
     fi
}

#Updating our environment
env_upd() {
	env-update
	check_fail
	source /etc/profile

}

#Syncing with portage
emerge_webrsync() {
     echo "Syncing portage"
     emerge-webrsync
     check_fail
}

script_em_sync() {
     echo "Syncing portage"
     emerge --sync
     check_fail
}

#Writing locales
conf_locales_gen() {
	echo "Generating locales"
	echo '' > /etc/locales.gen
	
	echo "en_US ISO-8859-1" >> /etc/locales.gen
        echo "en_US.UTF-8 UTF-8" >> /etc/locales.gen

}

#Select locale
conf_locales_select() {
    echo '' > /etc/env.d/02locale
    echo 'LANG="en_US.UTF-8"' >> /etc/env.d/02locale
    echo 'LC_COLLATE="C"' >> /etc/env.d/02locale
}

#Configuration locale
conf_locales() {
	conf_locales_gen
	locale-gen
	check_fail
	
	conf_locales_select
	env_upd
	
}


add_use_flag_dracut() {
	# Check existing
	if [ ! -f "$INSTALL_KERNEL_PATH" ]; then
	    echo "Making $INSTALL_KERNEL_PATH"
	    touch "$INSTALL_KERNEL_PATH"
	fi

	# Writing
	echo "$INSTALL_KERNEL" > "$INSTALL_KERNEL_PATH"

}

install_distr_kernel() {
	
	echo "Begining installation kernel"
	emerge sys-kernel/gentoo-kernel
	emerge --depclean
}

install_kernel_code() {
	echo "Begining installation source code of kernel..."
	emerge sys-kernel/gentoo-sources
	
}

add_use_flag_systemd() {
	if [ ! -f "$SYSTEMD_PATH" ]; then
	    echo "Making $SYSTEMD_PATH"
	    touch "$SYSTEMD_PATH"
	fi

	# Writing
	echo -e "$SYSTEMD_FLAG" > "$SYSTEMD_PATH"

}


emerge_webrsync

emerge --verbose --oneshot app-portage/mirrorselect
mirrorselect -i -o >> /etc/portage/make.conf

emerge --oneshot app-portage/cpuid2cpuflags
cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags


script_em_sync

profile_no=$(eselect profile list | grep "$(awk '{gsub(/[.()]/, "\\\\&")} END{print $0}' <<< "$PROFILE")" | tail -n1 | cut -d'[' -f2 | cut -d']' -f1)
eselect profile set $profile_no

eselect profile show

conf_locales

add_use_flag_dracut

install_distr_kernel

install_kernel_code

eselect kernel set 1

ls -l /usr/src/linux

#Add grub flag
echo "$GRUB_KERNEL" >> "$INSTALL_KERNEL_PATH"

#locale time generate
#ln -sf ../usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime

#echo "Time has choosen"

#locale language generate. Default: US-UTF-8
#sed -i "/^#${LOCALE}/ s/^#//" /etc/locale.gen

#locale-gen
#echo "locale has generated"
