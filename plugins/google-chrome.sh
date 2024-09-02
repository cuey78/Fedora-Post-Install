#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Utility Script                                             #
# This script facilitates the installation and configuration of various applications  #
# and settings on a Fedora system. It includes functions to manage system updates,    #
# install essential software, and configure system settings.                          #
#                                                                                     #
# Functions:                                                                          #
#   - install_google_chrome: Installs Google Chrome browser.                          #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with DNF package manager installed.          #
#   - Internet connection is required for downloading packages and updates.           #
#-------------------------------------------------------------------------------------#

# Installs Google Chrome repo and Installs Google Chrome
install_google_chrome() {
    dnf install -y fedora-workstation-repositories
    dnf config-manager --set-enabled google-chrome
    dnf -y install google-chrome-stable
    dialog --msgbox "Google Chrome Installed" 0 0
}
