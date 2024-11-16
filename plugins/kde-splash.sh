#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Configuration Script                                       #
# This script assists in setting up virtualization environments and related           #
# configurations on a Fedora system. It includes functions for configuring IOMMU,     #
# setting up virtualization software, and other system configurations.                #
#                                                                                     #
# Functions:                                                                          #
#   - FIX_KDE_SPLASH: Applies a Fedora theme Splash Screen to KDE                     #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with necessary virtualization capabilities.  #
#   - Internet connection is required for downloading packages and updates.           #
#-------------------------------------------------------------------------------------#

#Applys a Fedora theme Splash Screen to KDE
FIX_KDE_SPLASH(){
            #Fixs Fedora KDE Default Splash Screen to Match Fedora Logo
            USER2=$(logname)
            USER_HOME="/home/$USER2/.config"
            TAR_FILE="./splash/Fedora-Minimalistic.tar.gz"
            SOURCE_DIR="./splash/"
            DEST_DIR="/home/$USER2/.local/share/plasma/look-and-feel/"

            # Extract the tar.gz file
            echo "Extracting $TAR_FILE..."
            tar -xzf "$TAR_FILE" -C ./splash/ 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Error extracting $TAR_FILE."
                exit 1
            fi

            # Ensure the source directory was extracted
            if [ ! -d "$SOURCE_DIR" ]; then
                echo "Source directory $SOURCE_DIR not found after extraction."
                exit 1
            fi

            # Create the destination directory
            echo "Creating destination directory $DEST_DIR..."
            runuser -u "$USER2" -- mkdir -p "$DEST_DIR"
            if [ $? -ne 0 ]; then
                echo "Error creating destination directory $DEST_DIR."
                exit 1
            fi

            # Copy the files
            echo "Copying files from $SOURCE_DIR to $DEST_DIR..."
            runuser -u "$USER2" -- cp -r "$SOURCE_DIR"/* "$DEST_DIR"
            if [ $? -ne 0 ]; then
                echo "Error copying files to $DEST_DIR."
                exit 1
            fi

            echo "Files copied from $SOURCE_DIR to $DEST_DIR successfully."

            # Define the target file
            FILE="$USER_HOME/ksplashrc"

            # Write the specified lines to the ksplashrc file
            echo -e "[KSplash]\nTheme=Fedora-Minimalistic" > "$FILE"
            # set permissions on config
            chown $USER2:$USER2 $FILE
            # Print a success message
            dialog --msgbox "The Fedora KDE splash screen theme has been successfully applied." 0 0 
            
            #clean uo
            rm /home/$USER2/.local/share/plasma/look-and-feel/Fedora-Minimalistic.tar.gz
}