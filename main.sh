#!/bin/bash

# Shows Banner on load
banner(){
    color1="\033[0;31m" # Red color
    color2="\033[0;34m"
    # Reset color
    reset_color="\033[0m"

    clear
    printf "${color1}
    ######## ######## ########   #######  ########     ###
    ##       ##       ##     ## ##     ## ##     ##   ## ##
    ##       ##       ##     ## ##     ## ##     ##  ##   ##
    ######   ######   ##     ## ##     ## ########  ##     ##
    ##       ##       ##     ## ##     ## ##   ##   #########
    ##       ##       ##     ## ##     ## ##    ##  ##     ##
    ##       ######## ########   #######  ##     ## ##     ##

             ########   #######   ######  ########
             ##     ## ##     ## ##    ##    ##
             ##     ## ##     ## ##          ##
             ########  ##     ##  ######     ##
             ##        ##     ##       ##    ##
             ##        ##     ## ##    ##    ##
             ##         #######   ######     ##

   #### ##    ##  ######  ########    ###    ##       ##
    ##  ###   ## ##    ##    ##      ## ##   ##       ##
    ##  ####  ## ##          ##     ##   ##  ##       ##
    ##  ## ## ##  ######     ##    ##     ## ##       ##
    ##  ##  ####       ##    ##    ######### ##       ##
    ##  ##   ### ##    ##    ##    ##     ## ##       ##
   #### ##    ##  ######     ##    ##     ## ######## ########
        
    ${color2}
        https://github.com/cuey78/Fedora-Post-Install
      -------------------------------------------------
${reset_color}
"
}
# Ensure the script runs with elevated privileges
if [ $EUID -ne 0 ]; then
    banner
    echo "Please run this as root!"
    exit 1
fi

#shows progress of importing scripts
show_progress() {
    total_files=1  # Assuming you want to import 5 files
    for ((i = 0; i <= total_files; i++)); do
        echo "$((i * 0))"
        echo "$((i * 100))"
        sleep 1
    done | dialog --title "Importing function scripts..." --gauge "Importing script $file" 10 70 0
}

source_function_scripts() {
    for i in {1..5}; do
        file="./src/data$i.db"
        if [ -e "$file" ]; then
            show_progress "$file"
            source "$file"

            if [ $? -ne 0 ]; then
                echo "Failed to source $file"
                exit 1
            fi
        else
            echo "$file does not exist in the current directory."
            exit 1
        fi
    done
}

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

# Check for xdotool installation used for downloading using browser
if ! rpm -q xdotool &>/dev/null; then
    sudo dnf install -y xdotool || { log_action "Failed to install xdotool. Exiting."; exit 1; }
    log_action "Installed xdotool."
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
    banner
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a $LOG_FILE
}

# Function to check if required functions are loaded
check_functions() {
    required_functions=(
        fix_and_clean_dnf
        check_firmware_update
        install_rpm_fusion
        install_microsoft_core_fonts
        install_nerd_fonts
        execsh
    )

    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" > /dev/null; then
            echo "Error: Function $func is not defined."
            exit 1
        fi
    done
}

menu(){
    # Options for the menu
    OPTIONS=(
        1 "Fix and Clean DNF"
        2 "Check for Firmware update"
        3 "Install RPM Fusion"
        4 "Install Drivers"
        5 "Install Media Codecs"
        6 "Enable Flathub"
        7 "Install Google Chrome"
        8 "Install Virtualization"
        9 "NFS Shares Setup ( Wifi / Wired )"
        10 "Extras"
        Q "Quit"
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
}
#show Banner
banner
#sleep for 2
sleep 2
#show progress and imports scripts
source_function_scripts
#checks Imported functions
check_functions
#Displays Main Menu
menu
#show banner on exit
banner
