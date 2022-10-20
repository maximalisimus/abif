setcolor()
{
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_ERROR="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \\033[0;39m"
}
outin_success()
{
    $SETCOLOR_SUCCESS
    echo -n "$(tput hpa $(tput cols))$(tput cub 6)[OK]"
    $SETCOLOR_NORMAL
    echo
}
outin_failure()
{
    $SETCOLOR_FAILURE
    echo -n "$(tput hpa $(tput cols))$(tput cub 6)[fail]"
    $SETCOLOR_NORMAL
    echo
}
_help()
{
	echo -e -n "\nUSAGE: $0 [-cli] [-gui] [-h] [--help]"
	echo -e -n "\nThe command is:"
	echo -e -n "\n\t-cli\tCLI distribution installation type."
	echo -e -n "\n\t-gui\tGUI distribution installation type."
	echo -e -n "\n\n\t-h\tHelp."
	echo -e -n "\n\t--help\tHelp."
}
