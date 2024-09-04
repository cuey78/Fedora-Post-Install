#!/bin/bash

#########################################################################################
#                                                                                       #
# Fedora Post-Install Script                                                            #
# This script automates the configuration and setup of a Fedora system after            #
# installation. It includes functions for installing packages, configuring system       #
# settings, and setting up themes and environments.                                     #
#                                                                                       #
# Functions:                                                                            #
#   banner - Displays a custom banner with script information.                          #
#   show_progress - Shows the progress of file imports using a gauge dialog.            #
#   source_function_scripts - Sources additional script files containing utility        #
#                             functions.                                                #
#   check_and_install_package - Checks for the presence of a package and installs it    #
#                               if not present.                                         #
#   notify - Sends a desktop notification with a specified message.                     #
#   log_action - Logs actions to a file with a timestamp.                               #
#   check_functions - Checks if required functions are defined in the environment.      #
#   menu - Displays a menu for user interaction to select various setup options.        #
#                                                                                       #
# Usage:                                                                                #
#   Run the script with root privileges to ensure proper functionality.                 #
#   Select options from the menu to perform specific setup tasks.                       #
#                                                                                       #
#                                                                                      #
#  Author: cuey                                                                         #
#                                                                                       #
#  Example Colours                                                                      #
#  Define color variables                                                               #
#  RED="\033[0;31m"                                                                     #
#  GREEN="\033[0;32m"                                                                   #
#  YELLOW="\033[0;33m"                                                                  #
#  BLUE="\033[0;34m"                                                                    #
#  MAGENTA="\033[0;35m"                                                                 #
#  CYAN="\033[0;36m"                                                                    #
#  WHITE="\033[0;37m"                                                                   #
#  Reset color                                                                          #
#  RESET="\033[0m"                                                                      #
#########################################################################################

# Shows Banner on load
banner(){
    local color1="\033[0;37m" # Red color
    local color2="\033[0;34m" # Blue color
    # Reset color
    local reset_color="\033[0m"

    clear
    # Get terminal width
    local term_width=$(tput cols)
    # Calculate padding to center the banner
    local padding=$(printf '%*s' $(( (term_width - 58) / 2 )) '')

    echo -e "${color1}${padding}######## ######## ########   #######  ########     ###"
    echo -e "${color1}${padding}##       ##       ##     ## ##     ## ##     ##   ## ##"
    echo -e "${color1}${padding}##       ##       ##     ## ##     ## ##     ##  ##   ##"
    echo -e "${color1}${padding}######   ######   ##     ## ##     ## ########  ##     ##"
    echo -e "${color1}${padding}##       ##       ##     ## ##     ## ##   ##   #########"
    echo -e "${color1}${padding}##       ##       ##     ## ##     ## ##    ##  ##     ##"
    echo -e "${color1}${padding}##       ######## ########   #######  ##     ## ##     ##"
    echo -e "${color1}${padding}"
     echo -e "${color1}${padding}         ########   #######   ######  ########"
     echo -e "${color1}${padding}         ##     ## ##     ## ##    ##    ##"
     echo -e "${color1}${padding}         ##     ## ##     ## ##          ##"
     echo -e "${color1}${padding}         ########  ##     ##  ######     ##"
     echo -e "${color1}${padding}         ##        ##     ##       ##    ##"
     echo -e "${color1}${padding}         ##        ##     ## ##    ##    ##"
     echo -e "${color1}${padding}         ##         #######   ######     ##"
    echo -e "${color1}${padding}"
    echo -e "${color1}${padding}#### ##    ##  ######  ########    ###    ##       ##"
    echo -e "${color1}${padding} ##  ###   ## ##    ##    ##      ## ##   ##       ##"
    echo -e "${color1}${padding} ##  ####  ## ##          ##     ##   ##  ##       ##"
    echo -e "${color1}${padding} ##  ## ## ##  ######     ##    ##     ## ##       ##"
    echo -e "${color1}${padding} ##  ##  ####       ##    ##    ######### ##       ##"
    echo -e "${color1}${padding} ##  ##   ### ##    ##    ##    ##     ## ##       ##"
    echo -e "${color1}${padding}#### ##    ##  ######     ##    ##     ## ######## ########"
    echo -e "${color1}${padding}"
    echo -e "${color2}${padding}    https://github.com/cuey78/Fedora-Post-Install"
    echo -e "${reset_color}"
}

# Ensure the script runs with elevated privileges
if [ $EUID -ne 0 ]; then
    banner
    color1="\033[0;31m" # Red color
    # Get terminal width
    term_width=$(tput cols)
    # Calculate padding to center the banner
    padding=$(printf '%*s' $(( (term_width - 30) / 2 )) '')
    echo -e "${color1}${padding}Please run this as root!"
    echo -e "\033[0m"
    exit 1
fi

# Function to show progress of importing scripts
show_progress() {
    local total_files=$1
    local current_file_index=$2
    local percentage=$((current_file_index * 100 / total_files))

    echo $percentage | dialog --gauge "Importing function scripts..." 10 70
    sleep .1
}

# Function to source function scripts from the src directory
source_function_scripts() {
    local files_to_source=(./plugins/*.sh)
    local total_files=${#files_to_source[@]}
    local current_file_index=0

    for file in "${files_to_source[@]}"; do
        if [ -e "$file" ]; then
            source "$file"
            if [ $? -ne 0 ]; then
                echo "Failed to source $file"
                exit 1
            fi
            ((current_file_index++))
            show_progress "$total_files" "$current_file_index"
        else
            echo "$file does not exist in the current directory."
            exit 1
        fi
    done
}

# Check for necessary packages and install if missing
check_and_install_package() {
    local package=$1
    if ! rpm -q $package &>/dev/null; then
        sudo dnf install -y $package || { echo "Failed to install $package. Exiting."; exit 1; }
        echo "Installed $package."
    fi
}

# Function to display notifications
notify() {
    local message=$1
    local expire_time=${2:-10}
    if command -v notify-send &>/dev/null; then
        notify-send "$message" --expire-time="$expire_time"
    fi
    log_action "$message"
}

#reset permisions
cleanup() {
    local user1="$(logname)"
    local directory="$(pwd)"  # Current directory
    chown -R "$user1":"$user1" "$directory"
}

# Log function
log_action() {
    banner
    cleanup
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a $LOG_FILE
}

# Function to verify the availability of essential functions
# Ensures that critical functions are properly imported and available for use
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


# Constants for titles and messages
declare -r TITLE="Fedora Post Install Script"
declare -r MENU="Please Choose one of the following options:"

menu() {
    # Menu options array
    local options=(
        1 "Optimize and Update DNF Settings"
        2 "System Update"
        3 "Check for Firmware Updates"
        4 "Install RPM Fusion Repositories"
        5 "Install System Drivers"
        6 "Install Media Codecs"
        7 "Configure Flatpak and Manage Applications"
        8 "Install Google Chrome Browser"
        9 "Install Virtualization Tools"
        10 "Setup NFS Shares (WiFi/Wired)"
        11 "Install Additional Extras"
        12 "Swap Kernel"
        Q "Quit"
    )

    # Infinite loop for menu display and interaction
    while true; do
        local choice=$(dialog --clear \
                              --title "$TITLE" \
                              --nocancel \
                              --menu "$MENU" \
                              0 0 0 \
                              "${options[@]}" \
                              2>&1 >/dev/tty)

        clear
        case $choice in
            1) fix_and_clean_dnf ;;
            2) system_update ;;
            3) check_firmware_update ;;
            4) install_rpm_fusion ;;
            5) install_drivers ;;
            6) install_media_codecs ;;
            7) flatpak_menu ;;
            8) install_google_chrome ;;
            9) install_virtualization ;;
            10) nfs_setup ;;
            11) fedora_theme_fix ;;
            12) kernel_menu ;;
            Q) log_action "User chose to quit the script."; exit 0 ;;
            *) log_action "Invalid option selected: $choice";;
        esac
    done
}



# Initialization of the script

# Install required dependencies
check_and_install_package dialog
check_and_install_package xdotool

# Display the initial banner
banner

# Pause execution for .5 seconds to allow banner visibility
sleep 1
# Load additional script functions
source_function_scripts
# Verify that all necessary functions are correctly imported
check_functions
# Display the main menu to the user
menu
# Show the closing banner upon script exit
banner

