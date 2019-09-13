#
#
#
######################################################################
##                                                                  ##
##            System and Partitioning Functions                     ##
##                                                                  ##
######################################################################



# Unmount partitions.
umount_partitions(){
    
  MOUNTED=""
  MOUNTED=$(mount | grep "${MOUNTPOINT}" | awk '{print $3}' | sort -r)
  swapoff -a
  
  for i in ${MOUNTED[@]}; do
      umount $i >/dev/null 2>>/tmp/.errlog
  done
  
  check_for_error

}

# Revised to deal with partion sizes now being displayed to the user
confirm_mount() {
    if [[ $(mount | grep $1) ]]; then   
      dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_MntStatusTitle " --infobox "$_MntStatusSucc" 0 0
      sleep 2
      PARTITIONS=$(echo $PARTITIONS | sed "s~${PARTITION} [0-9]*[G-M]~~" | sed "s~${PARTITION} [0-9]*\.[0-9]*[G-M]~~" | sed s~${PARTITION}$' -'~~)
      NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS - 1 ))
    else
      dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_MntStatusTitle " --infobox "$_MntStatusFail" 0 0
      sleep 2
      prep_menu
    fi
}

# This function does not assume that the formatted device is the Root installation device as 
# more than one device may be formatted. Root is set in the mount_partitions function.
select_device() {
    
    DEVICE=""
    devices_list=$(lsblk -lno NAME,SIZE,TYPE | grep 'disk' | awk '{print "/dev/" $1 " " $2}' | sort -u);
    
    for i in ${devices_list[@]}; do
        DEVICE="${DEVICE} ${i}"
    done
    
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_DevSelTitle " --menu "$_DevSelBody" 0 0 4 ${DEVICE} 2>${ANSWER} || prep_menu
    DEVICE=$(cat ${ANSWER})
 
  }

# Finds all available partitions according to type(s) specified and generates a list 
# of them. This also includes partitions on different devices.
find_partitions() {

    PARTITIONS=""
    NUMBER_PARTITIONS=0 
    partition_list=$(lsblk -lno NAME,SIZE,TYPE | grep $INCLUDE_PART | sed 's/part$/\/dev\//g' | sed 's/lvm$\|crypt$/\/dev\/mapper\//g' | awk '{print $3$1 " " $2}' | sort -u)

    for i in ${partition_list}; do
        PARTITIONS="${PARTITIONS} ${i}"
        NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS + 1 ))
    done
    
    # Double-partitions will be counted due to counting sizes, so fix    
    NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS / 2 ))

    # Deal with partitioning schemes appropriate to mounting, lvm, and/or luks.
    case $INCLUDE_PART in
    'part\|lvm\|crypt') # Deal with incorrect partitioning for main mounting function

        if ([[ $SYSTEM == "UEFI" ]] && [[ $NUMBER_PARTITIONS -lt 2 ]]) || ([[ $SYSTEM == "BIOS" ]] && [[ $NUMBER_PARTITIONS -eq 0 ]]); then
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_PartErrBody" 0 0
            create_partitions
        fi
        ;;
    'part\|crypt') # Ensure there is at least one partition for LVM 
        if [[ $NUMBER_PARTITIONS -eq 0 ]]; then
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_LvmPartErrBody" 0 0
            create_partitions
        fi
        ;;
    'part\|lvm') # Ensure there are at least two partitions for LUKS
        if [[ $NUMBER_PARTITIONS -lt 2 ]]; then
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_LuksPartErrBody" 0 0
            create_partitions
        fi
        ;;
    esac
    
}


# Create partitions.
create_partitions(){

# Securely destroy all data on a given device.
secure_wipe(){
    
    # Warn the user. If they proceed, wipe the selected device.
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PartOptWipe " --yesno "$_AutoPartWipeBody1 ${DEVICE} $_AutoPartWipeBody2" 0 0
    if [[ $? -eq 0 ]]; then
        
        clear
        wipe -Ifre ${DEVICE}
        
        # Alternate dd command - requires pv to be installed
        #dd if=/dev/zero | pv | dd of=${DEVICE} iflag=nocache oflag=direct bs=4096 2>/tmp/.errlog
    else
        create_partitions
    fi
}


# BIOS and UEFI
auto_partition(){
    
    # Provide warning to user
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepPartDisk " --yesno "$_AutoPartBody1 $DEVICE $_AutoPartBody2 $_AutoPartBody3" 0 0
    
    if [[ $? -eq 0 ]]; then
        
        # Find existing partitions (if any) to remove
        parted -s ${DEVICE} print | awk '/^ / {print $1}' > /tmp/.del_parts
    
        for del_part in $(tac /tmp/.del_parts); do
            parted -s ${DEVICE} rm ${del_part} 2>/tmp/.errlog
            check_for_error
        done
 
        # Identify the partition table
        part_table=$(parted -s ${DEVICE} print | grep -i 'partition table' | awk '{print $3}')
 
        # Create partition table if one does not already exist
        ([[ $SYSTEM == "BIOS" ]] && [[ $part_table != "msdos" ]]) && parted -s ${DEVICE} mklabel msdos 2>/tmp/.errlog
        ([[ $SYSTEM == "UEFI" ]] && [[ $part_table != "gpt" ]]) && parted -s ${DEVICE} mklabel gpt 2>/tmp/.errlog
        check_for_error
        
        # Create paritions (same basic partitioning scheme for BIOS and UEFI)
        if [[ $SYSTEM == "BIOS" ]]; then
            parted -s ${DEVICE} mkpart primary ext3 1MiB 513MiB 2>/tmp/.errlog
        else
            parted -s ${DEVICE} mkpart ESP fat32 1MiB 513MiB 2>/tmp/.errlog
        fi
        
        parted -s ${DEVICE} set 1 boot on 2>>/tmp/.errlog
        parted -s ${DEVICE} mkpart primary ext3 513MiB 100% 2>>/tmp/.errlog
        check_for_error

        # Show created partitions
        lsblk ${DEVICE} -o NAME,TYPE,FSTYPE,SIZE > /tmp/.devlist
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "" --textbox /tmp/.devlist 0 0
    else
        create_partitions
    fi

}

    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_PartToolTitle" --menu "$_PartToolBody" 0 0 5 \
    "$_PartOptWipe" "BIOS & UEFI" \
    "$_PartOptAuto" "BIOS & UEFI" \
    "gparted" "BIOS & UEFI" \
    "cfdisk" "BIOS/MBR" \
    "parted" "UEFI/GPT" 2>${ANSWER}

    clear
    # If something selected
    if [[ $(cat ${ANSWER}) != "" ]]; then
        if ([[ $(cat ${ANSWER}) != "$_PartOptWipe" ]] &&  [[ $(cat ${ANSWER}) != "$_PartOptAuto" ]]); then
            $(cat ${ANSWER}) ${DEVICE}
        else
            [[ $(cat ${ANSWER}) == "$_PartOptWipe" ]] && secure_wipe && create_partitions
            [[ $(cat ${ANSWER}) == "$_PartOptAuto" ]] && auto_partition
        fi
    fi
    
}   


# Set static list of filesystems rather than on-the-fly. Partially as most require additional flags, and 
# partially because some don't seem to be viable.
# Set static list of filesystems rather than on-the-fly.
select_filesystem(){

    # prep variables
    fs_opts=""
    CHK_NUM=0

    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_FSTitle " --menu "$_FSBody" 0 0 12 \
    "$_FSSkip" "-" \
    "btrfs" "mkfs.btrfs -f" \
    "ext2" "mkfs.ext2 -q" \
    "ext3" "mkfs.ext3 -q" \
    "ext4" "mkfs.ext4 -q" \
    "f2fs" "mkfs.f2fs" \
    "jfs" "mkfs.jfs -q" \
    "nilfs2" "mkfs.nilfs2 -q" \
    "ntfs" "mkfs.ntfs -q" \
    "reiserfs" "mkfs.reiserfs -q" \
    "vfat" "mkfs.vfat -F32" \
    "xfs" "mkfs.xfs -f" 2>${ANSWER} 
    
    case $(cat ${ANSWER}) in
        "$_FSSkip") FILESYSTEM="$_FSSkip" ;;
        "btrfs")    FILESYSTEM="mkfs.btrfs -f"  
                    CHK_NUM=16
                    fs_opts="autodefrag compress=zlib compress=lzo compress=no compress-force=zlib compress-force=lzo discard noacl noatime nodatasum nospace_cache recovery skip_balance space_cache ssd ssd_spread"
                    modprobe btrfs
                    ;;
        "ext2")     FILESYSTEM="mkfs.ext2 -q" ;;
        "ext3")     FILESYSTEM="mkfs.ext3 -q" ;;
        "ext4")     FILESYSTEM="mkfs.ext4 -q"
                    CHK_NUM=8
                    fs_opts="data=journal data=writeback dealloc discard noacl noatime nobarrier nodelalloc"
                    ;;
        "f2fs")     FILESYSTEM="mkfs.f2fs"
                    fs_opts="data_flush disable_roll_forward disable_ext_identify discard fastboot flush_merge inline_xattr inline_data inline_dentry no_heap noacl nobarrier noextent_cache noinline_data norecovery"
                    CHK_NUM=16
                    modprobe f2fs
                    ;;
        "jfs")      FILESYSTEM="mkfs.jfs -q" 
                    CHK_NUM=4
                    fs_opts="discard errors=continue errors=panic nointegrity"
                    ;;
        "nilfs2")   FILESYSTEM="mkfs.nilfs2 -q" 
                    CHK_NUM=7
                    fs_opts="discard nobarrier errors=continue errors=panic order=relaxed order=strict norecovery"
                    ;;
        "ntfs")     FILESYSTEM="mkfs.ntfs -q" ;;
        "reiserfs") FILESYSTEM="mkfs.reiserfs -q"
                    CHK_NUM=5
                    fs_opts="acl nolog notail replayonly user_xattr"
                    ;;
        "vfat")     FILESYSTEM="mkfs.vfat -F32" ;;
        "xfs")      FILESYSTEM="mkfs.xfs -f" 
                    CHK_NUM=9
                    fs_opts="discard filestreams ikeep largeio noalign nobarrier norecovery noquota wsync"
                    ;;
        *)          prep_menu ;;
    esac
    
    # Warn about formatting!
    if [[ $FILESYSTEM != $_FSSkip ]]; then
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_FSTitle " --yesno "\n$FILESYSTEM $PARTITION\n\n" 0 0
        if [[ $? -eq 0 ]]; then
            ${FILESYSTEM} ${PARTITION} >/dev/null 2>/tmp/.errlog
            check_for_error
        else
            select_filesystem
        fi
    fi


  }
  
mount_partitions() {

# This subfunction allows for special mounting options to be applied for relevant fs's.
# Seperate subfunction for neatness.
mount_opts() {

    FS_OPTS=""
    echo "" > ${MOUNT_OPTS}
    
    for i in ${fs_opts}; do
        FS_OPTS="${FS_OPTS} ${i} - off"
    done

    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $(echo $FILESYSTEM | sed "s/.*\.//g" | sed "s/-.*//g") " --checklist "$_btrfsMntBody" 0 0 $CHK_NUM \
    $FS_OPTS 2>${MOUNT_OPTS}
    
    # Now clean up the file
    sed -i 's/ /,/g' ${MOUNT_OPTS}
    sed -i '$s/,$//' ${MOUNT_OPTS}

    # If mount options selected, confirm choice 
    if [[ $(cat ${MOUNT_OPTS}) != "" ]]; then
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_MntStatusTitle " --yesno "\n${_btrfsMntConfBody}$(cat ${MOUNT_OPTS})\n" 10 75
        [[ $? -eq 1 ]] && mount_opts
    fi 
   
}

# Subfunction to save repetition of code
mount_current_partition(){
    
    # Make the mount directory
    mkdir -p ${MOUNTPOINT}${MOUNT} 2>/tmp/.errlog
    
    # Get mounting options for appropriate filesystems
    [[ $fs_opts != "" ]] && mount_opts
        
    # Use special mounting options if selected, else standard mount
    if [[ $(cat ${MOUNT_OPTS}) != "" ]]; then
        mount -o $(cat ${MOUNT_OPTS}) ${PARTITION} ${MOUNTPOINT}${MOUNT} 2>>/tmp/.errlog
    else
        mount ${PARTITION} ${MOUNTPOINT}${MOUNT} 2>>/tmp/.errlog
    fi
    
    check_for_error
    confirm_mount ${MOUNTPOINT}${MOUNT}

    # Identify if mounted partition is type "crypt" (LUKS on LVM, or LUKS alone)
    if [[ $(lsblk -lno TYPE ${PARTITION} | grep "crypt") != "" ]]; then

        # cryptname for bootloader configuration either way
        LUKS=1
        LUKS_NAME=$(echo ${PARTITION} | sed "s~^/dev/mapper/~~g")

        # Check if LUKS on LVM (parent = lvm /dev/mapper/...) 
        cryptparts=$(lsblk -lno NAME,FSTYPE,TYPE | grep "lvm" | grep -i "crypto_luks" | uniq | awk '{print "/dev/mapper/"$1}')
        for i in ${cryptparts}; do
            if [[ $(lsblk -lno NAME ${i} | grep $LUKS_NAME) != "" ]]; then
                LUKS_DEV="$LUKS_DEV cryptdevice=${i}:$LUKS_NAME"
                LVM=1
                break;
            fi
        done
        
        # Check if LUKS alone (parent = part /dev/...)
        cryptparts=$(lsblk -lno NAME,FSTYPE,TYPE | grep "part" | grep -i "crypto_luks" | uniq | awk '{print "/dev/"$1}')
        for i in ${cryptparts}; do
            if [[ $(lsblk -lno NAME ${i} | grep $LUKS_NAME) != "" ]]; then
                LUKS_UUID=$(lsblk -lno UUID,TYPE,FSTYPE ${i} | grep "part" | grep -i "crypto_luks" | awk '{print $1}')
                LUKS_DEV="$LUKS_DEV cryptdevice=UUID=$LUKS_UUID:$LUKS_NAME"
                break;
            fi
        done
    
    # If LVM logical volume....
    elif [[ $(lsblk -lno TYPE ${PARTITION} | grep "lvm") != "" ]]; then
        LVM=1
        
        # First get crypt name (code above would get lv name)
        cryptparts=$(lsblk -lno NAME,TYPE,FSTYPE | grep "crypt" | grep -i "lvm2_member" | uniq | awk '{print "/dev/mapper/"$1}')
        for i in ${cryptparts}; do
            if [[ $(lsblk -lno NAME ${i} | grep $(echo $PARTITION | sed "s~^/dev/mapper/~~g")) != "" ]]; then
                LUKS_NAME=$(echo ${i} | sed s~/dev/mapper/~~g)
                break;
            fi
        done
        
        # Now get the device (/dev/...) for the crypt name
        cryptparts=$(lsblk -lno NAME,FSTYPE,TYPE | grep "part" | grep -i "crypto_luks" | uniq | awk '{print "/dev/"$1}')
        for i in ${cryptparts}; do
            if [[ $(lsblk -lno NAME ${i} | grep $LUKS_NAME) != "" ]]; then
                # Create UUID for comparison
                LUKS_UUID=$(lsblk -lno UUID,TYPE,FSTYPE ${i} | grep "part" | grep -i "crypto_luks" | awk '{print $1}')
                
                # Check if not already added as a LUKS DEVICE (i.e. multiple LVs on one crypt). If not, add.
                if [[ $(echo $LUKS_DEV | grep $LUKS_UUID) == "" ]]; then
                    LUKS_DEV="$LUKS_DEV cryptdevice=UUID=$LUKS_UUID:$LUKS_NAME"
                    LUKS=1
                fi
                
                break;
            fi
        done
    fi

    
}

# Seperate function due to ability to cancel
make_swap(){

    # Ask user to select partition or create swapfile
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart " --menu "$_SelSwpBody" 0 0 7 "$_SelSwpNone" $"-" "$_SelSwpFile" $"-" ${PARTITIONS} 2>${ANSWER} || prep_menu  
    
    if [[ $(cat ${ANSWER}) != "$_SelSwpNone" ]]; then    
        PARTITION=$(cat ${ANSWER})
    
        if [[ $PARTITION == "$_SelSwpFile" ]]; then
            total_memory=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}' | sed 's/\..*//')
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SelSwpFile " --inputbox "\nM = MB, G = GB\n" 9 30 "${total_memory}M" 2>${ANSWER} || make_swap
            m_or_g=$(cat ${ANSWER})
    
            while [[ $(echo ${m_or_g: -1} | grep "M\|G") == "" ]]; do
                dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SelSwpFile " --msgbox "\n$_SelSwpFile $_ErrTitle: M = MB, G = GB\n\n" 0 0
                dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_SelSwpFile " --inputbox "\nM = MB, G = GB\n" 9 30 "${total_memory}M" 2>${ANSWER} || make_swap
                m_or_g=$(cat ${ANSWER})
            done

            fallocate -l ${m_or_g} ${MOUNTPOINT}/swapfile 2>/tmp/.errlog
            chmod 600 ${MOUNTPOINT}/swapfile 2>>/tmp/.errlog
            mkswap ${MOUNTPOINT}/swapfile 2>>/tmp/.errlog
            swapon ${MOUNTPOINT}/swapfile 2>>/tmp/.errlog
            check_for_error
            
        else # Swap Partition
            # Warn user if creating a new swap
            if [[ $(lsblk -o FSTYPE  ${PARTITION} | grep -i "swap") != "swap" ]]; then
                dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart " --yesno "\nmkswap ${PARTITION}\n\n" 0 0
                [[ $? -eq 0 ]] && mkswap ${PARTITION} >/dev/null 2>/tmp/.errlog || mount_partitions
            fi
            # Whether existing to newly created, activate swap
            swapon  ${PARTITION} >/dev/null 2>>/tmp/.errlog
            check_for_error
            # Since a partition was used, remove that partition from the list
            PARTITIONS=$(echo $PARTITIONS | sed "s~${PARTITION} [0-9]*[G-M]~~" | sed "s~${PARTITION} [0-9]*\.[0-9]*[G-M]~~" | sed s~${PARTITION}$' -'~~)
            NUMBER_PARTITIONS=$(( NUMBER_PARTITIONS - 1 ))
        fi
    fi

}
    ####                                ####
    #### MOUNTING FUNCTION BEGINS HERE  ####
    ####                                ####

    # prep variables
    MOUNT=""
    LUKS_NAME=""
    LUKS_DEV=""
    LUKS_UUID=""
    LUKS=0
    LVM=0
    
    # Warn users that they CAN mount partitions without formatting them!
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart " --msgbox "$_WarnMount1 '$_FSSkip' $_WarnMount2" 0 0

    # LVM Detection. If detected, activate.
    lvm_detect

    # Ensure partitions are unmounted (i.e. where mounted previously), and then list available partitions
    INCLUDE_PART='part\|lvm\|crypt'
    umount_partitions
    find_partitions
    
    # Identify and mount root
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart " --menu "$_SelRootBody" 0 0 7 ${PARTITIONS} 2>${ANSWER} || prep_menu
    PARTITION=$(cat ${ANSWER})
    ROOT_PART=${PARTITION}
    
    # Format with FS (or skip)
    select_filesystem
        
    # Make the directory and mount. Also identify LUKS and/or LVM
    mount_current_partition

    # Identify and create swap, if applicable
    make_swap
    
    # Extra Step for VFAT UEFI Partition. This cannot be in an LVM container.
    if [[ $SYSTEM == "UEFI" ]]; then
    
       dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart " --menu "$_SelUefiBody" 0 0 7 ${PARTITIONS} 2>${ANSWER} || prep_menu  
       PARTITION=$(cat ${ANSWER})
       UEFI_PART=${PARTITION}
       
       # If it is already a fat/vfat partition...
       if [[ $(fsck -N $PARTITION | grep fat) ]]; then
          dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart " --yesno "$_FormUefiBody $PARTITION $_FormUefiBody2" 0 0 && mkfs.vfat -F32 ${PARTITION} >/dev/null 2>/tmp/.errlog
       else 
          mkfs.vfat -F32 ${PARTITION} >/dev/null 2>/tmp/.errlog
       fi
       check_for_error
             
       # Inform users of the mountpoint options and consequences       
       dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart " --menu "$_MntUefiBody"  0 0 2 \
       "/boot" "systemd-boot"\
       "/boot/efi" "-" 2>${ANSWER}
           
       [[ $(cat ${ANSWER}) != "" ]] && UEFI_MOUNT=$(cat ${ANSWER}) || prep_menu
       
       mkdir -p ${MOUNTPOINT}${UEFI_MOUNT} 2>/tmp/.errlog
       mount ${PARTITION} ${MOUNTPOINT}${UEFI_MOUNT} 2>>/tmp/.errlog
       check_for_error
       confirm_mount ${MOUNTPOINT}${UEFI_MOUNT}           
    fi
    
    # All other partitions
    while [[ $NUMBER_PARTITIONS > 0 ]]; do 
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart " --menu "$_ExtPartBody" 0 0 7 "$_Done" $"-" ${PARTITIONS} 2>${ANSWER} || prep_menu 
        PARTITION=$(cat ${ANSWER})
             
        if [[ $PARTITION == $_Done ]]; then
            break;
        else
            MOUNT=""
            select_filesystem
                 
            # Ask user for mountpoint. Don't give /boot as an example for UEFI systems!
            [[ $SYSTEM == "UEFI" ]] && MNT_EXAMPLES="/home\n/var" || MNT_EXAMPLES="/boot\n/home\n/var"
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart $PARTITON " --inputbox "$_ExtPartBody1$MNT_EXAMPLES\n" 0 0 "/" 2>${ANSWER} || prep_menu
            MOUNT=$(cat ${ANSWER})
                
            # loop while the mountpoint specified is incorrect (is only '/', is blank, or has spaces). 
            while [[ ${MOUNT:0:1} != "/" ]] || [[ ${#MOUNT} -le 1 ]] || [[ $MOUNT =~ \ |\' ]]; do
                # Warn user about naming convention
                dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_ExtErrBody" 0 0
                # Ask user for mountpoint again
                dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepMntPart $PARTITON " --inputbox "$_ExtPartBody1$MNT_EXAMPLES\n" 0 0 "/" 2>${ANSWER} || prep_menu
                MOUNT=$(cat ${ANSWER})                     
            done

            # Create directory and mount.
            mount_current_partition
                
            # Determine if a seperate /boot is used. 0 = no seperate boot, 1 = seperate non-lvm boot, 
            # 2 = seperate lvm boot. For Grub configuration
            if  [[ $MOUNT == "/boot" ]]; then
                [[ $(lsblk -lno TYPE ${PARTITION} | grep "lvm") != "" ]] && LVM_SEP_BOOT=2 || LVM_SEP_BOOT=1
            fi
                
        fi
    done
}   
