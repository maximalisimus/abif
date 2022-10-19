######################################################################
##                                                                  ##
##                   Installer Variables                            ##
##                                                                  ##
######################################################################

# ISO Specific Variables
ISO_HOST="maximalisimus"                            # ISO Host Name
ISO_USER="liveuser"                                # Live user account
VERSION="MAXIMALISIMUS Installation Framework 2.7"     # Installer Name / Version
TRANS_SRC="/abif-master"                            # Dir where translation files are stored

# Create a temporary file to store menu selections
ANSWER="/tmp/.abif"

# Installation
BOOTLOADER="n/a"                                    # Which bootloader has been installed?
KEYMAP="us"                                         # Virtual console keymap. Default is "us"
XKBMAP="us"                                         # X11 keyboard layout. Default is "us"
ZONE=""                                             # For time
SUBZONE=""                                          # For time
LOCALE="en_US.UTF-8"                                # System locale. Default is "en_US.UTF-8"
_h_c=0
_sethwclock=""

# Architecture
ARCHI=$(uname -m)                                   # Display whether 32 or 64 bit system
SYSTEM="Unknown"                                    # Display whether system is BIOS or UEFI. Default is "unknown"
ROOT_PART=""                                        # ROOT partition
UEFI_PART=""                                        # UEFI partition
UEFI_MOUNT=""                                       # UEFI mountpoint
INST_DEV=""                                         # Device where system has been installed
HIGHLIGHT=0                                         # Highlight items for Main Menu
HIGHLIGHT_SUB=0                                     # Highlight items for submenus
SUB_MENU=""                                         # Submenu to be highlighted

# Logical Volume Management
LVM=0                                               # Logical Volume Management Detected?
LVM_SEP_BOOT=0                                      # 1 = Seperate /boot, 2 = seperate /boot & LVM
LVM_VG=""                                           # Name of volume group to create or use
LVM_VG_MB=0                                         # MB remaining of VG
LVM_LV_NAME=""                                      # Name of LV to create or use
LV_SIZE_INVALID=0                                   # Is LVM LV size entered valid?
VG_SIZE_TYPE=""                                     # Is VG in Gigabytes or Megabytes?

# LUKS
LUKS=0                                              # Luks Detected?
LUKS_DEV=""                                         # If encrypted, partition
LUKS_NAME=""                                        # Name given to encrypted partition
LUKS_UUID=""                                        # UUID used for comparison purposes
LUKS_OPT=""                                         # Default or user-defined?

# Installation
MOUNTPOINT="/mnt"                                   # Installation
AIROOTIMG=""                                        # Root image to install
BYPASS="$MOUNTPOINT/bypass/"                        # Root image mountpoint
BTRFS=0                                             # BTRFS used? "1" = btrfs alone, "2" = btrfs + subvolume(s)
MOUNT_OPTS="/tmp/.mnt_opts"                         # Filesystem Mount options
FS_OPTS=""                                          # FS mount options available
CHK_NUM=16                                          # Used for FS mount options checklist length

# Language Support
CURR_LOCALE="en_US.UTF-8"                           # Default Locale
FONT=""                                             # Set new font if necessary

# Edit Files
FILE=""                                             # Which file is to be opened?

# SHELL
_how_shell=$(echo "$SHELL" | rev | cut -d '/' -f1 | rev | tr '[:upper:]' '[:lower:]')
_once_conf_fscr=0                   # once config to windows fonts and screenfetch startup console
_usr_list=""                        # list of user to home folder
_usr_lst_menu=""                    # dialog menu list of user to home folder
_old_shell=""                       # old select shell for seccurity
_scrnf=0                           # Flag to screenfetch question setup
_bool_bash=0                        # bash once screenfetch config
_bool_fish=0                        # fish once screenfetch config
_bsh_stp_once=0                     # Once setup bash
_zsh_stp_once=0                     # Once setup zsh
_fsh_stp_once=0                     # Once setup fish
shll_list=("bash" "zsh" "fish")
shll_lst=""
shll_once=0
shl_menu_select=""
_ugch=""
# Variables of keyboard parameters
_is_xkb=0
_skip=0
_switch_xkb=""
_indicate_xkd=""
_xkb_mdl=""
_xkb_list=""
_xkb_var=""
xkb_model=""
xkb_layout=""
xkb_variant=""
xkb_options=""

# Devices
declare -a _devices                                            # Array scan mnt mount devices variables declare
declare -a _device_menu                                         # Array menu form on scan mnt mount devices variables declare
DEVICES=""                                                     # Array devices to clear
_isreserved=""                                                 # Percentage to setup reserved block count on root
_rsrvd_file="/tmp/rsrvd.nfo"                                     # File information to reserved block count
_tmp_fstab="/tmp/tmp.fstab"                                      # File information on tmp folder to FSTAB
_once_shwram=0                                                 # Once form memory information to mem file

# Multilib, Swappiness
_multilib=0                                                    # Multilib additional repositoryes to qestion
_user_local=""                                                 # Forms User Locale in auto forms on Locale menu
_freefile=""                                                   # File of comand "free -h"
_swappiness=""                                                 # Variable to save parameter swappiness
_mem_file="/tmp/mem.conf"                                       # file of info memory
_mem_msg_file="/tmp/msginfo.nfo"                                 # Information on swappiness
_File_of_Config="/tmp/00-sysctl.conf"                             # Temp configuration swappiness
_real_dir_swpns="${MOUNTPOINT}/etc/sysctl.d/"                      # Real dir to swappiness on config
_real_swappiness="${MOUNTPOINT}/etc/sysctl.d/00-sysctl.conf"         # File of full path swappiness config to install system
_mem_head=""
_memory=""
_mem_2=""

# Network-Manager and Desktop-Manager for autoselect
_network_manager=(dhcpcd connman NetworkManager wicd)
_user_dm=(lxdm lightdm sddm gdm slim)
_dt_nm_count=0
_nm_dt_instll=0

# Color dialog configured
_dlgrc_hm_sts=0
_dlgrc_rs_sts=0
_dlgrc_rr_sts=0
_dlgrc_hm_st="$HOME/.dialogrc"
_dlgrc_rt_st="/etc/dialogrc"
_dlgrc_rt_rt="/root/.dialogrc"
_dlgrc_hm_bp="$filesdir/dlg-home.bp"
_dlgrc_rt_st_bp="$filesdir/dlg-rt-st.bp"
_dlg_rt_rt_bp="$filesdir/dlg-rt-rt.bp"
_dlgrc_mp_etc="${MOUNTPOINT}/etc/dialogrc"
_dlgrc_mp_rt="${MOUNTPOINT}/root/.dialogrc"
_dlgrc_mp_hm_dr="${MOUNTPOINT}/home/"

# User and Groups
_us_gr_users=(adm ftp games http log rfkill sys systemd-journal users uucp wheel)
_us_gr_system=(dbus kmem locate lp mail nobody proc smmsp tty utmp)
_us_gr_presystemd=(audio disk floppy input kvm optical scanner storage video)

# /dialogrc-conf.sh						# Color dialog configuration
# /installer-variables.sh				# list of variables
# /dependences_function.sh				# Dependences for script
# /core-functions.sh					# language, checks
# /configuration-functions.sh			# Keyboard, locale, time zone, FSTAB, mkinitcpio, user controls
# /system-partitioning.sh				# managing partitions, installing the boot
# /luks.sh								# Encryption
# /lvm.sh								# LVM control
# /installation-functions.sh			# system installation functions
# /swappiness-config.sh					# SWAPPINESS
# /devices-config.sh					# tune2fs
# /shell_installer.sh					# SHELL installer functions
# /main-interfaces.sh					# main menu interface

