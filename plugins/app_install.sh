#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora 41 Application Installer Script                                             #
# This script automates the installation of various software applications on a       #
# Fedora 41 system. It provides a menu-driven interface for users to select and      #
# install applications like Cooler Control, gaming utilities, GNOME Software,        #
# and development tools.                                                             #
#                                                                                     #
# Functions:                                                                          #
#   - display_menu: Displays a menu for user selection of applications to install.    #
#   - install_cooler_lact: Installs Cooler Control and LACT.                          #
#   - install_gaming_utils: Installs gaming-related utilities like Steam and Lutris.  #
#   - install_gnome_software: Installs GNOME Software for application management.     #
#   - install_dev_tools: Installs development tools like wget and git.                #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin for fedora post install.              #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora 41 system with DNF and internet access.             #
#   - Ensure sudo privileges for software installation and system configuration.      #
#-------------------------------------------------------------------------------------#

# Function to display a menu using dialog
display_menu() {
  dialog --clear \
    --backtitle "Fedora 41 Application Installer" \
    --title "Application Installation Menu" \
    --menu "Select an application to install:" 0 0 0 \
    1 "Cooler Control and LACT - Install tools to control CPU coolers and monitor temperature." \
    2 "Gaming Utilities - Install Steam, Lutris, Gamescope, and other gaming-related tools." \
    3 "Development Tools - Install wget, git, pciutils, and related utilities for development." \
    4 "GNOME Software - Install GNOME Software for managing applications on your system." \
    5 "Back" 2>menu_selection

  choice=$(<menu_selection)
  rm -f menu_selection
}

# Function to install Cooler Control and LACT
install_cooler_lact() {
  clear
  echo "Installing Cooler Control and LACT..."
  dnf copr enable codifryed/CoolerControl -y
  dnf install coolercontrol -y
  systemctl enable --now coolercontrold

  dnf install https://github.com/ilya-zlobintsev/LACT/releases/download/v0.6.0/lact-0.6.0-0.x86_64.fedora-41.rpm -y
  systemctl enable --now lactd
}

# Function to install gaming utilities
install_gaming_utils() {
  clear
  echo "Installing Gaming Utilities..."
  dnf install steam lutris gamescope mangohud -y

  git clone https://github.com/Winetricks/winetricks
  cd winetricks || exit
  make install
  cd ..
  rm -rf winetricks

  wget https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.15.2/heroic-2.15.2.x86_64.rpm
  dnf install heroic-2.15.2.x86_64.rpm -y
  rm -f heroic-2.15.2.x86_64.rpm
}

# Function to install GNOME Software
install_gnome_software() {
  clear
  echo "Installing GNOME Software..."
  dnf install gnome-software -y
}

# Function to install development tools
install_dev_tools() {
  clear
  echo "Installing Development Tools..."
  dnf install wget2 wget git pciutils -y
}

# Function for the main script loop
app_install() {
  clear
  while true; do
    display_menu

    case $choice in
      1)
        install_cooler_lact
        ;;
      2)
        install_gaming_utils
        ;;
      3)
        install_dev_tools
        ;;
      4)
        install_gnome_software
        ;;
      5)
        return # Exit the function to go back to the main menu
        ;;
      *)
        echo "Invalid option. Please try again."
        ;;
    esac
  done
}
