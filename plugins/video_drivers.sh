#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Utility Script                                             #
# This script facilitates the installation and configuration of various drivers,      #
# codecs, and applications on a Fedora system. It includes functions to install       #
# AMD and Intel drivers, media codecs, and manage video driver installations.         #
#                                                                                     #
# Functions:                                                                          #
#   - install_amd_drivers: Installs AMD Mesa Freeworld Drivers.                       #
#   - install_intel_drivers: Installs Intel Media Drivers.                            #
#   - install_drivers: Provides a menu to install video drivers based on user choice. #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with DNF installed.                          #
#   - Internet connection is required for downloading packages and updates.           #
#   - RPM Fusion repositories should be enabled for some functions to work properly.  #
#-------------------------------------------------------------------------------------#

# Installs Mesa Freeworld Drivers 
install_amd_drivers(){
    clear
    dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
    dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
    dnf install -y libva-utils
}

# Installs Intel Media Driver
install_intel_drivers(){
    clear
    dnf install -y intel-media-driver
    dnf install -y  libva-utils
}

# Main Function to Install Video Drivers
install_drivers() {
    # Check if rpmfusion-free and rpmfusion-nonfree repositories are enabled
    free_repo=$(dnf repolist all | grep -i 'rpmfusion-free')
    nonfree_repo=$(dnf repolist all | grep -i 'rpmfusion-nonfree')
    
    if [[ -n "$free_repo" && -n "$nonfree_repo" ]]; then
     while true; do
        CHOICE=$(dialog --clear \
                --title "Video Drivers" \
                --nocancel \
                --menu "Choose an option:" \
                15 60 3 \
                1 "Install Mesa FreeWorld Drivers for AMD" \
                2 "Install Intel Media Driver" \
                3 "Exit" \
                3>&1 1>&2 2>&3)


        case $CHOICE in
            1) install_amd_drivers ;;
            2) install_intel_drivers ;;
            3) break ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
    else
        dialog --msgbox "Please Enable RPM Fusion First" 0 0
        break
    fi
}