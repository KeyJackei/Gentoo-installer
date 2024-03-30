
#LOCALE_SET="en_US.utf8"
#LOCALE="en_US.UTF-8"

PROFILE="desktop/systemd/mergedusr (stable)"

INSTALL_KERNEL_PATH="/etc/portage/package.use/installkernel"

INSTALL_KERNEL="sys-kernel/installkernel dracut"

#Check error mount
mount_check() {
     if ! mountpoint -q "$1"; then
        echo "Error: Did not mounted $1"
        exit 1
     else
	echo "$1 Success mounted"
     fi
}


mkdir /efi
mount /dev/vda1 /efi
mount_check /dev/vda1 /efi


mkdir --parents /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf

#Checker for any trouble
script_error() {
     logger "gen_inst: Failing out"
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
	env_update
	check_fail
	source /etc/profile

}

#Syncing with portage
emerge_webrsync() {
     logger "Syncing portage"
     emerge-webrsync
     check_fail
}

script_em_sync() {
     logger "Syncing portage"
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
	
	add_use_flag_dracut
	echo "Begining installation kernel"
	emerge --ask sys-kernel/gentoo-kernel
	emerge --depclean
}

install_kernel_code() {
	echo "Begining installation source code of kernel..."
	emerge --ask sys-kernel/gentoo-sources
	
}



emerge_webrsync
    
script_em_sync


profile_no=$(eselect profile list | grep "$(awk '{gsub(/[.()]/, "\\\\&")} END{print $0}' <<< "$PROFILE")" | tail -n1 | cut -d'[' -f2 | cut -d']' -f1)
eselect profile set $profile_no

eselect profile show

conf_locales

add_use_flag_dracut

#locale time generate
#ln -sf ../usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime

#echo "Time has choosen"

#locale language generate. Default: US-UTF-8
#sed -i "/^#${LOCALE}/ s/^#//" /etc/locale.gen

#locale-gen
#echo "locale has generated"











