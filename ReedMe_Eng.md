###########################################
#                                         #
#   abif-master script instalation        #
#   offline to Dialog mode on ArchLinux   #
#                                         #
###########################################
 
Creation date: 13.09.2019

Editor used: Notepad++
    end of line: unix
    encoding: UTF-8
    
The starting point of the project: Github: https://github.com/midfingr/archmid-iso.git/airootfs/abif-master/

This script is designed for full-featured installation of the project "ArchISO" - 
Live CD/DVD/USB system ArchLinux in pseudographic mode, using the dialog package.

The script can be used with any distribution ArchLunux supporting: xorg, DM and DE. 
This wizard supports UEFI installation mode when you start ArchLinux in UEFI mode.

How to use this wizard?
There are 2 important conditions to observe:
1) run as superuser
2) have your Live CD/DVD/USB distribution: xorg, LightDM and any DE, for example xfce4

Instead of LighDM, you can use any other one added to your Live distribution.

To do this, make edits to the file "abif-installation/modules/installation-functions.sh" in the following lines:

 Display Manager
arch_chroot "systemctl enable lightdm -f" 2>>/tmp/.errlog
check_for_error

Instead of "lightdm" respectively your display Manager. 

This script can be run from anywhere. 
Enough to make one of the files - ispolnjaemyj and run it directly in console.

$ chmod ugo+x abif-installation/abif

$ sudo sh abif-installation/abif

Then just follow the instructions of the master installation.

P.S.: Pay attention!

Before adding this wizard to your Live distribution
in the file "abif-installation/modules/installer-variables.sh" 
there is a necessary setting.

ISO_USER="liveuser" 

In the line "ISO_USER" you need to record user, 
added to your Live distribution. 
The correctness of the image installation on your hard disk depends on it.

The recommended folder to add this installation wizard to your Live distribution:
airootfs/abif-installation

And its shortcut on the desktop: airootfs/etc/skel/Desktop/install_offline.desktop

If you want to change this location of installation folders and files edit
file "abif-installation/modules/installation-functions.sh" block "Clean up installation".

Also in the above cleaning block, the addition to the Live distribution is taken into account
installation wizard - online (aif-master) and language change wizard " archlinux-language"
c corresponding to them shortcuts to the desktop Live system.

If you do not intend to use the above installation wizard, you can delete these lines.
However, it is not necessary to delete them.
This installation wizard will not change your Live system with the specified strings.


Good luck investing.





