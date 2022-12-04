######################################################################
##                                                                  ##
##                       Setup Functions                            ##
##                                                                  ##
######################################################################

fixed_users_and_groups()
{
	if [[ -e "${ALL_USER_PASSWORDS}" ]]; then
		_all_user_pass=$(cat "${ALL_USER_PASSWORDS}")
		wait
		_user_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
		wait
		for i in ${_user_list[*]}; do
			_pass=$(echo "${_all_user_pass[*]}" | grep -Ei "${i}" | cut -d ':' -f2-9 )
			echo -e "${_pass[*]}\n${_pass[*]}" > "${ONCE_PASSWORDS}"
			arch-chroot /mnt /bin/bash -c "chown -R ${i}:users /home/${i}" < "${ONCE_PASSWORDS}"
			wait
		done
		wait
		rm -rf "${ALL_USER_PASSWORDS}" "${ONCE_PASSWORDS}"
		unset PASSWD
		unset PASSWD2
		wait
	else
		_user_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
		wait
		for i in ${_user_list[*]}; do
			USER="${i}"
			dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_NUsrSetTitle" --clear --insecure --passwordbox "$_PassNUsrBody $USER\n\n" 0 0 2> ${ANSWER}
			wait
			PASSWD=$(cat ${ANSWER}) 
			wait
			echo "${USER}:${PASSWD[*]}" >> "${ALL_USER_PASSWORDS}"
			wait
		done
		wait
		_all_user_pass=$(cat "${ALL_USER_PASSWORDS}")
		wait
		for i in ${_user_list[*]}; do
			_pass=$(echo "${_all_user_pass[*]}" | grep -Ei "${i}" | cut -d ':' -f2-9 )
			echo -e "${_pass[*]}\n${_pass[*]}" > "${ONCE_PASSWORDS}"
			arch-chroot /mnt /bin/bash -c "chown -R ${i}:users /home/${i}" < "${ONCE_PASSWORDS}"
			wait
		done
		wait
		rm -rf "${ALL_USER_PASSWORDS}" "${ONCE_PASSWORDS}"
		unset PASSWD
		unset PASSWD2
		unset USER
		wait
	fi
}

grub_theme_destiny_setup(){
	_grub_theme_name="Destiny"
	wait
	_grub_theme_stp_bd="${_grub_theme_stp_bd_one[*]} ${_grub_theme_name[*]} ${_grub_theme_stp_bd_two[*]}"
	wait
	wget "${_grub_theme_destiny[*]}" -O "${_grub_theme_destiny_pkg[*]}"
	wait
	mkdir -p ${MOUNTPOINT}/boot/grub/themes/
	wait
	tar -C "${MOUNTPOINT}/boot/grub/themes/" -xvzf "${_grub_theme_destiny_pkg[*]}"
	wait
	tar -xvzf "${_grub_theme_destiny_pkg[*]}"
	wait
	mkdir -p "${MOUNTPOINT}/boot/grub/themes/destiny/"
	wait
	cp -Rf "${_grub_theme_destiny_tmp_dir[*]}"/* "${MOUNTPOINT}/boot/grub/themes/destiny/"
	wait
	rm -rf "${_grub_theme_destiny_tmp_dir[*]}" "${_grub_theme_destiny_pkg[*]}"
	wait
	sed -i '/GRUB_TIMEOUT=/c GRUB_TIMEOUT="15"' ${MOUNTPOINT}/etc/default/grub
	sed -i '/GRUB_GFXMODE=/c GRUB_GFXMODE="auto"' ${MOUNTPOINT}/etc/default/grub
	wait
	if [[ -e "${MOUNTPOINT}/boot/grub/themes/destiny/theme.txt" ]]; then
		sed -i '/GRUB_THEME=/c GRUB_THEME="/boot/grub/themes/destiny/theme.txt"' ${MOUNTPOINT}/etc/default/grub
		wait
		arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 2>/tmp/.errlog
		check_for_error
		wait
		dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_grub_theme_stp_ttl" --msgbox "$_grub_theme_stp_bd" 0 0
	fi
}

grub_theme_starfield_setup(){
	_grub_theme_name="Starfield"
	wait
	_grub_theme_stp_bd="${_grub_theme_stp_bd_one[*]} ${_grub_theme_name[*]} ${_grub_theme_stp_bd_two[*]}"
	wait
	wget "${_grub_theme_starfield[*]}" -O "${_grub_theme_starfield_pkg[*]}"
	wait
	mkdir -p ${MOUNTPOINT}/boot/grub/themes/
	wait
	tar -C "${MOUNTPOINT}/boot/grub/themes/" -xvzf "${_grub_theme_starfield_pkg[*]}"
	wait
	tar -xvzf "${_grub_theme_starfield_pkg[*]}"
	wait
	mkdir -p "${MOUNTPOINT}/boot/grub/themes/starfield/"
	wait
	cp -Rf "${_grub_theme_starfield_tmp_dir[*]}"/* "${MOUNTPOINT}/boot/grub/themes/starfield/"
	wait
	rm -rf "${_grub_theme_starfield_tmp_dir[*]}" "${_grub_theme_starfield_pkg[*]}"
	wait
	sed -i '/GRUB_TIMEOUT=/c GRUB_TIMEOUT="15"' ${MOUNTPOINT}/etc/default/grub
	sed -i '/GRUB_GFXMODE=/c GRUB_GFXMODE="auto"' ${MOUNTPOINT}/etc/default/grub
	wait
	if [[ -e "${MOUNTPOINT}/boot/grub/themes/starfield/theme.txt" ]]; then
		sed -i '/GRUB_THEME=/c GRUB_THEME="/boot/grub/themes/starfield/theme.txt"' ${MOUNTPOINT}/etc/default/grub
		wait
		arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg" 2>/tmp/.errlog
		check_for_error
		wait
		dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_grub_theme_stp_ttl" --msgbox "$_grub_theme_stp_bd" 0 0
	fi
}

no_grub_theme_setup(){
	dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_grub_theme_stp_ttl" --msgbox "$_no_grub_theme_stp_bd" 0 0
}

osprober_configuration(){
	if [[ ${prober_detect} == 1 ]]; then
		mkdir -p ${MOUNTPOINT}/etc/default/
		sed -i '/GRUB_DISABLE_OS_PROBER/s/#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' ${MOUNTPOINT}/etc/default/grub
		sed -i '/GRUB_DISABLE_OS_PROBER/s/true/false/' ${MOUNTPOINT}/etc/default/grub
	fi
}

refind_configuration(){
	if [[ ${refind_detect} == 1 ]]; then
		mkdir -p ${MOUNTPOINT}/etc/pacman.d/hooks/
		echo "[Trigger]" > ${MOUNTPOINT}/etc/pacman.d/hooks/refind.hook
		echo "Operation=Upgrade" >> ${MOUNTPOINT}/etc/pacman.d/hooks/refind.hook
		echo "Type=Package" >> ${MOUNTPOINT}/etc/pacman.d/hooks/refind.hook
		echo "Target=refind" >> ${MOUNTPOINT}/etc/pacman.d/hooks/refind.hook
		echo "" >> ${MOUNTPOINT}/etc/pacman.d/hooks/refind.hook
		echo "[Action]" >> ${MOUNTPOINT}/etc/pacman.d/hooks/refind.hook
		echo "Description = Updating rEFInd on ESP" >> ${MOUNTPOINT}/etc/pacman.d/hooks/refind.hook
		echo "When=PostTransaction" >> ${MOUNTPOINT}/etc/pacman.d/hooks/refind.hook
		echo "Exec=/usr/bin/refind-install" >> ${MOUNTPOINT}/etc/pacman.d/hooks/refind.hook
	fi
}

systemdboot_configuration(){
	if [[ ${systemdboot_detect} == 1 ]]; then
		mkdir -p ${MOUNTPOINT}/etc/pacman.d/hooks/
		echo "[Trigger]" > ${MOUNTPOINT}/etc/pacman.d/hooks/systemd-boot.hook
		echo "Type = Package" >> ${MOUNTPOINT}/etc/pacman.d/hooks/systemd-boot.hook
		echo "Operation = Upgrade" >> ${MOUNTPOINT}/etc/pacman.d/hooks/systemd-boot.hook
		echo "Target = systemd" >> ${MOUNTPOINT}/etc/pacman.d/hooks/systemd-boot.hook
		echo "" >> ${MOUNTPOINT}/etc/pacman.d/hooks/systemd-boot.hook
		echo "[Action]" >> ${MOUNTPOINT}/etc/pacman.d/hooks/systemd-boot.hook
		echo "Description = Updating systemd-boot..." >> ${MOUNTPOINT}/etc/pacman.d/hooks/systemd-boot.hook
		echo "When = PostTransaction" >> ${MOUNTPOINT}/etc/pacman.d/hooks/systemd-boot.hook
		echo "Exec = /usr/bin/bootctl update" >> ${MOUNTPOINT}/etc/pacman.d/hooks/systemd-boot.hook
	fi
}

icontheme_configuration(){
	
	dialog --defaultno --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_yn_icontheme_ttl" --yesno "$_yn_icontheme_bd" 0 0

	if [[ $? -eq 0 ]]; then
		wget "${_icontheme_url[*]}" -O "${_icontheme_pkg[*]}"
		wait
		_user_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
		for i in ${_user_list[*]}; do
			mkdir -p ${MOUNTPOINT}/home/"${i}"/.icons/
			wait
			tar -C ${MOUNTPOINT}/home/"${i}"/.icons/ -xvzf "${_icontheme_pkg[*]}"
			wait
		done
		wait
		rm -rf "${_icontheme_pkg[*]}"
		wait
		dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_greeter_ttl" --msgbox "$_icontheme_bd" 0 0
	fi
}

wallpapers_configuration(){
	wget "${_wallpapers_url[*]}" -O "${_wallpapers_pkg[*]}"
	wait
	mkdir -p ${MOUNTPOINT}/usr/share/wallpapers/
	wait
	tar -C "${MOUNTPOINT}/usr/share/wallpapers/" --strip-components=1 -xvzf "${_wallpapers_pkg[*]}" wallpapers/Full-HD/
	wait
	tar -C "${MOUNTPOINT}/usr/share/wallpapers/" --strip-components=1 -xvzf "${_wallpapers_pkg[*]}" wallpapers/Carbon-Mesh/
	wait
	tar -xvzf "${_wallpapers_pkg[*]}"
	wait
	mkdir -p "${MOUNTPOINT}/usr/share/wallpapers"/{Full-HD,Carbon-Mesh}
	wait
	cp -Rf "${_wallpapers_tmp_dir}"/Full-HD/* "${MOUNTPOINT}/usr/share/wallpapers/Full-HD/"
	wait
	cp -Rf "${_wallpapers_tmp_dir}"/Carbon-Mesh/* "${MOUNTPOINT}/usr/share/wallpapers/Carbon-Mesh/"
	wait
	_user_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
	for i in ${_user_list[*]}; do
		mkdir -p "${MOUNTPOINT}/home/${i}/wallpapers/"
		wait
		tar -C "${MOUNTPOINT}/home/${i}/wallpapers/" --strip-components=1 -xvzf "${_wallpapers_pkg[*]}" wallpapers/Full-HD/
		wait
		tar -C "${MOUNTPOINT}/home/${i}/wallpapers/" --strip-components=1 -xvzf "${_wallpapers_pkg[*]}" wallpapers/Carbon-Mesh/
		wait
		mkdir -p "${MOUNTPOINT}/home/${i}/wallpapers"/{Full-HD,Carbon-Mesh}
		wait
		cp -Rf "${_wallpapers_tmp_dir}"/Full-HD/* "${MOUNTPOINT}/home/${i}/wallpapers/Full-HD/"
		wait
		cp -Rf "${_wallpapers_tmp_dir}"/Carbon-Mesh/* "${MOUNTPOINT}/home/${i}/wallpapers/Carbon-Mesh/"
		wait
	done
	wait
	rm -rf "${_wallpapers_tmp_dir}"/  "${_wallpapers_pkg[*]}"
	wait
}

greeter_configuration(){
	if [[ $_greeter_once == "0" ]]; then
		_greeter_once=1
		wallpapers_configuration
		wait
		if [[ -e ${MOUNTPOINT}/usr/share/wallpapers/Carbon-Mesh/carbon_mesh_arch.png  ]]; then
			echo "[greeter]" > ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "theme-name = Adwaita" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "icon-theme-name = Adwaita" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "background = /usr/share/wallpapers/Full-HD/looking-out.jpg" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "default-user-image = #avatar-default-symbolic" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "panel-position = bottom" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo -e -n "indicators = ~spacer;~separator;~session;~separator;~layout;" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo -e -n "~separator;~language;~separator;~a11y;~separator;~power;" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo -e -n "~separator;~spacer;~host;~spacer;~clock;~spacer" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
		else
			echo "[greeter]" > ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "theme-name = Adwaita" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "icon-theme-name = Adwaita" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "background = " >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "default-user-image = #avatar-default-symbolic" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo "panel-position = bottom" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo -e -n "indicators = ~spacer;~separator;~session;~separator;~layout;" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo -e -n "~separator;~language;~separator;~a11y;~separator;~power;" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
			echo -e -n "~separator;~spacer;~host;~spacer;~clock;~spacer" >> ${MOUNTPOINT}/etc/lightdm/lightdm-gtk-greeter.conf
		fi
		wait
		dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_greeter_ttl" --msgbox "$_greeter_bd" 0 0
		wait
	fi
}

fonts_configuration(){
	dialog --defaultno --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_yn_truetype_ttl" --yesno "$_yn_truetype_bd" 0 0

	if [[ $? -eq 0 ]]; then
		wget "${_truetype_url[*]}" -O "${_truetype_pkg[*]}"
		wait
		tar -C ${MOUNTPOINT}/usr/share/fonts/ -xvzf "${_truetype_pkg[*]}"
		wait
		rm -rf "${_truetype_pkg[*]}"
		wait
		dialog --defaultno --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_yn_truetype_ttl" --yesno "$_yn_truetype_bd_two" 0 0
		if [[ $? -eq 0 ]]; then
			arch-chroot $MOUNTPOINT /bin/bash -c "fc-cache –fv" 2>/tmp/.errlog
			wait
			check_for_error
			wait
		fi
	fi
}

multiple_question(){
	if [[ $SYSTEM == "UEFI" ]]; then
		dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title " ${_MntUefiTitle} " --msgbox "${_Mnt_Uefi_Msg}${_refind_yn_body_msg}\n" 0 0
	fi
	wait
	dialog --default-item 2 --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_InstMultipleTitle" \
    --menu "$_InstMultipleBody" 0 0 3 \
 	"1" "${_InstMultiple_msg} Windows/Linux/MacOS" \
	"2" "${_InstMultiple_one}" \
	"3" "$_Back" 2>${ANSWER}	
	variable=($(cat ${ANSWER}))
    case $variable in
        "1") _multiple_system=1
			_multiple_once=1
			dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_InstMultipleTitle" --msgbox "$_multiple_bd_one" 0 0
             ;;
        "2") _multiple_system=0
			_multiple_once=1
			dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_InstMultipleTitle" --msgbox "$_multiple_bd_two" 0 0
             ;;
        "3") prep_menu
             ;;
     esac
}

search_display_manager()
{
	if [[ -e "${MOUNTPOINT}/etc/gdm/" ]]; then
		_gdm_search=$(find "${MOUNTPOINT}/etc/gdm/" -type f -iname "custom.conf" | wc -l)
		wait
		[[ "${_gdm_search[*]}" == "1" ]] && DM="GDM"
	fi
	_lxdm_search=$(find "${MOUNTPOINT}/etc/" -type f -iname "lxdm.conf" | wc -l)
	wait
	_lightdm_search=$(find "${MOUNTPOINT}/etc/" -type f -iname "lightdm.conf" | wc -l)
	wait
	_sddm_search=$(find "${MOUNTPOINT}/etc/" -type f -iname "sddm.conf" | wc -l)
	wait
	_slim_search=$(find "${MOUNTPOINT}/etc/" -type f -iname "slim.conf" | wc -l)
	wait
	[[ "${_lxdm_search[*]}" == "1" ]] && DM="LXDM"
	wait
	[[ "${_lightdm_search[*]}" == "1" ]] && DM="LightDM"
	wait
	[[ "${_sddm_search[*]}" == "1" ]] && DM="SDDM"
	wait
	[[ "${_slim_search[*]}" == "1" ]] && DM="SLiM"
	wait
}

synaptic_installation()
{
	touchpad_detect=$(echo "${_current_pkgs[*]}" | grep -oi "xf86-input-synaptics" | wc -l)
	if [[ ${touchpad_detect[*]} == 1 ]]; then
		cp -f "${MOUNTPOINT}"/usr/share/X11/xorg.conf.d/70-synaptics.conf "${MOUNTPOINT}"/etc/X11/xorg.conf.d/
		echo -e -n "\n\nSection \"InputClass\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\tIdentifier \"touchpad\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\tDriver \"synaptics\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\tMatchIsTouchpad \"on\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"TapButton1\" \"1\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"TapButton2\" \"3\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"VertEdgeScroll\" \"on\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"HorizEdgeScroll\" \"on\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"CircularScrolling\" \"on\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"CircScrollTrigger\" \"2\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"EmulateTwoFingerMinZ\" \"40\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"EmulateTwoFingerMinW\" \"8\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"CoastingSpeed\" \"0\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"FingerLow\" \"30\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"FingerHigh\" \"50\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "\t\tOption \"MaxTapTime\" \"125\"\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
		echo -e -n "EndSection\n\n" >> "${MOUNTPOINT}"/etc/X11/xorg.conf.d/70-synaptics.conf
	fi
}
