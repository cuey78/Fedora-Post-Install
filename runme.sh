#!/bin/bash
clear
# Source the functions script
# Check if Function.db exists in the current directory
if [ -e "./Function.db" ]; then
    echo "Importing Fuctions....."
    source ./Function.db
else
    echo "Function.db does not exist in the current directory."
    exit 1
fi
# Dialog dimensions
HEIGHT=0
WIDTH=0
CHOICE_HEIGHT=11

# Titles and messages
TITLE="Fedora Post Install Script"
MENU="Please Choose one of the following options:"

# Check for dialog installation
if ! rpm -q dialog &>/dev/null; then
    sudo dnf install -y dialog || { log_action "Failed to install dialog. Exiting."; exit 1; }
    log_action "Installed dialog."
fi
# Function to display notifications
notify() {
    local message=$1
    local expire_time=${2:-10}
    if command -v notify-send &>/dev/null; then
        notify-send "$message" --expire-time="$expire_time"
    fi
    log_action "$message"
}
# Log function
log_action() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a $LOG_FILE
}
# Options for the menu
OPTIONS=(
    1 "1. Fix and Clean DNF"
    2 "2. Check for Firmware update"
    3 "3. Install RPM Fusion"
    4 "4. Install Drivers"
    5 "5. Install Media Codecs"
    6 "6. Enable Flathub"
    7 "7. Install Google Chrome"
    8 "8. Install Virtualization"
    9 "9. NFS Shares Setup ( Wifi / Wired )"
    10 "10. Fedora Theme Fix"
    Q "Q. Quit"

)
# Main loop
while true; do
    CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --nocancel \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

    clear
    case $CHOICE in
        1) fix_and_clean_dnf ;;
        2) check_firmware_update ;;
        3) install_rpm_fusion ;;
        4) install_drivers ;;
        5) install_media_codecs ;;
        6) enable_flathub ;;
        7) install_google_chrome ;;
        8) install_virtualization ;;
        9) nfs_setup ;;
        10) fedora_theme_fix ;;
        Q) log_action "User chose to quit the script."; exit 0 ;;
        *) log_action "Invalid option selected: $CHOICE";;
    esac
done