######################################################################
##                                                                  ##
##                    Installation Functions                        ##
##                                                                  ##
######################################################################  

function detecting_service()
{
	dt_s=$(find /etc/ -type f -iname "$1*" | wc -l)
	wait
	echo ${dt_s[*]}
}
nm_manager_instllng()
{
	arch-chroot $MOUNTPOINT /bin/bash -c "systemctl enable ${network_manager}.service" 2>>/tmp/.errlog
	wait
	check_for_error
	wait
	echo "systemctl enable ${network_manager}.service"
	if [[ ${network_manager} == "${_network_manager[2]}" ]]; then
		arch-chroot $MOUNTPOINT /bin/bash -c "systemctl enable ${network_manager}-dispatcher.service" 2>>/tmp/.errlog
		wait
		check_for_error
		wait
		echo "systemctl enable ${network_manager}-dispatcher.service"
	fi
	_nm_dt_instll=1
	sleep 2
}
slm_instllng()
{
	# Amend the xinitrc file accordingly for all user accounts
	user_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
	for k in ${user_list[@]}; do
		if [[ -n ${MOUNTPOINT}/home/$k/.xinitrc ]]; then
			cp -f ${MOUNTPOINT}/etc/X11/xinit/xinitrc ${MOUNTPOINT}/home/$k/.xinitrc
			wait
			arch-chroot $MOUNTPOINT /bin/bash -c "chown -R ${k}:users /home/${k}"
			wait
		fi
		echo 'exec $1' >> ${MOUNTPOINT}/home/$k/.xinitrc
	done
}
dm_manager_instllng()
{
	clear
	wait
	case $user_dm in
		"${_user_dm[0]}") arch-chroot $MOUNTPOINT /bin/bash -c "systemctl enable ${user_dm}.service" 2>>/tmp/.errlog
						   wait
						   check_for_error
						   wait
						   echo "systemctl enable ${user_dm}.service"
						;;
		"${_user_dm[1]}") arch-chroot $MOUNTPOINT /bin/bash -c "systemctl enable ${user_dm}.service" 2>>/tmp/.errlog
						   wait
						   check_for_error
						   wait
						   echo "systemctl enable ${user_dm}.service"
						;;
		"${_user_dm[2]}") arch-chroot $MOUNTPOINT /bin/bash -c "systemctl enable ${user_dm}.service" 2>>/tmp/.errlog
						   wait
						   check_for_error
						   wait
						   echo "systemctl enable ${user_dm}.service"
						;;
		 "${_user_dm[3]}") arch-chroot $MOUNTPOINT /bin/bash -c "$user_dm --example-config > /etc/${_user_dm[3]}.conf" 2>>/tmp/.errlog
						wait
						check_for_error
						wait
						echo "$user_dm --example-config > /etc/${_user_dm[3]}.conf"
						wait
						arch-chroot $MOUNTPOINT /bin/bash -c "systemctl enable ${user_dm}.service" 2>>/tmp/.errlog
						wait
						check_for_error
						wait
						echo "systemctl enable ${user_dm}.service"
						;;
		 "${_user_dm[4]}") slm_instllng
						wait
						arch-chroot $MOUNTPOINT /bin/bash -c "systemctl enable ${user_dm}.service" 2>>/tmp/.errlog
						wait
						check_for_error
						wait
						echo "systemctl enable ${user_dm}.service"
						;;
	esac
	sleep 2
}

install_root(){

  clear

  # Change installation method depending on use of img or sfs
  if [ -e "/run/archiso/sfs/airootfs/airootfs.img" ]; then
     AIROOTIMG="/run/archiso/sfs/airootfs/airootfs.img"
     mkdir -p ${BYPASS} 2>/tmp/.errlog
     mount ${AIROOTIMG} ${BYPASS} 2>>/tmp/.errlog
     rsync -a --progress ${BYPASS} ${MOUNTPOINT}/ 2>>/tmp/.errlog
     umount -l ${BYPASS}
  else
     AIROOTIMG="/run/archiso/sfs/airootfs/"
     rsync -a --progress ${AIROOTIMG} ${MOUNTPOINT}/ 2>/tmp/.errlog
  fi

  check_for_error
  
  # Keyboard config for vc and x11
  # [[ -f /tmp/vconsole.conf ]] && cp /tmp/vconsole.conf ${MOUNTPOINT}/etc/vconsole.conf 2>>/tmp/.errlog
  [ -f "/tmp/01-keyboard-layout.conf" ] && cp -f "/tmp/01-keyboard-layout.conf" "${MOUNTPOINT}/etc/X11/xorg.conf.d/00-keyboard.conf" 2>>/tmp/.errlog
  wait
  [ -f "/tmp/01-keyboard-layout.conf" ] && sed -i 's/^HOOKS=(base/HOOKS=(base consolefont keymap /' "${MOUNTPOINT}/etc/mkinitcpio.conf"

  # set up kernel for mkiniticpio
  cp "/run/archiso/bootmnt/arch/boot/${ARCHI}/vmlinuz" "${MOUNTPOINT}/boot/vmlinuz-linux" 2>>/tmp/.errlog

  # copy over new mirrorlist
  cp "/etc/pacman.d/mirrorlist" "${MOUNTPOINT}/etc/pacman.d/mirrorlist" 2>>/tmp/.errlog
  
  sed -i 's/\# include \"\/usr\/share\/nano\/\*.nanorc\"/include \"\/usr\/share\/nano\/\*.nanorc\"/' "${MOUNTPOINT}/etc/nanorc" 2>>/tmp/.errlog
  
  # Clean up installation
  rm -rf ${MOUNTPOINT}/vomi 2>>/tmp/.errlog
  rm -rf ${BYPASS} 2>>/tmp/.errlog
  rm -rf ${MOUNTPOINT}/source 2>>/tmp/.errlog
  rm -rf ${MOUNTPOINT}/src 2>>/tmp/.errlog
  rmdir ${MOUNTPOINT}/bypass 2>>/tmp/.errlog
  rmdir ${MOUNTPOINT}/src 2>>/tmp/.errlog
  rmdir ${MOUNTPOINT}/source 2>>/tmp/.errlog
  rm -rf ${MOUNTPOINT}/etc/sudoers.d/g_wheel 2>>/tmp/.errlog
  rm -rf ${MOUNTPOINT}/var/lib/NetworkManager/NetworkManager.state 2>>/tmp/.errlog
  rm -rf ${MOUNTPOINT}/update-abif 2>>/tmp/.errlog
  sed -i 's/.*pam_wheel\.so/#&/' ${MOUNTPOINT}/etc/pam.d/su 2>>/tmp/.errlog
 
  # clean out archiso files from install
  find "${MOUNTPOINT}/usr/lib/initcpio" -type f -name "archiso*" -exec rm '{}' \;

  # root files
  mv /etc/skel/bash_root ${MOUNTPOINT}/root/.bashrc 2>>/tmp/.errlog
  rm -rf ${MOUNTPOINT}/root/.config 2>>/tmp/.errlog
  rm -rf ${MOUNTPOINT}/root/.local 2>>/tmp/.errlog
  rm -r ${MOUNTPOINT}/root/.bash_profle  2>>/tmp/.errlog
  rm -r ${MOUNTPOINT}/root/.xinitrc  2>>/tmp/.errlog
  rm -r ${MOUNTPOINT}/root/.xsession  2>>/tmp/.errlog
  rm -r ${MOUNTPOINT}/home/$ISO_USER/.bash_profile 2>>/tmp/.errlog
  rm -r ${MOUNTPOINT}/home/$ISO_USER/.xinitrc 2>>/tmp/.errlog
  rm -r ${MOUNTPOINT}/home/$ISO_USER/bash_root 2>>/tmp/.errlog
  rm -r ${MOUNTPOINT}/root/bash_root  2>>/tmp/.errlog

  # skel files
  rm -rf ${MOUNTPOINT}/etc/skel/ 2>>/tmp/.errlog

  # restore skel
  mv /skel_default/ ${MOUNTPOINT}/etc/skel  2>>/tmp/.errlog

  # user files
  rm -r ${MOUNTPOINT}/home/$ISO_USER/.bash_profile 2>>/tmp/.errlog
  rm -r ${MOUNTPOINT}/home/$ISO_USER/.xinitrc 2>>/tmp/.errlog
  rm -r ${MOUNTPOINT}/home/$ISO_USER/bash_root 2>>/tmp/.errlog

 # remove geany
 # arch_chroot "pacman -Rns geany --noconfirm"
 # arch_chroot "pacman -Rns xfce4-appfinder --noconfirm"
 
  # systemd
  rm -R ${MOUNTPOINT}/etc/systemd/system/getty@tty1.service.d 2>>/tmp/.errlog
  rm ${MOUNTPOINT}/etc/systemd/system/default.target 2>>/tmp/.errlog
  rm -R ${MOUNTPOINT}/etc/systemd/system/{choose-mirror.service,pacman-init.service} 2>>/tmp/.errlog
  arch_chroot "systemctl disable pacman-init.service choose-mirror.service"

  # Journal
  sed -i 's/volatile/auto/g' ${MOUNTPOINT}/etc/systemd/journald.conf 2>>/tmp/.errlog
 
  # Stop pacman complaining
  arch_chroot "mkdir -p /var/lib/pacman/sync" 2>>/tmp/.errlog
  arch_chroot "touch /var/lib/pacman/sync/{core.db,extra.db,community.db}" 2>>/tmp/.errlog

  # Keyboard config for vc and x11
  # [[ -e /tmp/vconsole.conf ]] && cp /tmp/vconsole.conf ${MOUNTPOINT}/etc/vconsole.conf 2>>/tmp/.errlog
  if [ -e "/tmp/01-keyboard-layout.conf" ]; then
	cp -f "/tmp/01-keyboard-layout.conf" "${MOUNTPOINT}/etc/X11/xorg.conf.d/00-keyboard.conf"  2>>/tmp/.errlog
	wait
	ls "${MOUNTPOINT}/etc/X11/xorg.conf.d/"
	wait
  	sed -i "s/^HOOKS=(base/HOOKS=(base consolefont keymap /" "${MOUNTPOINT}/etc/mkinitcpio.conf" 2>>/tmp/.errlog
	wait
	cat "${MOUNTPOINT}/etc/mkinitcpio.conf" | grep -Ei "HOOKS" | grep -Eiv "\#"
	sleep 2
  fi

  # Network-Manager installing
  nm_manager_instllng
  
  # Desktop-Manager installing
  dm_manager_instllng
  
  check_for_error
}

# Install Bootloader
install_bootloader() {

bios_bootloader() { 
    
   dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_InstBiosBtTitle" --menu "$_InstBiosBtBody" 0 0 3 \
    "grub" "-" "syslinux [MBR]" "-" "syslinux [/]" "-" 2>${ANSWER}
    
    if [[ $(cat ${ANSWER}) == "grub" ]];then
        select_device
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Grub-install " --infobox "$_PlsWaitBody" 0 0
        arch_chroot "grub-install --target=i386-pc --recheck $DEVICE" 2>/tmp/.errlog
        check_for_error
        
        arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 2>/tmp/.errlog
        check_for_error

        # if /boot is LVM (whether using a seperate /boot mount or not), amend grub
        if ( [[ $LVM -eq 1 ]] && [[ $LVM_SEP_BOOT -eq 0 ]] ) || [[ $LVM_SEP_BOOT -eq 2 ]]; then
            sed -i "s/GRUB_PRELOAD_MODULES=\"\"/GRUB_PRELOAD_MODULES=\"lvm\"/g" ${MOUNTPOINT}/etc/default/grub
        fi

        # If encryption used amend grub
        [[ $LUKS_DEV != "" ]] && sed -i "s~GRUB_CMDLINE_LINUX=.*~GRUB_CMDLINE_LINUX=\"$LUKS_DEV\"~g" ${MOUNTPOINT}/etc/default/grub
                
        arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 2>>/tmp/.errlog
        check_for_error
        BOOTLOADER="grub"
        
    elif ([[ $(cat ${ANSWER}) == "syslinux [MBR]" ]] || [[ $(cat ${ANSWER}) == "syslinux [/]" ]]);then
        [[ $(cat ${ANSWER}) == "syslinux [MBR]" ]] && arch_chroot "syslinux-install_update -iam" 2>/tmp/.errlog
        [[ $(cat ${ANSWER}) == "syslinux [/]" ]] && arch_chroot "syslinux-install_update -i" 2>/tmp/.errlog
        check_for_error
             
        # Amend configuration file. First remove all existing entries, then input new ones. 
        sed -i '/^LABEL.*$/,$d' ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
                
        # First the "main" entries
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux.img ]] && echo -e "\n\nLABEL arch\n\tMENU LABEL $ISO_HOST Linux\n\tLINUX ../vmlinuz-linux\n\tAPPEND root=${ROOT_PART} rw\n\tINITRD ../initramfs-linux.img" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux-lts.img ]] && echo -e "\n\nLABEL arch\n\tMENU LABEL $ISO_HOST Linux LTS\n\tLINUX ../vmlinuz-linux-lts\n\tAPPEND root=${ROOT_PART} rw\n\tINITRD ../initramfs-linux-lts.img" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux-grsec.img ]] && echo -e "\n\nLABEL arch\n\tMENU LABEL $ISO_HOST Linux Grsec\n\tLINUX ../vmlinuz-linux-grsec\n\tAPPEND root=${ROOT_PART} rw\n\tINITRD ../initramfs-linux-grsec.img" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux-zen.img ]] && echo -e "\n\nLABEL arch\n\tMENU LABEL $ISO_HOST Linux Zen\n\tLINUX ../vmlinuz-linux-zen\n\tAPPEND root=${ROOT_PART} rw\n\tINITRD ../initramfs-linux-zen.img" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
                
        # Second the "fallback" entries
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux.img ]] && echo -e "\n\nLABEL arch\n\tMENU LABEL $ISO_HOST Linux Fallback\n\tLINUX ../vmlinuz-linux\n\tAPPEND root=${ROOT_PART} rw\n\tINITRD ../initramfs-linux-fallback.img" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux-lts.img ]] && echo -e "\n\nLABEL arch\n\tMENU LABEL $ISO_HOST Linux Fallback LTS\n\tLINUX ../vmlinuz-linux-lts\n\tAPPEND root=${ROOT_PART} rw\n\tINITRD ../initramfs-linux-lts-fallback.img" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux-grsec.img ]] && echo -e "\n\nLABEL arch\n\tMENU LABEL $ISO_HOST Linux Fallback Grsec\n\tLINUX ../vmlinuz-linux-grsec\n\tAPPEND root=${ROOT_PART} rw\n\tINITRD ../initramfs-linux-grsec-fallback.img" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux-zen.img ]] && echo -e "\n\nLABEL arch\n\tMENU LABEL $ISO_HOST Linux Fallbacl Zen\n\tLINUX ../vmlinuz-linux-zen\n\tAPPEND root=${ROOT_PART} rw\n\tINITRD ../initramfs-linux-zen-fallback.img" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
                
        # Third, amend for LUKS
        [[ $LUKS_DEV != "" ]] && sed -i "s~rw~$LUKS_DEV rw~g" ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
                
        # Finally, re-add the "default" entries
        echo -e "\n\nLABEL hdt\n\tMENU LABEL HDT (Hardware Detection Tool)\n\tCOM32 hdt.c32" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        echo -e "\n\nLABEL reboot\n\tMENU LABEL Reboot\n\tCOM32 reboot.c32" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        echo -e "\n\n#LABEL windows\n\t#MENU LABEL Windows\n\t#COM32 chain.c32\n\t#APPEND root=/dev/sda2 rw" >> ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        echo -e "\n\nLABEL poweroff\n\tMENU LABEL Poweroff\n\tCOM32 poweroff.c32" ${MOUNTPOINT}/boot/syslinux/syslinux.cfg
        
        BOOTLOADER="syslinux"
    fi

}

uefi_bootloader() {

    #Ensure again that efivarfs is mounted
    [[ -z $(mount | grep /sys/firmware/efi/efivars) ]] && mount -t efivarfs efivarfs /sys/firmware/efi/efivars

    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_InstUefiBtTitle " --menu "$_InstUefiBtBody" 0 0 2 \
    "grub" "-" "systemd-boot" "/boot" 2>${ANSWER}

    if [[ $(cat ${ANSWER}) == "grub" ]];then

        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Grub-install " --infobox "$_PlsWaitBody" 0 0
        arch_chroot "grub-install --target=x86_64-efi --efi-directory=${UEFI_MOUNT} --bootloader-id=arch_grub --recheck" 2>/tmp/.errlog
                
        # If encryption used amend grub
        [[ $LUKS_DEV != "" ]] && sed -i "s~GRUB_CMDLINE_LINUX=.*~GRUB_CMDLINE_LINUX=\"$LUKS_DEV\"~g" ${MOUNTPOINT}/etc/default/grub
                
        # Generate config file
        arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 2>>/tmp/.errlog
        check_for_error

        # Ask if user wishes to set Grub as the default bootloader and act accordingly
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_InstUefiBtTitle " --yesno "$_SetBootDefBody ${UEFI_MOUNT}/EFI/boot $_SetBootDefBody2" 0 0
            
        if [[ $? -eq 0 ]]; then
            arch_chroot "mkdir ${UEFI_MOUNT}/EFI/boot" 2>/tmp/.errlog
            arch_chroot "cp -r ${UEFI_MOUNT}/EFI/arch_grub/grubx64.efi ${UEFI_MOUNT}/EFI/boot/bootx64.efi" 2>>/tmp/.errlog
            check_for_error
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_InstUefiBtTitle " --infobox "\nGrub $_SetDefDoneBody" 0 0
            sleep 2
        fi
        
        BOOTLOADER="grub"

    elif [[ $(cat ${ANSWER}) == "systemd-boot" ]];then

        arch_chroot "bootctl --path=${UEFI_MOUNT} install" 2>/tmp/.errlog
        check_for_error
                
        # Deal with LVM Root
        [[ $(echo $ROOT_PART | grep "/dev/mapper/") != "" ]] && bl_root=$ROOT_PART \
        || bl_root=$"PARTUUID="$(blkid -s PARTUUID ${ROOT_PART} | sed 's/.*=//g' | sed 's/"//g')
                    
        # Create default config files. First the loader
        echo -e "default  $ISO_HOST\ntimeout  10" > ${MOUNTPOINT}${UEFI_MOUNT}/loader/loader.conf 2>/tmp/.errlog
                
        # Second, the kernel conf files
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux.img ]] && echo -e "title\t$ISO_HOST Linux\nlinux\t/vmlinuz-linux\ninitrd\t/initramfs-linux.img\noptions\troot=${bl_root} rw" > ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/$ISO_HOST.conf
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux-lts.img ]] && echo -e "title\t$ISO_HOST Linux LTS\nlinux\t/vmlinuz-linux-lts\ninitrd\t/initramfs-linux-lts.img\noptions\troot=${bl_root} rw" > ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/$ISO_HOST-lts.conf
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux-grsec.img ]] && echo -e "title\t$ISO_HOST Linux Grsec\nlinux\t/vmlinuz-linux-grsec\ninitrd\t/initramfs-linux-grsec.img\noptions\troot=${bl_root} rw" > ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/$ISO_HOST-grsec.conf
        [[ -e ${MOUNTPOINT}/boot/initramfs-linux-zen.img ]] && echo -e "title\t$ISO_HOST Linux Zen\nlinux\t/vmlinuz-linux-zen\ninitrd\t/initramfs-linux-zen.img\noptions\troot=${bl_root} rw" > ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/$ISO_HOST-zen.conf

        # Finally, amend kernel conf files for LUKS
        sysdconf=$(ls ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/$ISO_HOST*.conf)
        for i in ${sysdconf}; do
            [[ $LUKS_DEV != "" ]] && sed -i "s~rw~$LUKS_DEV rw~g" ${i}
        done
        
        BOOTLOADER="systemd-boot"
    fi

}
    #                                   #
    # Bootloader function begins here   #
    #                                   #
    check_mount
    # Set the default PATH variable
    arch_chroot "PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/core_perl" 2>/tmp/.errlog
    check_for_error

    if [[ $SYSTEM == "BIOS" ]]; then
       bios_bootloader
    else
       uefi_bootloader
    fi
}
