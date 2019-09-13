#
#
#
######################################################################
##                                                                  ##
##             Logical Volume Management Functions                  ##
##                                                                  ##
######################################################################

# LVM Detection.
lvm_detect() {
    
  LVM_PV=$(pvs -o pv_name --noheading 2>/dev/null)
  LVM_VG=$(vgs -o vg_name --noheading 2>/dev/null)
  LVM_LV=$(lvs -o vg_name,lv_name --noheading --separator - 2>/dev/null)
  
    if [[ $LVM_LV != "" ]] && [[ $LVM_VG != "" ]] && [[ $LVM_PV != "" ]]; then
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepLVM " --infobox "$_LvmDetBody" 0 0
        modprobe dm-mod 2>/tmp/.errlog
        check_for_error
        vgscan >/dev/null 2>&1
        vgchange -ay >/dev/null 2>&1
    fi
}

lvm_show_vg(){

    VG_LIST=""
    vg_list=$(lvs --noheadings | awk '{print $2}' | uniq)

    for i in ${vg_list}; do
        VG_LIST="${VG_LIST} ${i} $(vgdisplay ${i} | grep -i "vg size" | awk '{print $3$4}')"
    done

    # If no VGs, no point in continuing
    if [[ $VG_LIST == "" ]]; then
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_LvmVGErr" 0 0
        lvm_menu
    fi

    # Select VG
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepLVM " --menu "$_LvmSelVGBody" 0 0 5 \
    ${VG_LIST} 2>${ANSWER} || lvm_menu
}

# Create Volume Group and Logical Volumes
lvm_create() {

# subroutine to save a lot of repetition.
check_lv_size() {

    LV_SIZE_INVALID=0
    chars=0

    # Check to see if anything was actually entered and if first character is '0'
    ([[ ${#LVM_LV_SIZE} -eq 0 ]] || [[ ${LVM_LV_SIZE:0:1} -eq "0" ]]) && LV_SIZE_INVALID=1

    # If not invalid so far, check for non numberic characters other than the last character
    if [[ $LV_SIZE_INVALID -eq 0 ]]; then
        while [[ $chars -lt $(( ${#LVM_LV_SIZE} - 1 )) ]]; do
            [[ ${LVM_LV_SIZE:chars:1} != [0-9] ]] && LV_SIZE_INVALID=1 && break;
            chars=$(( chars + 1 ))
        done
    fi
    
    # If not invalid so far, check that last character is a M/m or G/g
    if [[ $LV_SIZE_INVALID -eq 0 ]]; then
        LV_SIZE_TYPE=$(echo ${LVM_LV_SIZE:$(( ${#LVM_LV_SIZE} - 1 )):1})
        
        case $LV_SIZE_TYPE in
        "m"|"M"|"g"|"G") LV_SIZE_INVALID=0 ;;
        *) LV_SIZE_INVALID=1 ;;
        esac
        
    fi

    # If not invalid so far, check whether the value is greater than or equal to the LV remaining Size.
    # If not, convert into MB for VG space remaining.      
    if [[ ${LV_SIZE_INVALID} -eq 0 ]]; then
  
        case ${LV_SIZE_TYPE} in
        "G"|"g") if [[ $(( $(echo ${LVM_LV_SIZE:0:$(( ${#LVM_LV_SIZE} - 1 ))}) * 1000 )) -ge ${LVM_VG_MB} ]]; then
                    LV_SIZE_INVALID=1
                 else
                    LVM_VG_MB=$(( LVM_VG_MB - $(( $(echo ${LVM_LV_SIZE:0:$(( ${#LVM_LV_SIZE} - 1 ))}) * 1000 )) ))
                 fi
                 ;;
        "M"|"m") if [[ $(echo ${LVM_LV_SIZE:0:$(( ${#LVM_LV_SIZE} - 1 ))}) -ge ${LVM_VG_MB} ]]; then
                    LV_SIZE_INVALID=1
                 else
                    LVM_VG_MB=$(( LVM_VG_MB - $(echo ${LVM_LV_SIZE:0:$(( ${#LVM_LV_SIZE} - 1 ))}) ))
                 fi
                 ;;
        *) LV_SIZE_INVALID=1
                 ;;
        esac

    fi  

}

    #                           #
    # LVM Create Starts Here    #
    #                           #

    # Prep Variables
    LVM_VG=""
    VG_PARTS=""
    LVM_VG_MB=0

    # Find LVM appropriate partitions.
    INCLUDE_PART='part\|crypt'
    umount_partitions
    find_partitions
    # Amend partition(s) found for use in check list
    PARTITIONS=$(echo $PARTITIONS | sed 's/M\|G\|T/& off/g')
    
    # Name the Volume Group
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG " --inputbox "$_LvmNameVgBody" 0 0 "" 2>${ANSWER} || prep_menu
    LVM_VG=$(cat ${ANSWER})

    # Loop while the Volume Group name starts with a "/", is blank, has spaces, or is already being used
    while [[ ${LVM_VG:0:1} == "/" ]] || [[ ${#LVM_VG} -eq 0 ]] || [[ $LVM_VG =~ \ |\' ]] || [[ $(lsblk | grep ${LVM_VG}) != "" ]]; do
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_ErrTitle" --msgbox "$_LvmNameVgErr" 0 0
              
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG " --inputbox "$_LvmNameVgBody" 0 0 "" 2>${ANSWER} || prep_menu
        LVM_VG=$(cat ${ANSWER})
    done
    
    # Select the partition(s) for the Volume Group
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG " --checklist "$_LvmPvSelBody $_UseSpaceBar" 0 0 7 ${PARTITIONS} 2>${ANSWER} || prep_menu 
    [[ $(cat ${ANSWER}) != "" ]] && VG_PARTS=$(cat ${ANSWER}) || prep_menu
    
    # Once all the partitions have been selected, show user. On confirmation, use it/them in 'vgcreate' command.
    # Also determine the size of the VG, to use for creating LVs for it.
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG " --yesno "$_LvmPvConfBody1${LVM_VG} $_LvmPvConfBody2${VG_PARTS}" 0 0
    
    if [[ $? -eq 0 ]]; then
       dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG " --infobox "$_LvmPvActBody1${LVM_VG}.$_PlsWaitBody" 0 0
       sleep 1
       vgcreate -f ${LVM_VG} ${VG_PARTS} >/dev/null 2>/tmp/.errlog
       check_for_error
       
        # Once created, get size and size type for display and later number-crunching for lv creation
        VG_SIZE=$(vgdisplay $LVM_VG | grep 'VG Size' | awk '{print $3}' | sed 's/\..*//')
        VG_SIZE_TYPE=$(vgdisplay $LVM_VG | grep 'VG Size' | awk '{print $4}')

        # Convert the VG size into GB and MB. These variables are used to keep tabs on space available and remaining
        [[ ${VG_SIZE_TYPE:0:1} == "G" ]] && LVM_VG_MB=$(( VG_SIZE * 1000 )) || LVM_VG_MB=$VG_SIZE
       
       dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG " --msgbox "$_LvmPvDoneBody1 '${LVM_VG}' $_LvmPvDoneBody2 (${VG_SIZE} ${VG_SIZE_TYPE}).\n\n" 0 0
    else
       lvm_menu
    fi

    #
    # Once VG created, create Logical Volumes
    #
    
    # Specify number of Logical volumes to create.
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG " --radiolist "$_LvmLvNumBody1 ${LVM_VG}. $_LvmLvNumBody2" 0 0 9 \
    "1" "-" off "2" "-" off "3" "-" off "4" "-" off "5" "-" off "6" "-" off "7" "-" off "8" "-" off "9 " "-" off 2>${ANSWER}
    
    [[ $(cat ${ANSWER}) == "" ]] && lvm_menu || NUMBER_LOGICAL_VOLUMES=$(cat ${ANSWER})

    # Loop while the number of LVs is greater than 1. This is because the size of the last LV is automatic.
    while [[ $NUMBER_LOGICAL_VOLUMES -gt 1 ]]; do
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG (LV:$NUMBER_LOGICAL_VOLUMES) " --inputbox "$_LvmLvNameBody1" 0 0 "lvol" 2>${ANSWER} || prep_menu
        LVM_LV_NAME=$(cat ${ANSWER})

        # Loop if preceeded with a "/", if nothing is entered, if there is a space, or if that name already exists.
        while [[ ${LVM_LV_NAME:0:1} == "/" ]] || [[ ${#LVM_LV_NAME} -eq 0 ]] || [[ ${LVM_LV_NAME} =~ \ |\' ]] || [[ $(lsblk | grep ${LVM_LV_NAME}) != "" ]]; do
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_LvmLvNameErrBody" 0 0
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG (LV:$NUMBER_LOGICAL_VOLUMES) " --inputbox "$_LvmLvNameBody1" 0 0 "lvol" 2>${ANSWER} || prep_menu
            LVM_LV_NAME=$(cat ${ANSWER})
        done

        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG (LV:$NUMBER_LOGICAL_VOLUMES) " --inputbox "\n${LVM_VG}: ${VG_SIZE}${VG_SIZE_TYPE} (${LVM_VG_MB}MB $_LvmLvSizeBody1).$_LvmLvSizeBody2" 0 0 "" 2>${ANSWER} || prep_menu
        LVM_LV_SIZE=$(cat ${ANSWER})          
        check_lv_size 
          
        # Loop while an invalid value is entered.
        while [[ $LV_SIZE_INVALID -eq 1 ]]; do
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_LvmLvSizeErrBody" 0 0
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG (LV:$NUMBER_LOGICAL_VOLUMES) " --inputbox "\n${LVM_VG}: ${VG_SIZE}${VG_SIZE_TYPE} (${LVM_VG_MB}MB $_LvmLvSizeBody1).$_LvmLvSizeBody2" 0 0 "" 2>${ANSWER} || prep_menu
            LVM_LV_SIZE=$(cat ${ANSWER})          
            check_lv_size
        done
          
        # Create the LV
        lvcreate -L ${LVM_LV_SIZE} ${LVM_VG} -n ${LVM_LV_NAME} 2>/tmp/.errlog
        check_for_error
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG (LV:$NUMBER_LOGICAL_VOLUMES) " --msgbox "\n$_Done\n\nLV ${LVM_LV_NAME} (${LVM_LV_SIZE}) $_LvmPvDoneBody2.\n\n" 0 0
        NUMBER_LOGICAL_VOLUMES=$(( NUMBER_LOGICAL_VOLUMES - 1 ))
    done
    
    # Now the final LV. Size is automatic.      
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG (LV:$NUMBER_LOGICAL_VOLUMES) " --inputbox "$_LvmLvNameBody1 $_LvmLvNameBody2 (${LVM_VG_MB}MB)." 0 0 "lvol" 2>${ANSWER} || prep_menu
    LVM_LV_NAME=$(cat ${ANSWER})

    # Loop if preceeded with a "/", if nothing is entered, if there is a space, or if that name already exists.
    while [[ ${LVM_LV_NAME:0:1} == "/" ]] || [[ ${#LVM_LV_NAME} -eq 0 ]] || [[ ${LVM_LV_NAME} =~ \ |\' ]] || [[ $(lsblk | grep ${LVM_LV_NAME}) != "" ]]; do
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_LvmLvNameErrBody" 0 0
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG (LV:$NUMBER_LOGICAL_VOLUMES) " --inputbox "$_LvmLvNameBody1 $_LvmLvNameBody2 (${LVM_VG_MB}MB)." 0 0 "lvol" 2>${ANSWER} || prep_menu
        LVM_LV_NAME=$(cat ${ANSWER})
    done

    # Create the final LV
    lvcreate -l +100%FREE ${LVM_VG} -n ${LVM_LV_NAME} 2>/tmp/.errlog
    check_for_error
    NUMBER_LOGICAL_VOLUMES=$(( NUMBER_LOGICAL_VOLUMES - 1 ))
    LVM=1
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmCreateVG " --yesno "$_LvmCompBody" 0 0 \
    && show_devices || lvm_menu

}

lvm_del_vg(){

    # Generate list of VGs for selection
    lvm_show_vg
    
    # Ask for confirmation
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmDelVG " --yesno "$_LvmDelQ" 0 0
    
    # if confirmation given, delete
    if [[ $? -eq 0 ]]; then
        vgremove -f $(cat ${ANSWER}) >/dev/null 2>&1
    fi
    
    lvm_menu
}

lvm_del_all(){

    LVM_PV=$(pvs -o pv_name --noheading 2>/dev/null)
    LVM_VG=$(vgs -o vg_name --noheading 2>/dev/null)
    LVM_LV=$(lvs -o vg_name,lv_name --noheading --separator - 2>/dev/null)
    
    # Ask for confirmation
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_LvmDelLV " --yesno "$_LvmDelQ" 0 0
    
    # if confirmation given, delete
    if [[ $? -eq 0 ]]; then
    
        for i in ${LVM_LV}; do
            lvremove -f /dev/mapper/${i} >/dev/null 2>&1
        done

        for i in ${LVM_VG}; do
            vgremove -f ${i} >/dev/null 2>&1
        done

        for i in ${LV_PV}; do
            pvremove -f ${i} >/dev/null 2>&1
        done

    fi
    
    lvm_menu
}

lvm_menu(){

    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepLVM $_PrepLVM2 " --infobox "$_PlsWaitBody" 0 0
    sleep 1
    lvm_detect

    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepLVM $_PrepLVM2 " --menu "$_LvmMenu" 0 0 4 \
    "$_LvmCreateVG" "vgcreate -f, lvcreate -L -n" \
    "$_LvmDelVG" "vgremove -f" \
    "$_LvMDelAll" "lvrmeove, vgremove, pvremove -f" \
    "$_Back" "-" 2>${ANSWER}
    
    case $(cat ${ANSWER}) in
        "$_LvmCreateVG")    lvm_create ;;
        "$_LvmDelVG")       lvm_del_vg ;;
        "$_LvMDelAll")      lvm_del_all ;;
        *)                  prep_menu ;;
    esac


}
