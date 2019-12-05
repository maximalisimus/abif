#!/bin/bash
#
﻿######################################################################
##                                                                  ##
##                 SHELL SETUP                                      ##
##                                                                  ##
######################################################################

# SHELL user installer

select_install_shell()
{
    # Select dialog shell
    dialog --default-item ${HIGHLIGHT_SUB} --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_select_shell_menu_ttl" --menu "$_select_shell_menu_bd $1\n" 0 0 3 \
    "1" $"BASH" \
    "2" $"ZSH" \
    "3" $"FISH" 2>${ANSWER}
    variable=($(cat ${ANSWER}))
    case $variable in 
        "1") arch-chroot $MOUNTPOINT /bin/bash -c "chsh -s /bin/bash $1" 2>/tmp/.errlog
            ;;
        "2") arch-chroot $MOUNTPOINT /bin/bash -c "chsh -s /usr/bin/zsh $1" 2>/tmp/.errlog
            ;;
        "3") arch-chroot $MOUNTPOINT /bin/bash -c "chsh -s /usr/bin/fish $1" 2>/tmp/.errlog
            ;;
    esac
    check_for_error
}
shell_friendly_setup()
{
    if [[ $_once_conf_fscr == "0" ]]; then
        _once_conf_fscr=1
		[[ -e ${MOUNTPOINT}/etc/fish/config.fish ]] && echo "alias ls='ls --color=auto'" >> ${MOUNTPOINT}/etc/fish/config.fish
		sed -i 's/PS1=/#PS1=/' ${MOUNTPOINT}/etc/bash.bashrc
		echo "alias ls='ls --color=auto'" >> ${MOUNTPOINT}/etc/bash.bashrc
		echo "PS1='\[\e[0;32m\]\u\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\\$\[\e[m\] \[\e[1;37m\]'" >> ${MOUNTPOINT}/etc/bash.bashrc
        _usr_list=$(ls ${MOUNTPOINT}/home/ | sed "s/lost+found//")
        _usr_lst_menu=""
        for i in ${_usr_list[*]}; do
            _usr_lst_menu="${_usr_lst_menu} $i - on"
			[[ -e ${MOUNTPOINT}/home/$i/.zshrc ]] || echo "alias ls='ls --color=auto'" >> ${MOUNTPOINT}/home/$i/.zshrc
        done
		echo "alias ls='ls --color=auto'" >> ${MOUNTPOINT}/root/.zshrc
        _usr_lst_menu="${_usr_lst_menu} root - off"
    fi
    # Checklist dialog user
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_menu_ch_usr_ttl" --checklist "$_menu_ch_usr_bd" 0 0 16 ${_usr_lst_menu} 2>${ANSWER}
    _ch_usr=$(cat ${ANSWER})
	if [[ ${_ch_usr[*]} != "" ]]; then
        for i in ${_ch_usr[*]}; do
            select_install_shell "$i"
        done
	fi
}
