#!/bin/bash
#
#
######################################################################
##                                                                  ##
##                 Main Interfaces                                  ##
##                                                                  ##
######################################################################

security_menu(){

    if [[ $SUB_MENU != "security_menu" ]]; then
       SUB_MENU="security_menu"
       HIGHLIGHT_SUB=1
    else
       if [[ $HIGHLIGHT_SUB != 4 ]]; then
          HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
       fi
    fi

    dialog --default-item ${HIGHLIGHT_SUB} --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SecMenuTitle " --menu "$_SecMenuBody" 0 0 4 \
    "1" "$_SecJournTitle" \
    "2" "$_SecCoreTitle" \
    "3" "$_SecKernTitle" \
    "4" "$_Back" 2>${ANSWER}

    HIGHLIGHT_SUB=$(cat ${ANSWER})
    case $(cat ${ANSWER}) in
        "1") # systemd-journald
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SecJournTitle " --menu "$_SecJournBody" 0 0 7 \
            "$_Edit" "/etc/systemd/journald.conf" \
            "10M" "SystemMaxUse=10M" \
            "20M" "SystemMaxUse=20M" \
            "50M" "SystemMaxUse=50M" \
            "100M" "SystemMaxUse=100M" \
            "200M" "SystemMaxUse=200M" \
            "$_Disable" "Storage=none" 2>${ANSWER}

            if [[ $(cat ${ANSWER}) != "" ]]; then
                if  [[ $(cat ${ANSWER}) == "$_Disable" ]]; then
                    sed -i "s/#Storage.*\|Storage.*/Storage=none/g" ${MOUNTPOINT}/etc/systemd/journald.conf
                    sed -i "s/SystemMaxUse.*/#&/g" ${MOUNTPOINT}/etc/systemd/journald.conf
                    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SecJournTitle " --infobox "\n$_Done!\n\n" 0 0
                    sleep 2
                elif [[ $(cat ${ANSWER}) == "$_Edit" ]]; then
                    nano ${MOUNTPOINT}/etc/systemd/journald.conf
                else
                    sed -i "s/#Storage.*\|Storage.*/Storage=$(cat ${ANSWER})/g" ${MOUNTPOINT}/etc/systemd/journald.conf
                    sed -i "s/SystemMaxUse.*/#&/g" ${MOUNTPOINT}/etc/systemd/journald.conf
                    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SecJournTitle " --infobox "\n$_Done!\n\n" 0 0
                    sleep 2
                fi
            fi
            ;;
        "2") # core dump
             dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SecCoreTitle " --menu "$_SecCoreBody" 0 0 2 \
            "$_Disable" "Storage=none" "$_Edit" "/etc/systemd/coredump.conf" 2>${ANSWER}
            
            if [[ $(cat ${ANSWER}) == "$_Disable" ]]; then
                sed -i "s/#Storage.*\|Storage.*/Storage=none/g" ${MOUNTPOINT}/etc/systemd/coredump.conf
                dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SecCoreTitle " --infobox "\n$_Done!\n\n" 0 0
                sleep 2
            elif [[ $(cat ${ANSWER}) == "$_Edit" ]]; then
                nano ${MOUNTPOINT}/etc/systemd/coredump.conf
            fi
          ;;
        "3") # Kernel log access 
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SecKernTitle " --menu "\nKernel logs may contain information an attacker can use to identify and exploit kernel vulnerabilities, including sensitive memory addresses.\n\nIf systemd-journald logging has not been disabled, it is possible to create a rule in /etc/sysctl.d/ to disable access to these logs unless using root privilages (e.g. via sudo).\n" 0 0 2 \
            "$_Disable" "kernel.dmesg_restrict = 1" "$_Edit" "/etc/systemd/coredump.conf.d/custom.conf" 2>${ANSWER}
            
            case $(cat ${ANSWER}) in
            "$_Disable")    echo "kernel.dmesg_restrict = 1" > ${MOUNTPOINT}/etc/sysctl.d/50-dmesg-restrict.conf
                            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SecKernTitle " --infobox "\n$_Done!\n\n" 0 0
                            sleep 2 ;;
            "$_Edit")       [[ -e ${MOUNTPOINT}/etc/sysctl.d/50-dmesg-restrict.conf ]] && nano ${MOUNTPOINT}/etc/sysctl.d/50-dmesg-restrict.conf \
                            || dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SeeConfErrTitle " --msgbox "$_SeeConfErrBody1" 0 0 ;;
            esac
             ;;
          *) main_menu
            ;;
    esac
    
    security_menu
}


# Greet the user when first starting the installer
greeting() {

dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_WelTitle $VERSION " --msgbox "$_WelBody" 0 0   

}

# Preparation
prep_menu() {
    
    if [[ $SUB_MENU != "prep_menu" ]]; then
       SUB_MENU="prep_menu"
       HIGHLIGHT_SUB=1
    else
       if [[ $HIGHLIGHT_SUB != 8 ]]; then
          HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
       fi
    fi
    
    dialog --default-item ${HIGHLIGHT_SUB} --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMenuTitle " --menu "$_PrepMenuBody" 0 0 8 \
    "1" "$_KeymapTitle" \
    "2" "$_XkbmapTitle" \
    "3" "$_DevShowOpt" \
    "4" "$_PrepPartDisk" \
    "5" "$_PrepLUKS" \
    "6" "$_PrepLVM $_PrepLVM2" \
    "7" "$_PrepMntPart" \
    "8" "$_Back" 2>${ANSWER}

    HIGHLIGHT_SUB=$(cat ${ANSWER})
    case $(cat ${ANSWER}) in
        "1") set_keymap 
             ;;
        "2") set_xkbmap
            ;;
        "3") show_devices
             ;;
        "4") umount_partitions
             select_device
             create_partitions
             ;;
        "5") luks_menu
            ;;
        "6") lvm_menu
             ;;
        "7") mount_partitions
             ;;        
          *) main_menu
             ;;
    esac
    
    prep_menu   
    
}

# Base Installation
install_root_menu() {

    if [[ $SUB_MENU != "install_base_menu" ]]; then
       SUB_MENU="install_base_menu"
       HIGHLIGHT_SUB=1
    else
       if [[ $HIGHLIGHT_SUB != 4 ]]; then
          HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
       fi
    fi

   dialog --default-item ${HIGHLIGHT_SUB} --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_InstBsMenuTitle" --menu "$_InstBseMenuBody" 0 0 4 \
    "1" "$_InstBse" \
    "2" "$_MMRunMkinit" \
    "3" "$_InstBootldr" \
    "4" "$_Back" 2>${ANSWER}    
    
    HIGHLIGHT_SUB=$(cat ${ANSWER})
    case $(cat ${ANSWER}) in
        "1") install_root
             ;;
        "2") run_mkinitcpio
             ;;
        "3") install_bootloader
             ;;
          *) main_menu
             ;;
     esac
    
    install_root_menu   
}

# Base Configuration
config_base_menu() {
    
    # Set the default PATH variable
    arch_chroot "PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/core_perl" 2>/tmp/.errlog
    check_for_error
    
    if [[ $SUB_MENU != "config_base_menu" ]]; then
       SUB_MENU="config_base_menu"
       HIGHLIGHT_SUB=1
    else
       if [[ $HIGHLIGHT_SUB != 11 ]]; then
          HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
       fi
    fi

    dialog --default-item ${HIGHLIGHT_SUB} --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfBseMenuTitle " --menu "$_ConfBseBody" 0 0 11 \
    "1" "$_ConfBseFstab" \
    "2" "$_ConfBseHost" \
    "3" "$_ConfBseTimeHC" \
    "4" "$_ConfBseSysLoc" \
    "5" "$_ConfUsrRoot" \
    "6" "$_ConfUsrNew" \
	 "7" "$_shell_friendly_menu" \
    "8" "$_SecMenuTitle" \
	 "9" "$_swap_menu_title" \
	 "10" "$_rsrvd_menu_title" \
    "11" "$_Back" 2>${ANSWER}    
    
    HIGHLIGHT_SUB=$(cat ${ANSWER})
    case $(cat ${ANSWER}) in
        "1") generate_fstab 
             ;;
        "2") set_hostname
             ;;
        "3") set_timezone
             set_hw_clock
             ;;        
        "4") set_locale
             ;;
        "5") set_root_password 
            ;;
        "6") create_new_user
            ;;
	"7") shell_friendly_setup
			 ;;
        "8") security_menu
            ;;
	"9") swap_menu
			 ;;
	"10") rsrvd_menu
			 ;;
          *) main_menu
            ;;
    esac
    
    config_base_menu

}

# Edit configs of installed system
edit_configs() {
    
    # Clear the file variables
    FILE=""
    user_list=""
    
    if [[ $SUB_MENU != "edit configs" ]]; then
       SUB_MENU="edit configs"
       HIGHLIGHT_SUB=1
    else
       if [[ $HIGHLIGHT_SUB != 14 ]]; then
          HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
       fi
    fi

   dialog --default-item ${HIGHLIGHT_SUB} --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SeeConfOptTitle " --menu "$_SeeConfOptBody" 0 0 14 \
   "1" "/etc/vconsole.conf" \
   "2" "/etc/locale.conf" \
   "3" "/etc/hostname" \
   "4" "/etc/hosts" \
   "5" "/etc/sudoers" \
   "6" "/etc/mkinitcpio.conf" \
   "7" "/etc/fstab" \
   "8" "/etc/crypttab" \
   "9" "grub/syslinux/systemd-boot" \
   "10" "/etc/lightdm/lightdm-gtk-greeter.conf" \
   "11" "/etc/pacman.conf" \
   "12" "/etc/resolv.conf" \
   "13" "/etc/sysctl.d/00-sysctl.conf" \
   "14" "$_Back" 2>${ANSWER}
    
    HIGHLIGHT_SUB=$(cat ${ANSWER})
    case $(cat ${ANSWER}) in
        "1") [[ -e ${MOUNTPOINT}/etc/vconsole.conf ]] && FILE="${MOUNTPOINT}/etc/vconsole.conf"
             ;;
        "2") [[ -e ${MOUNTPOINT}/etc/locale.conf ]] && FILE="${MOUNTPOINT}/etc/locale.conf" 
             ;;
        "3") [[ -e ${MOUNTPOINT}/etc/hostname ]] && FILE="${MOUNTPOINT}/etc/hostname"
             ;;
        "4") [[ -e ${MOUNTPOINT}/etc/hosts ]] && FILE="${MOUNTPOINT}/etc/hosts"
             ;;
        "5") [[ -e ${MOUNTPOINT}/etc/sudoers ]] && FILE="${MOUNTPOINT}/etc/sudoers"
             ;;
        "6") [[ -e ${MOUNTPOINT}/etc/mkinitcpio.conf ]] && FILE="${MOUNTPOINT}/etc/mkinitcpio.conf"
             ;;
        "7") [[ -e ${MOUNTPOINT}/etc/fstab ]] && FILE="${MOUNTPOINT}/etc/fstab"
             ;;
        "8") [[ -e ${MOUNTPOINT}/etc/crypttab ]] && FILE="${MOUNTPOINT}/etc/crypttab"
             ;;
        "9") [[  $BOOTLOADER == "grub" ]] && FILE="${MOUNTPOINT}/etc/default/grub"
             [[  $BOOTLOADER == "syslinux" ]] && FILE="${MOUNTPOINT}/boot/syslinux/syslinux.cfg"
             if [[  $BOOTLOADER == "systemd-boot" ]]; then
                FILE="${MOUNTPOINT}${UEFI_MOUNT}/loader/loader.conf"     
                files=$(ls ${MOUNTPOINT}${UEFI_MOUNT}/loader/entries/*.conf)
                for i in ${files}; do
                    FILE="$FILE ${i}"
                done
             fi
            ;;
        "10") [[ -e ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf ]] && FILE="${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf" 
            ;;
        "11") [[ -e ${MOUNTPOINT}/etc/pacman.conf ]] && FILE="${MOUNTPOINT}/etc/pacman.conf"
            ;;
		 "12") [[ -e ${MOUNTPOINT}/etc/resolv.conf ]] && FILE="${MOUNTPOINT}/etc/resolv.conf"
			  ;;
		 "13") [[ -e ${MOUNTPOINT}/etc/sysctl.d/00-sysctl.conf ]] && FILE="${MOUNTPOINT}/etc/sysctl.d/00-sysctl.conf"
			  ;;
         *) main_menu
            ;;
     esac
     
    [[ $FILE != "" ]] && geany -i $FILE \
    || dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_SeeConfErrBody" 0 0
    
    edit_configs
}

main_menu() {
    
    if [[ $HIGHLIGHT != 5 ]]; then
       HIGHLIGHT=$(( HIGHLIGHT + 1 ))
    fi

   dialog --default-item ${HIGHLIGHT} --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_MMTitle " \
    --menu "$_MMBody" 0 0 5 \
    "1" "$_PrepMenuTitle" \
    "2" "$_InstBsMenuTitle" \
    "3" "$_ConfBseMenuTitle" \
    "4" "$_SeeConfOptTitle" \
    "5" "$_Done" 2>${ANSWER}

    HIGHLIGHT=$(cat ${ANSWER})
    
    # Depending on the answer, first check whether partition(s) are mounted and whether base has been installed
    if [[ $(cat ${ANSWER}) -eq 2 ]]; then
       check_mount
    fi

    if [[ $(cat ${ANSWER}) -ge 3 ]] && [[ $(cat ${ANSWER}) -le 4 ]]; then
       check_mount
       check_base
    fi
    
    case $(cat ${ANSWER}) in
        "1") prep_menu 
             ;;
        "2") install_root_menu
             ;;
        "3") config_base_menu
             ;;         
        "4") edit_configs
             ;;            
          *) dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --yesno "$_CloseInstBody" 0 0
          
             if [[ $? -eq 0 ]]; then
                echo -n  -e "\e[1;31mPlease wait ...\e[0m"\\r
                # Remove packages to installing-masters
                arch_chroot "pacman -Rns abif-master --noconfirm 2>/dev/null" 2>/dev/null
                wait
                echo -n  -e "\e[1;32mPlease wait ...\e[0m"\\r
                arch_chroot "pacman -Rns aif-master --noconfirm 2>/dev/null" 2>/dev/null
                wait
                echo -n  -e "\e[1;31mPlease wait ...\e[0m"\\r
                arch_chroot "pacman -Rns archlinux-graphical --noconfirm 2>/dev/null" 2>/dev/null
                wait
                echo -n  -e "\e[1;32mPlease wait ...\e[0m"\\r
                arch_chroot "pacman -Rns archlinux-language --noconfirm 2>/dev/null" 2>/dev/null
                wait
                echo -n  -e "\e[1;31mPlease wait ...\e[0m"\\r
                # Remove *.desktop icon on Desktop
                find ${MOUNTPOINT}/ -type d -iname "abif*" -print0 | xargs -0 rm -rf
                wait
                echo -n  -e "\e[1;32mPlease wait ...\e[0m"\\r
                find ${MOUNTPOINT}/ -type d -iname "aif*" -print0 | xargs -0 rm -rf
                wait
                echo -n  -e "\e[1;31mPlease wait ...\e[0m"\\r
                find ${MOUNTPOINT}/ -type d -iname "archlinux-graphical*" -print0 | xargs -0 rm -rf
                wait
                echo -n  -e "\e[1;32mPlease wait ...\e[0m"\\r
                find ${MOUNTPOINT}/ -type d -iname "archlinux-language*" -print0 | xargs -0 rm -rf
                wait
                echo -n  -e "\e[1;31mPlease wait ...\e[0m"\\r
                _user_lists=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
                for k in ${_user_lists[*]}; do
                    find ${MOUNTPOINT}/home/$k/Desktop/ -type f -iname "*.desktop" -print0 | xargs -0 rm -rf
                    wait
                done
                echo -n  -e "\e[1;32mPlease wait ...\e[0m"\\r
                wait
                umount_partitions
                un_us_dlgrc_conf
                clear
                exit 0
             else
                main_menu
             fi
             
             ;;
    esac
    
    main_menu 
    
}
