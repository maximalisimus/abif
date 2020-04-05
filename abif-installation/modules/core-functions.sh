#!/bin/bash
#
######################################################################
##                                                                  ##
##                        Core Functions                            ##
##                                                                  ##
######################################################################

# Add locale on-the-fly and sets source translation file for installer
select_language() {
    
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " Select Language " --menu "\nLanguage / sprache / taal / språk / lingua / idioma / nyelv / língua" 0 0 8 \
    "1" $"English            (en_**)" \
    "2" $"Español            (es_ES)" \
    "3" $"Português          (pt_PT)" \
    "4" $"Français           (fr_FR)" \
    "5" $"Russian            (ru_RU)" \
    "6" $"Italiano           (it_IT)" \
    "7" $"Nederlands         (nl_NL)" \
    "8" $"Magyar             (hu_HU)" 2>${ANSWER}

    case $(cat ${ANSWER}) in
        "1") source "$filesdir"/lang/english.trans
             CURR_LOCALE="en_US.UTF-8"
             ;;
        "2") source "$filesdir"/lang/spanish.trans
             CURR_LOCALE="es_ES.UTF-8"
             ;; 
        "3") source "$filesdir"/lang/portuguese.trans
             CURR_LOCALE="pt_PT.UTF-8"
             ;;     
        "4") source "$filesdir"/lang/french.trans
             CURR_LOCALE="fr_FR.UTF-8"
             ;;  
        "5") source "$filesdir"/lang/russian.trans
             CURR_LOCALE="ru_RU.UTF-8"
             FONT="LatKaCyrHeb-14.psfu"
             ;;
        "6") source "$filesdir"/lang/italian.trans
             CURR_LOCALE="it_IT.UTF-8"
             ;;
        "7") source "$filesdir"/lang/dutch.trans
             CURR_LOCALE="nl_NL.UTF-8"
             ;;
        "8") source "$filesdir"/lang/hungarian.trans
             CURR_LOCALE="hu_HU.UTF-8"
             FONT="lat2-16.psfu"
             ;;
          *) exit 0
             ;;
    esac
        
    # Generate the chosen locale and set the language
    sed -i "s/#${CURR_LOCALE}/${CURR_LOCALE}/" /etc/locale.gen
    locale-gen >/dev/null 2>&1
    export LANG=${CURR_LOCALE}
    [[ $FONT != "" ]] && setfont $FONT
}



# Check user is root, and that there is an active internet connection
# Seperated the checks into seperate "if" statements for readability.
check_requirements() {
    
  dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ChkTitle " --infobox "$_PlsWaitBody" 0 0
  sleep 2
  
  if [[ $(whoami) != "root" ]]; then
     dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_Erritle " --infobox "$_RtFailBody" 0 0
     sleep 2
     exit 1
  fi
  
  # The error log is also cleared, just in case something is there from a previous use of the installer.
  dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ReqMetTitle " --infobox "$_ReqMetBody" 0 0
  sleep 2   
  clear
  echo "" > /tmp/.errlog
}

# Adapted from AIS. Checks if system is made by Apple, whether the system is BIOS or UEFI,
# and for LVM and/or LUKS.
id_system() {
    
    # Apple System Detection
    if [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Inc.' ]] || [[ "$(cat /sys/class/dmi/id/sys_vendor)" == 'Apple Computer, Inc.' ]]; then
      modprobe -r -q efivars || true  # if MAC
    else
      modprobe -q efivarfs            # all others
    fi
    
    # BIOS or UEFI Detection
    if [[ -d "/sys/firmware/efi/" ]]; then
      # Mount efivarfs if it is not already mounted
      if [[ -z $(mount | grep /sys/firmware/efi/efivars) ]]; then
        mount -t efivarfs efivarfs /sys/firmware/efi/efivars
      fi
      SYSTEM="UEFI"
    else
      SYSTEM="BIOS"
    fi
         

}   
 

# Adapted from AIS. An excellent bit of code!
arch_chroot() {
    arch-chroot $MOUNTPOINT /bin/bash -c "${1}"
}  

# If there is an error, display it, clear the log and then go back to the main menu (no point in continuing).
check_for_error() {

 if [[ $? -eq 1 ]] && [[ $(cat /tmp/.errlog | grep -i "error") != "" ]]; then
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$(cat /tmp/.errlog)" 0 0
    echo "" > /tmp/.errlog
    main_menu
 fi
   
}

# Ensure that a partition is mounted
check_mount() {

    if [[ $(lsblk -o MOUNTPOINT | grep ${MOUNTPOINT}) == "" ]]; then
       dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_ErrNoMount" 0 0
       main_menu
    fi

}

# Ensure that Arch has been installed
check_base() {

    if [[ ! -e ${MOUNTPOINT}/etc ]]; then
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_ErrNoBase" 0 0
        main_menu
    fi
    
}

# Simple code to show devices / partitions.
show_devices() {
     lsblk -o NAME,MODEL,TYPE,FSTYPE,SIZE,MOUNTPOINT | grep "disk\|part\|lvm\|crypt\|NAME\|MODEL\|TYPE\|FSTYPE\|SIZE\|MOUNTPOINT" > /tmp/.devlist
     dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_DevShowOpt " --textbox /tmp/.devlist 0 0
}
