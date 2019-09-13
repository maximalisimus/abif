#
#
#
######################################################################
##                                                                  ##
##                 Configuration Functions                          ##
##                                                                  ##
######################################################################

# virtual console keymap
set_keymap() { 
    
    KEYMAPS=""
    for i in $(ls -R /usr/share/kbd/keymaps | grep "map.gz" | sed 's/\.map\.gz//g' | sort); do
        KEYMAPS="${KEYMAPS} ${i} -"
    done
    
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_KeymapTitle" \
    --menu "$_KeymapBody" 20 40 16 ${KEYMAPS} 2>${ANSWER} || prep_menu 
    KEYMAP=$(cat ${ANSWER})
    
    loadkeys $KEYMAP 2>/tmp/.errlog
    check_for_error

    echo -e "KEYMAP=${KEYMAP}\nFONT=${FONT}" > /tmp/vconsole.conf
  }

# Set keymap for X11
 set_xkbmap() {
     
    #XKBMAP_LIST=""
    #keymaps_xkb=("af al am at az ba bd be bg br bt bw by ca cd ch cm cn cz de dk ee es et eu fi fo fr gb ge gh gn gr hr hu ie il in iq ir is it jp ke kg kh kr kz la lk lt lv ma md me mk ml mm mn mt mv ng nl no np pc ph pk pl pt ro rs ru se si sk sn sy tg th tj tm tr tw tz ua us uz vn za")
    
    #for i in ${keymaps_xkb}; do
    #    XKBMAP_LIST="${XKBMAP_LIST} ${i} -"
    #done
    
    #dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_PrepKBLayout " --menu "$_XkbmapBody" 0 0 16 ${XKBMAP_LIST} 2>${ANSWER} || install_graphics_menu
    #XKBMAP=$(cat ${ANSWER} |sed 's/_.*//')
    #echo -e "Section "\"InputClass"\"\nIdentifier "\"system-keyboard"\"\nMatchIsKeyboard "\"on"\"\nOption "\"XkbLayout"\" "\"${XKBMAP}"\"\nEndSection" > /tmp/01-keyboard-layout.conf
 
    #setxkbmap $XKBMAP 2>/tmp/.errlog
    #check_for_error
    if [[ $_is_xkb -eq 0 ]]; then
      
        _switch_xkb=("grp:toggle" "grp:ctrl_shift_toggle" "grp:alt_shift_toggle" "grp:ctrl_alt_toggle" "grp:lwin_toggle" "grp:rwin_toggle" "grp:lctrl_toggle" "grp:rctrl_toggle")
        
        _indicate_xkd=("grp_led:caps" "grp_led:num" "grp_led:scroll")
        
        for i in $(cat $filesdir/modules/xkb-models.conf); do
            _xkb_mdl="${_xkb_mdl} ${i} -"
        done
        
        KEYMAPS=""
        for i in $(ls -R /usr/share/kbd/keymaps | grep "map.gz" | sed 's/\.map.gz//g' | sort); do
            KEYMAPS="${KEYMAPS} ${i} -"
        done
        
        for i in ${KEYMAPS[*]}; do
            _xkb_list="${_xkb_list} ${i} -"
        done    
        
        
        for i in $(cat $filesdir/modules/xkb-variant.conf); do
            _xkb_var="${_xkb_var} ${i} -"
        done
        
        _is_xkb=1
    fi
    
    xkbmodel()
    {
        dialog --default-item 1 --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_xkb_mdl_title" --menu "$_xkb_mdl_body" 0 0 11 ${_xkb_mdl} 2>${ANSWER} || set_xkbmap
        xkb_model=$(cat ${ANSWER})
    }
    xkbvariant()
    {
        dialog --default-item 1 --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_xkb_var_title" --menu "$_xkb_var_body" 0 0 11 ${_xkb_var} 2>${ANSWER} || set_xkbmap
        xkb_variant=$(cat ${ANSWER})
    }
    xkboptions()
    {
        _sw=""
        _ind=""
        dialog --default-item 2 --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_xkb_switch_title" --menu "$_xkb_switch_body" 0 0 8 \
            "1" $"Right Alt" \
            "2" $"Control+Shift" \
            "3" $"Alt+Shift" \
            "4" $"Control+Alt" \
            "5" $"Left Win" \
            "6" $"Right Win" \
            "7" $"Left Control" \
            "8" $"Right Control" 2>${ANSWER}
        var=$(cat ${ANSWER})
        var=$(($var-1))
        _sw=${_switch_xkb[$var]}
        dialog --default-item 2 --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_xkb_indicate_title" --checklist "$_xkb_indicate_body" 0 0 3 \
            "1" "$_indicate_caps_lock" "off" \
            "2" "$_indicate_num_lock" "on" \
            "3" "$_indicate_scroll_lock" "off" 2>${ANSWER}
        if [[ $(cat ${ANSWER}) == "" ]]; then
            xkb_options="$_sw"
        else
            counter=0
            for i in $(cat ${ANSWER}); do
                if [[ $counter -eq 0 ]]; then
                    counter=1
                    _tmp=$(($i-1))
                    _ind=${_indicate_xkd[_tmp]}
                else
                    _tmp=$(($i-1))
                    _ind="${_ind},${_indicate_xkd[_tmp]}"
                fi
            done
            xkb_options="$_sw,$_ind"
        fi
    }
    fine_keyboard_conf()
    {
       # [[ $xkb_layout == "" ]] && _skip=1
        [[ $xkb_model == "" ]] && _skip=1
        [[ $xkb_variant == "" ]] && _skip=1
        [[ $xkb_layout == "" ]] && xkb_layout="${KEYMAP[*]}"
        [[ $xkb_model == "" ]] && xkb_model="pc105"
        [[ $xkb_variant == "" ]] && xkb_variant="qwerty"
        if [[ $_skip == "1" ]]; then
            _xkb_info_body="\n$_inf2\n\n$_inf_l $xkb_layout\n$_inf_m $xkb_model\n$_inf_v $xkb_variant\n$_inf_o $xkb_options\n\n\n"
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_xkb_info_title" --msgbox "$_xkb_info_body" 0 0
            _skip=0
        fi
        echo "# /etc/X11/xorg.conf.d/00-keyboard.conf " > /tmp/01-keyboard-layout.conf
        echo "# Read and parsed by systemd-localed. It's probably wise not to edit this file" >> /tmp/01-keyboard-layout.conf
        echo -e -n "# manually too freely.\n" >> /tmp/01-keyboard-layout.conf
        echo -e -n "Section \"InputClass\"\n" >> /tmp/01-keyboard-layout.conf
        echo -e -n "\tIdentifier \"system-keyboard\"\n" >> /tmp/01-keyboard-layout.conf
        echo -e -n "\tMatchIsKeyboard \"on\"\n" >> /tmp/01-keyboard-layout.conf
        echo -e -n "\tOption \"XkbLayout\" \"$xkb_layout\"\n" >> /tmp/01-keyboard-layout.conf
        echo -e -n "\tOption \"XkbModel\" \"$xkb_model\"\n" >> /tmp/01-keyboard-layout.conf
        echo -e -n "\tOption \"XkbVariant\" \"$xkb_variant\"\n" >> /tmp/01-keyboard-layout.conf
        echo -e -n "\tOption \"XKbOptions\" \"$xkb_options\"\n" >> /tmp/01-keyboard-layout.conf
        echo -e -n "EndSection\n" >> /tmp/01-keyboard-layout.conf
    }
    
    if [[ $SUB_MENU != "set_xkbmap" ]]; then
       SUB_MENU="set_xkbmap"
       HIGHLIGHT_SUB=1
    else
       if [[ $HIGHLIGHT_SUB != 4 ]]; then
          HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
       fi
    fi
    
   dialog --default-item ${HIGHLIGHT_SUB} --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_xkb_menu_title" --menu "$_xkb_menu_body" 0 0 5 \
    "1" "$_xkb_model_menu" \
    "2" "$_xkb_variant_menu" \
    "3" "$_xkb_options_menu" \
    "4" "$_Back" 2>${ANSWER}
    
    HIGHLIGHT_SUB=$(cat ${ANSWER})
    case $(cat ${ANSWER}) in
    "1") dialog --defaultno --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_yesno_xkb_model_title" --yesno "$_yesno_xkb_model_body" 0 0
        if [[ $? -eq 0 ]]; then
            xkbmodel
        else
            xkb_model="pc105"
        fi
         ;;
    "2") dialog --defaultno --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_yesno_variant_title" --yesno "$_yesno_varinant_body" 0 0
        if [[ $? -eq 0 ]]; then
            xkbvariant
        else
            xkb_variant="qwerty"
        fi
        ;;
    "3") dialog --defaultno --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_yesno_options_title" --yesno "$_yesno_options_body" 0 0
        if [[ $? -eq 0 ]]; then
            xkboptions
        else
            xkb_options="grp:ctrl_shift_toggle,grp_led:num"
        fi
        ;;
      *) fine_keyboard_conf 
        prep_menu
         ;;
    esac

    set_xkbmap
}

# locale array generation code adapted from the Manjaro 0.8 installer
set_locale() {
    
	sed -i '/^[a-z]/s/^/#/g' ${MOUNTPOINT}/etc/locale.gen
	
  #LOCALES=""    
  #for i in $(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8); do
  #    LOCALES="${LOCALES} ${i} -"
  #done

  #dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfBseSysLoc " --menu "$_localeBody" 0 0 12 ${LOCALES} 2>${ANSWER} || config_base_menu 
  
  #LOCALE=$(cat ${ANSWER})

  #echo "LANG=\"${LOCALE}\"" > ${MOUNTPOINT}/etc/locale.conf
  #sed -i "s/#${LOCALE}/${LOCALE}/" ${MOUNTPOINT}/etc/locale.gen 2>/tmp/.errlog
  #arch_chroot "locale-gen" >/dev/null 2>>/tmp/.errlog
  #check_for_error
  LOCALES=""    
  for i in $(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8); do
      LOCALES="${LOCALES} ${i} -"
  done

  dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_LocateTitle" --menu "$_localeBody" 0 0 16 ${LOCALES} 2>${ANSWER} || config_base_menu 
  LOCALE=$(cat ${ANSWER})
    
  _KEYMAP=""
   for i in $(ls -R /usr/share/kbd/keymaps | grep "map.gz" | sed 's/\.map.gz//g' | sort); do
    _KEYMAP="${_KEYMAP} ${i} -"
   done

   clear
   
   dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_LocaleConsoleTitle" \
  --menu "$_LocaleConsoleBody" 20 40 16 ${_KEYMAP} 2>${ANSWER} || prep_menu 
   _KEYMAP=$(cat ${ANSWER})
   
  _user_local=$(echo "${LOCALE}" | sed 's/_.*//')
  
  echo "LANG=\"${LOCALE}\"" > ${MOUNTPOINT}/etc/locale.conf
  echo "LC_MESSAGES=\"${LOCALE}\"" >> ${MOUNTPOINT}/etc/locale.conf
  sed -i "s/#${LOCALE}/${LOCALE}/" ${MOUNTPOINT}/etc/locale.gen 2>/tmp/.errlog
  arch_chroot "loadkeys ${_KEYMAP}" >/dev/null 2>>/tmp/.errlog
  echo "LOCALE=\"${LOCALE}\"" > ${MOUNTPOINT}/etc/vconsole.conf
  echo "KEYMAP=\"${_KEYMAP}\"" >> ${MOUNTPOINT}/etc/vconsole.conf
  [[ ${_KEYMAP} =~ ^(ru) ]] && FONT="cyr-sun16"
  if [[ $FONT != "" ]]; then
    echo "FONT=\"${FONT}\"" >> ${MOUNTPOINT}/etc/vconsole.conf
    echo "CONSOLEFONT=\"${FONT}\"" >> ${MOUNTPOINT}/etc/vconsole.conf
    arch_chroot "setfont ${FONT}" >/dev/null 2>>/tmp/.errlog
  else
    echo "FONT=\"cyr-sun16\"" >> ${MOUNTPOINT}/etc/vconsole.conf
    echo "CONSOLEFONT=\"cyr-sun16\"" >> ${MOUNTPOINT}/etc/vconsole.conf
    arch_chroot "setfont cyr-sun16" >/dev/null 2>>/tmp/.errlog
  fi
  echo "USECOLOR=\"yes\"" >> ${MOUNTPOINT}/etc/vconsole.conf
  arch_chroot "locale-gen" >/dev/null 2>>/tmp/.errlog
  arch_chroot "export Lang=\"${LOCALE}\"" >/dev/null 2>>/tmp/.errlog
  [[ ${ZONE[*]} != "" ]] && [[ ${SUBZONE[*]} != "" ]] && echo "TIMEZONE=\"${ZONE}/${SUBZONE}\"" >> ${MOUNTPOINT}/etc/vconsole.conf
  [[ ${_sethwclock[*]} != "" ]] && echo "HARDWARECLOCK=\"${_sethwclock}\"" >> ${MOUNTPOINT}/etc/vconsole.conf
  echo "CONSOLEMAP=\"\"" >> ${MOUNTPOINT}/etc/vconsole.conf
  check_for_error
}

# Set Zone and Sub-Zone
set_timezone() {

    ZONE=""
    for i in $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud); do
      ZONE="$ZONE ${i} -"
    done
    
     dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_TimeZTitle" --menu "$_TimeZBody" 0 0 10 ${ZONE} 2>${ANSWER} || config_base_menu
     ZONE=$(cat ${ANSWER}) 
    
     SUBZONE=""
     for i in $(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "${ZONE}/" | sed "s/${ZONE}\///g" | sort -ud); do
        SUBZONE="$SUBZONE ${i} -"
     done
         
     dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_TimeSubZTitle" --menu "$_TimeSubZBody" 0 0 11 ${SUBZONE} 2>${ANSWER} || config_base_menu
     SUBZONE=$(cat ${ANSWER}) 
    
     dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfBseTimeHC " --yesno "$_TimeZQ ${ZONE}/${SUBZONE}?" 0 0 
     
     if [[ $? -eq 0 ]]; then
        arch_chroot "ln -sf /usr/share/zoneinfo/${ZONE}/${SUBZONE} /etc/localtime" 2>/tmp/.errlog
        check_for_error
     else
        config_base_menu
     fi
}

set_hw_clock() {
    
   #dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfBseTimeHC " --menu "$_HwCBody" 0 0 2 \
    #"utc" "-" "localtime" "-" 2>${ANSWER}   

    #[[ $(cat ${ANSWER}) != "" ]] && arch_chroot "hwclock --systohc --$(cat ${ANSWER})"  2>/tmp/.errlog && check_for_error
	dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_HwCTitle" \
    --menu "$_HwCBody" 0 0 2 \
    "1" "$_HwCUTC" \
    "2" "$_HwLocal" 2>${ANSWER} 

    case $(cat ${ANSWER}) in
        "1") arch_chroot "hwclock --systohc --utc"  2>/tmp/.errlog
            _sethwclock="UTC"
             ;;
        "2") arch_chroot "hwclock --systohc --localtime" 2>/tmp/.errlog
            _sethwclock="localtime"
             ;;
          *) config_base_menu
             ;;
     esac   
     
     check_for_error
}

# Generate the installed system's FSTAB
generate_fstab() {

    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfBseFstab " --menu "$_FstabBody" 0 0 4 \
    "genfstab -p" "$_FstabDevName" \
    "genfstab -L -p" "$_FstabDevLabel" \
    "genfstab -U -p" "$_FstabDevUUID" \
    "genfstab -t PARTUUID -p" "$_FstabDevPtUUID" 2>${ANSWER}
    
    if [[ $(cat ${ANSWER}) != "" ]]; then
        if [[ $SYSTEM == "BIOS" ]] && [[ $(cat ${ANSWER}) == "genfstab -t PARTUUID -p" ]]; then
            dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_FstabErr" 0 0
            generate_fstab
        else
            $(cat ${ANSWER}) ${MOUNTPOINT} > ${MOUNTPOINT}/etc/fstab 2>/tmp/.errlog
            check_for_error
            [[ -f ${MOUNTPOINT}/swapfile ]] && sed -i "s/\\${MOUNTPOINT}//" ${MOUNTPOINT}/etc/fstab
        fi
    fi

}

# Set the installed system's hostname
set_hostname() {

   dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_HostNameTitle" --inputbox "$_HostNameBody" 0 0 "archmid" 2>${ANSWER} || config_base_menu
   HOST_NAME=$(cat ${ANSWER})

   echo "$HOST_NAME" > ${MOUNTPOINT}/etc/hostname
   sed -i "s/$ISO_HOST/$HOST_NAME/g" ${MOUNTPOINT}/etc/hosts
}

# Set the installed system's root password
set_root_password() {

    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfUsrRoot " --clear --insecure --passwordbox "$_PassRtBody" 0 0 2> ${ANSWER} || config_base_menu
    PASSWD=$(cat ${ANSWER})
    
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfUsrRoot " --clear --insecure --passwordbox "$_PassReEntBody" 0 0 2> ${ANSWER} || config_base_menu
    PASSWD2=$(cat ${ANSWER})
    
    if [[ $PASSWD == $PASSWD2 ]]; then 
       echo -e "${PASSWD}\n${PASSWD}" > /tmp/.passwd
       arch_chroot "passwd root" < /tmp/.passwd >/dev/null 2>/tmp/.errlog
       rm /tmp/.passwd
       check_for_error
    else
       dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_PassErrBody" 0 0
       set_root_password
    fi

}

# Create new user(s) for installed system. First user is created by renaming the live account.
# All others are brand new.
create_new_user() {

    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_NUsrTitle " --inputbox "$_NUsrBody" 0 0 "" 2>${ANSWER} || config_base_menu
    USER=$(cat ${ANSWER})
        
    # Loop while user name is blank, has spaces, or has capital letters in it.
    while [[ ${#USER} -eq 0 ]] || [[ $USER =~ \ |\' ]] || [[ $USER =~ [^a-z0-9\ ] ]]; do
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_NUsrTitle " --inputbox "$_NUsrErrBody" 0 0 "" 2>${ANSWER} || config_base_menu
        USER=$(cat ${ANSWER})
    done
        
    # Enter password. This step will only be reached where the loop has been skipped or broken.
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfUsrNew " --clear --insecure --passwordbox "$_PassNUsrBody $USER\n\n" 0 0 2> ${ANSWER} || config_base_menu
    PASSWD=$(cat ${ANSWER}) 
    
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfUsrNew " --clear --insecure --passwordbox "$_PassReEntBody" 0 0 2> ${ANSWER} || config_base_menu
    PASSWD2=$(cat ${ANSWER}) 
    
    # loop while passwords entered do not match.
    while [[ $PASSWD != $PASSWD2 ]]; do
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ErrTitle " --msgbox "$_PassErrBody" 0 0
              
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfUsrNew " --clear --insecure --passwordbox "$_PassNUsrBody $USER\n\n" 0 0 2> ${ANSWER} || config_base_menu
        PASSWD=$(cat ${ANSWER}) 
    
        dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfUsrNew " --clear --insecure --passwordbox "$_PassReEntBody" 0 0 2> ${ANSWER} || config_base_menu
        PASSWD2=$(cat ${ANSWER}) 
    done      
    
    # create new user. This step will only be reached where the password loop has been skipped or broken.  
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " $_ConfUsrNew " --infobox "$_NUsrSetBody" 0 0
    sleep 2
    echo -e "${PASSWD}\n${PASSWD}" > /tmp/.passwd

    # If the first (or only) user account, then change the live account
    if [[ -e ${MOUNTPOINT}/home/$ISO_USER ]]; then
       arch_chroot "passwd $ISO_USER" < /tmp/.passwd >/dev/null 2>>/tmp/.errlog
       check_for_error      
       
       # Convert live account to entered username - group, password, folder, and ownership
       sed -i "s/$ISO_USER/$USER/g" ${MOUNTPOINT}/etc/group 2>>/tmp/.errlog
       sed -i "s/$ISO_USER/$USER/g" ${MOUNTPOINT}/etc/gshadow 2>>/tmp/.errlog
       sed -i "s/$ISO_USER/$USER/g" ${MOUNTPOINT}/etc/passwd 2>>/tmp/.errlog
       sed -i "s/$ISO_USER/$USER/g" ${MOUNTPOINT}/etc/shadow 2>>/tmp/.errlog
       mv ${MOUNTPOINT}/home/$ISO_USER ${MOUNTPOINT}/home/$USER 2>>/tmp/.errlog
       chown -R $USER:users ${MOUNTPOINT}/home/$USER 2>>/tmp/.errlog
        
       # Change sudoers file to require passwords for sudo commands
       sed -i '/%wheel ALL=(ALL) ALL/s/^#//' ${MOUNTPOINT}/etc/sudoers 2>>/tmp/.errlog
       sed -i '/%wheel ALL=(ALL) ALL NOPASSWD: ALL/s/#%wheel ALL=(ALL) ALL NOPASSWD: ALL//' ${MOUNTPOINT}/etc/sudoers 2>>/tmp/.errlog
       check_for_error
    else
       # If the live account has already been changed, create a new user account
       arch_chroot "useradd ${USER} -m -g users -G wheel,storage,power,network,video,audio,lp,games,optical,scanner,floppy,log,rfkill,ftp,http,sys,input -s /bin/bash" 2>/tmp/.errlog   
       arch_chroot "passwd ${USER}" < /tmp/.passwd >/dev/null 2>>/tmp/.errlog  
     
       # Set up basic configuration files and ownership for new account
       arch_chroot "cp -R /etc/skel/ /home/${USER}" 2>>/tmp/.errlog
       arch_chroot "chown -R ${USER}:users /home/${USER}" 2>>/tmp/.errlog
       check_for_error
    fi
       rm /tmp/.passwd
}

run_mkinitcpio() {
    
    clear

    KERNEL=""

    # If LVM and/or LUKS used, add the relevant hook(s)
    ([[ $LVM -eq 1 ]] && [[ $LUKS -eq 0 ]]) && sed -i 's/block filesystems/block lvm2 filesystems/g' ${MOUNTPOINT}/etc/mkinitcpio.conf 2>/tmp/.errlog
    ([[ $LVM -eq 1 ]] && [[ $LUKS -eq 1 ]]) && sed -i 's/block filesystems/block encrypt lvm2 filesystems/g' ${MOUNTPOINT}/etc/mkinitcpio.conf 2>/tmp/.errlog
    ([[ $LVM -eq 0 ]] && [[ $LUKS -eq 1 ]]) && sed -i 's/block filesystems/block encrypt filesystems/g' ${MOUNTPOINT}/etc/mkinitcpio.conf 2>/tmp/.errlog
    check_for_error
    
    arch_chroot "mkinitcpio -P" 2>>/tmp/.errlog
    check_for_error
 
}
