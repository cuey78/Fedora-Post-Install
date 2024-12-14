#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Utility Script                                             #
# This script facilitates the installation of media codecs on a Fedora system.        #
#                                                                                     #
# Functions:                                                                          #
#   - install_media_codecs: Installs essential media codecs for multimedia playback.  #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with DNF installed.                          #
#   - Internet connection is required for downloading packages and updates.           #
#   - RPM Fusion repositories should be enabled for this function to work properly.   #
#-------------------------------------------------------------------------------------#

# Install Media Codecs 
install_media_codecs() {
    echo "Installing Media Codecs"

    # Function to check if dnf5 is installed
    check_dnf5_installed() {
        command -v dnf5 >/dev/null 2>&1
    }

    # Determine which DNF command to use and check for RPM Fusion repositories
    if check_dnf5_installed; then
        free_repo=$(dnf5 repo list --all | grep -i 'rpmfusion-free')
        nonfree_repo=$(dnf5 repo list --all | grep -i 'rpmfusion-nonfree')
    else
        free_repo=$(dnf repolist all | grep -i 'rpmfusion-free')
        nonfree_repo=$(dnf repolist all | grep -i 'rpmfusion-nonfree')
    fi

    # Check if both repositories are detected
    if [[ -n "$free_repo" && -n "$nonfree_repo" ]]; then
        echo "RPM Fusion repositories are enabled."

        # Update system and install codecs
        if check_dnf5_installed; then
            dnf5 update -y
            dnf5 install -y \
                gstreamer1-plugins-{bad-\*,good-\*,base} \
                gstreamer1-plugin-openh264 \
                gstreamer1-libav \
                --exclude=gstreamer1-plugins-bad-free-devel
            dnf5 install -y lame* --exclude=lame-devel
            dnf5 group upgrade -y --with-optional Multimedia
        else
            dnf update -y
            dnf install -y \
                gstreamer1-plugins-{bad-\*,good-\*,base} \
                gstreamer1-plugin-openh264 \
                gstreamer1-libav \
                --exclude=gstreamer1-plugins-bad-free-devel
            dnf install -y lame* --exclude=lame-devel
            dnf group upgrade -y --with-optional Multimedia
        fi

        echo "Media codecs installed successfully."
    else
        echo "Error: RPM Fusion repositories are not enabled. Please enable them first and try again."
        echo "Detected repositories:"
        if check_dnf5_installed; then
            dnf5 repo list --all
        else
            dnf repolist all
        fi
        exit 1
    fi
}



