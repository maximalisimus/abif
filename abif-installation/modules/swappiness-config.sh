######################################################################
##                                                                  ##
##                 Swappiness config                                ##
##                                                                  ##
######################################################################

# User installer to swappines parameters config

setswappiness()
{
    codes=""
    xcode=""
    cat /sys/fs/cgroup/memory/memory.swappiness 2> /dev/null 1> /dev/null
    codes=$?
    if [[ $codes == "0" ]]; then
        _swappiness=( $(cat /sys/fs/cgroup/memory/memory.swappiness) )
    elif [[ $codes != "0" ]]; then
        cat /proc/sys/vm/swappiness 2> /dev/null 1> /dev/null
        xcode=$?
        if [[ $xcode == "0" ]]; then
            _swappiness=( $(cat /proc/sys/vm/swappiness) )
        elif [[ $xcode != "0" ]]; then
            _swappiness="40"
        fi
    fi
    unset codes
    unset xcode
}
show_memory()
{
    echo -e -n "\n" > $_mem_file
    count=0
    for letter in "${_freefile[@]}"; do
        if [ "$count" -le 5 ]; then
            echo -e -n "\t$letter" >> $_mem_file
        elif [ "$count" -eq 6 ]; then
            echo -e -n "\n$letter" >> $_mem_file
        elif [ "$count" -eq 10 ]; then
            echo -e -n "\t  $letter" >> $_mem_file
        elif [ "$count" -eq 11 ]; then
            echo -e -n "\t     $letter" >> $_mem_file
        elif [ "$count" -eq 12 ]; then
            echo -e -n "\t    $letter" >> $_mem_file
        elif [ "$count" -le 12 ]; then
            echo -e -n "\t$letter" >> $_mem_file
        elif [ "$count" -eq 13 ]; then
            echo -e -n "\t\n$letter" >> $_mem_file
        elif [ "$count" -le 19 ]; then
            echo -e -n "\t$letter" >> $_mem_file
        fi
        let count+=1
    done
}
swappiness_info()
{
    echo -e -n "\n$_sw_nfo1\n" > $_mem_msg_file
    echo -e -n "$_sw_nfo2\n" >> $_mem_msg_file
    echo -e -n "$_sw_nfo3\n" >> $_mem_msg_file
    echo -e -n "$_sw_nfo4\n" >> $_mem_msg_file
    echo -e -n "$_sw_nfo5\n" >> $_mem_msg_file
    echo -e -n "$_sw_nfo6\n" >> $_mem_msg_file
    echo -e -n "\n$_sw_nfo7\n" >> $_mem_msg_file
    echo -e -n "\n$_sw_nfo8\n" >> $_mem_msg_file
}
show_mem()
{
    _freefile=( $(free -h) )
    IFS=$' '
    show_memory
    setswappiness
    echo -e -n "\n\n$_swap_frequency_info\n" >> $_mem_file
    echo -e -n "swappiness: $_swappiness\n" >> $_mem_file
    swappiness_info
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_msg_swps_title" --textbox $_mem_msg_file 0 0
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_free_info" --textbox $_mem_file 15 100
}
free_mem()
{
    rm -rf $_mem_file
    rm -rf $_mem_msg_file
    rm -rf $_File_of_Config
    unset freefile
    unset IFS
}
set_temp_swpns()
{
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_input_swappiness_title" --inputbox "$_input_swappiness_body" 0 0 "" 2>${ANSWER}

    qst=$?
    case $qst in
        0) _swappiness=$(cat ${ANSWER})
            sysctl vm.swappiness=$_swappiness
            ;;
    esac
}
set_swpns()
{
    dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_input_swappiness_title" --inputbox "$_input_swappiness_body" 0 0 "" 2>${ANSWER}
    _swappiness=$(cat ${ANSWER})
    [ -e ${MOUNTPOINT}/etc/sysctl.d/ ] || mkdir ${MOUNTPOINT}/etc/sysctl.d/
    [[ ${_swappiness[*]} != "" ]] && echo "vm.swappiness=${_swappiness[*]}" > ${MOUNTPOINT}/etc/sysctl.d/00-sysctl.conf
}
swap_menu() {
    
    if [[ $SUB_MENU != "swap_menu" ]]; then
       SUB_MENU="swap_menu"
       HIGHLIGHT_SUB=1
    else
       if [[ $HIGHLIGHT_SUB != 4 ]]; then
          HIGHLIGHT_SUB=$(( HIGHLIGHT_SUB + 1 ))
       fi
    fi
    
   dialog --backtitle "$VERSION - $SYSTEM ($ARCHI)" --title "$_swap_menu_title" \
    --menu "$_swap_menu_body" 0 0 4 \
    "1" "$_sw_menu_info" \
    "2" "$_sw_menu_temp_swpns" \
    "3" "$_sw_menu_swpns" \
    "4" "$_Back"    2>${ANSWER} 
    variable=($(cat ${ANSWER}))
    case $variable in
        "1") show_mem
             ;;
        "2") set_temp_swpns
             ;;
        "3") set_swpns
            ;;
        *) free_mem
            config_base_menu
             ;;
     esac   
     
    swap_menu
}   
