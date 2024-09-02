#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Utility Script                                             #
# This script facilitates the installation and configuration of various applications  #
# and settings on a Fedora system. It includes functions to manage system updates,    #
# install essential software, and configure system settings.                          #
#                                                                                     #
# Functions:                                                                          #
#   - install_nerd_fonts: Installs JetBrains Mono Nerd Font for enhanced typography   #
#     and programming experience.                                                     #
#   - install_microsoft_core_fonts: Installs Microsoft's core fonts for improved      #
#     compatibility with Microsoft Office documents and web content.                  #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with DNF package manager installed.          #
#   - Internet connection is required for downloading packages and updates.           #
#-------------------------------------------------------------------------------------#


#Function Installs A nerd font called Jetbrains Mono
install_nerd_fonts() {
  # Variables
  URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
  ZIP_FILE="JetBrainsMono.zip"
  EXTRACT_DIR="JetBrainsMono"
  FONT_DIR="/usr/share/fonts/$EXTRACT_DIR"
  LOG_FILE="install_nerd_fonts.log"

  # Logging function
  log() {
    echo "$(date +"%Y-%m-%d %T") - $1" | tee -a $LOG_FILE
  }

  # Start installation
  log "Starting installation of Nerd Fonts"

  # Download the ZIP file
  log "Downloading $URL"
  wget -O $ZIP_FILE $URL
  if [ $? -ne 0 ]; then
    log "Failed to download $URL"
    exit 1
  fi

  # Extract the ZIP file
  log "Extracting $ZIP_FILE"
  unzip $ZIP_FILE -d $EXTRACT_DIR
  if [ $? -ne 0 ]; then
    log "Failed to extract $ZIP_FILE"
    exit 1
  fi

  # Check if destination directory exists, if not, create it
  if [ ! -d "$FONT_DIR" ]; then
    log "Destination directory $FONT_DIR does not exist. Creating it."
    mkdir -p $FONT_DIR
    if [ $? -ne 0 ]; then
      log "Failed to create directory $FONT_DIR"
      exit 1
    fi
  fi

  # Copy the extracted files to the destination directory
  log "Copying extracted files to $FONT_DIR"
  cp -r $EXTRACT_DIR/* $FONT_DIR
  if [ $? -ne 0 ]; then
    log "Failed to copy extracted files to $FONT_DIR"
    exit 1
  fi

  # Change the ownership to root
  log "Changing ownership of $FONT_DIR to root"
  chown -R root: $FONT_DIR
  if [ $? -ne 0 ]; then
    log "Failed to change ownership of $FONT_DIR"
    exit 1
  fi

  # Change the permissions to 644 for files
  log "Changing permissions of files in $FONT_DIR to 644"
  find $FONT_DIR -type f -exec chmod 644 {} \;
  if [ $? -ne 0 ]; then
    log "Failed to change file permissions in $FONT_DIR"
    exit 1
  fi

  # Apply restorecon to the folder
  log "Applying restorecon to $FONT_DIR"
  restorecon -vFr $FONT_DIR
  if [ $? -ne 0 ]; then
    log "Failed to apply restorecon to $FONT_DIR"
    exit 1
  fi

  # Clean up
  log "Cleaning up"
  rm -rf $ZIP_FILE $EXTRACT_DIR
  if [ $? -ne 0 ]; then
    log "Failed to remove $ZIP_FILE or $EXTRACT_DIR"
    exit 1
  fi
    sleep 20
  log "Installation of Nerd Fonts completed successfully"
}

#This Function Installs Microsoft core Fonts
install_microsoft_core_fonts() {
  # Update and install necessary packages
  sudo dnf upgrade --refresh -y
  sudo dnf install curl cabextract xorg-x11-font-utils fontconfig -y
  # Install Microsoft Core Fonts
  
  sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
  echo "Installation of Microsoft Core Fonts completed successfully"
}

# This Function set all .sh files as executable
#not used anymore marked for deletion possible but leaving here for future use
execsh(){
    # Iterate over all .sh files in the current directory
    for file in *.sh; do
    if [ -f "$file" ]; then
        # Add executable permission
        chmod +x "$file"
    fi
    echo "files mark as execuctable"
done
}

# This Function installs Oh My Bash
function ohh_my_bash() {
  local USER2=$(logname)
    # Fetch script from URL with --unattended option
    script_url="https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh"
    script=$(curl -fsSL $script_url)

    # Execute the script with --unattended option
    echo "$script" | runuser -u "$USER2" -- bash -c "bash -s -- --unattended"
    dialog --msgbox "Oh My Bash installed. Please restart your terminal to apply changes." 0 0
}
