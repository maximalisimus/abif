# abif-master

****************************

abif-master - Bash script for installing the ArchISO system, which is running as a Live CD/DVD/USB, on a computer.

abif-master - Bash скрипт для установки системы ArchISO, которая запущена как Live CD/DVD/USB, на компьютер.

<img src="https://raw.githubusercontent.com/maximalisimus/abif-master/master/image/abif-image.jpg"  height="400">

#   offline to Dialog mode on ArchLinux
 
Имя автора: maximalisimus
E-Mail: maximalis171091@yandex.ru
 
Дата создания: 13.09.2019
    
Начальная точка проекта: Github: https://github.com/midfingr/archmid-iso.git/airootfs/abif-master/

Данный скрипт предназначен для установки проекта "ArchISO" - 
Live CD/DVD/USB системы ArchLinux в псевдографическом режиме, используя пакет dialog.

Скрипт можно использовать с любым дистрибутивом ArchLunux, поддерживающим: xorg, DM и DE. 
Данный мастер поддерживает UEFI режим установки при запуске системы ArchLinux в режиме UEFI.

Как пользоваться данным мастером?
Необходимо соблюдать 2 важных условий:
1) запуск из под суперпользователя
2) Наличие в вашем Live CD/DVD/USB дистрибутиве: Geany, xorg, LightDM и любого DE, например xfce4

Данный скрипт можно запустить из любого места. 
Достаточно сделать один из файлов - испольняемым и запустить его непосредственно в консоли.

$ chmod ugo+x abif-installation/abif

$ sudo sh abif-installation/abif

Далее просто следуйсте указаниям мастер-установки.

P.S.: Обратите внимание!

Перед добавлением данного мастера в ваш Live дистрибутив
в файле "abif-installation/modules/installer-variables.sh" 
имеется необходимая настройка.

ISO_USER="liveuser" 

В строку "ISO_USER" необходимо записать пользователя, 
добавленного в ваш Live дистрибутив. 
От этого зависит коректность установки образа на ваш жесткий диск.

Рекомендуемая папка добавления данного мастера установки в ваш Live дистрибутив:
airootfs/abif-installation

А его ярлык на рабочем столе: airootfs/etc/skel/Desktop/install_offline.desktop

Если желаете изменить данное расположение установочных папок и файлов отредактируйте
файл "abif-installation/modules/installation-functions.sh", блок "Clean up installation".

Также в указанном выше блоке очистки, учитывается добавление в Live дистрибутив
мастера установки - online (aif-master) и мастера смены языка системы "archlinux-language"
c соответствующими для них ярлыками на рабочий стол Live системы.

Если вы не собираетесь использовать вышеуказанные мастера установок, можете удалить данные строки.
Однако, удалять их вовсе не обязательно.
Данный мастер установки никак не изменит вашу Live систему с указанными строками.


Желаем вам удачи.



