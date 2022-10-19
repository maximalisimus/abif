# abif-master

****************************

abif-master - Bash script for installing the ArchISO system, which is running as a Live CD/DVD/USB, on a computer.

abif-master - Bash скрипт для установки системы ArchISO, которая запущена в качестве Live CD/DVD/USB, на компьютер.

<img src="https://raw.githubusercontent.com/maximalisimus/abif-master/master/image/abif-image.jpg"  height="400">

## Оглавление

1. [Информация](#Информация)
2. [Information](#Information)
4. [Использование](#Использование)
5. [Uses](#Uses)
6. [Обо Мне](#aboutrus)
7. [About](#abouten)

[:arrow_up:Информация](#Информация)

Данный скрипт предназначен для установки сборки системы в виде **ArchISO - 
Live CD/DVD/USB ArchLinux** в псевдографическом режиме, используя пакет **dialog**.

Скрипт можно использовать с любым дистрибутивом *ArchLunux*, который **должен поддерживать**: 
* **XORG** 
* Рабочее окружение - **Desktop environment** 
* Менеджер дисплея - **Display Manager**.

Данный мастер поддерживает **UEFI** режим установки при запуске системы *ArchLinux* в режиме *UEFI*.

Для начала вы форматируете ваш жесткий диск, создаете на нём необходимые вам разделы и монтируете их 
с помощью встроенного меню.

Затем скрипт переносит систему с помощью утилиты **rsync** на ваш жесткий диск и осуществляет дополнительные настройки.

Такие как: 
* Пользователи
* Настройки swappiness
* TMPFS для SSD
* Язык системы
* Настройки клавиатуры
* и другие.

[:arrow_up:Information](#Information)

This script is intended for installing the system assembly in the form of "ArchISO" -
Live CD/DVD/USB ArchLinux in pseudographic mode, using the dialog package.

The script can be used with any Archlinux distribution that **must support**:
* XORG
* Working environment-Desktop environment
* Display Manager - Display Manager.

This wizard supports UEFI installation mode when starting the ArchLinux system in UEFI mode.

First, you format your hard disk, create the necessary partitions on it and mount them
using the built-in menu.

Then the script transfers the system using the **rsync** utility to your hard disk and performs additional settings.

Such as:
* Users
* Swappiness settings
* TMPFS for SSD
* System language
* Keyboard Settings
* and others.

[:arrow_up:Использование](#Использование)

### Базовая информация

Для использования данного мастера необходимо соблюдать 2 важных условий:

1. Запуск из под суперпользователя **root**.
2. Наличие в вашем **Live CD/DVD/USB** дистрибутиве утилит и пакетов: **Geany**, **Xorg**, 
а также рабочего окружения и менеджера дисплея. Например, **XFCE4** и **LightDM**.

**Данный скрипт можно запустить из любого места**.
 
Достаточно сделать один из файлов - испольняемым и запустить его из консоли:

```
$ chmod ugo+x abif-installation/abif

$ sudo sh abif-installation/abif
```

Далее просто следуйсте указаниям мастер-установки.

### Установка в ArchISO дистрибутив.

Перед добавлением данного мастера в ваш **ArchISO** необходимо в файле 
*abif-installation/modules/installer-variables.sh* исправить переменную 
**ISO_USER** на того пользователя, которого вы создадите в вашем дистрибутиве.

```
ISO_USER="liveuser"
```

От этой настройки зависит **коректность установки конечного образа** на ваш жесткий диск.

Рекомендуемая папка добавления данного мастера установки в ваш **Live** дистрибутив: 
*airootfs/abif-installation*

А его ярлык на рабочем столе: *airootfs/etc/skel/Desktop/install_offline.desktop*

Если желаете изменить данное расположение установочных папок и файлов рекомендуется отредактировать 
файл: *abif-installation/modules/installation-functions.sh*, начиная с блока **Clean up installation**.

Также в указанном выше блоке очистки, учитывается добавление в **Live** дистрибутив
мастера установки - **online (aif-master)** и мастера смены языка системы **archlinux-language**
c соответствующими для них ярлыками на рабочий стол **Live** системы.

Если вы не собираетесь использовать вышеуказанные мастера установок, можете удалить данные строки.
Однако, удалять их вовсе не обязательно.
Данный мастер установки никак не изменит вашу Live систему с указанными строками.

**Желаем вам удачи!**

[:arrow_up:Uses](#Uses)

### Basic information

To use this wizard, you must comply with 2 important conditions:

1. Start from under the superuser * * root**.
2. The presence in your **Live CD/DVD/USB** distribution of utilities and packages: **Geany**, **Xorg**,
as well as a working environment and a display manager. For example, **XFCE4** and **LightDM**.

**This script can be run from anywhere**.

It is enough to make one of the files executable and run it from the console:

```
$ chmod ugo+x abif-installation/abif

$ sudo sh abif-installation/abif
```

Then just follow the instructions of the installation wizard.

### Installation in the ArchISO distribution.

Before adding this wizard to your **ArchISO**, it is necessary in the file
*abif-installation/modules/installer-variables.sh* fix the variable 
**ISO_USER** for the user that you will create in your distribution.

```
ISO_USER="liveuser"
```

**The correctness of installing the final image** on your hard disk depends on this setting.

The recommended folder for adding this installation wizard to your **Live** distribution: 
*airootfs/abif-installation*

And its shortcut on the desktop: *airootfs/etc/skel/Desktop/install_offline.desktop*

If you want to change this location of the installation folders and files, it is recommended to edit
the file: *abif-installation/modules/installer-variables.sh*, starting from the 
**Clean up installation** block.

Also in the above cleaning block, the addition to the **Live** distribution 
is taken into account installation wizards - **online (aif-master)** 
and the system language change wizard **archlinux-language** with the 
corresponding shortcuts to the desktop **Live** of the system.

If you are not going to use the above installation wizards, you can delete these lines. 
However, it is not necessary to delete them at all. 
This installation wizard will not change your Live system with the specified lines in any way.

**We wish you good luck!**

[:arrow_up:Обо Мне](#aboutrus)

Автор данной разработки **Shadow**: [maximalisimus](https://github.com/maximalisimus).

Имя автора: **maximalisimus**: [E-Mail](mailto:maximalis171091@yandex.ru).

Дата создания: **13.09.2019**

Начальная точка проекта: [midfingr/archmid-iso](https://github.com/midfingr/archmid-iso.git/airootfs/abif-master/).

[:arrow_up:About](#abouten)

The author of this development **Shadow**: [maximalisimus](https://github.com/maximalisimus).

Author's name: **maximalisimus**: [E-Mail](mailto:maximalis171091@yandex.ru).

Date of creation: **13.09.2019**

Starting point of the project: [midfingr/archmid-iso](https://github.com/midfingr/archmid-iso.git/airootfs/abif-master/).

