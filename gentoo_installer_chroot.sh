mkdir /efi
mount /dev/vda1 /efi
echo "/efi has mounted"

mkdir --parents /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf

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

emerge_webrsync
    
script_em_sync

# TODO: Check after syncing
profile_no=$(eselect profile list | grep "$(awk '{gsub(/[.()]/, "\\\\&")} END{print $0}' <<< "$PROFILE")" | tail -n1 | cut -d'[' -f2 | cut -d']' -f1)
eselect profile set $profile_no

