#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Script                                                     #
# This script automates the configuration and installation of various software        #
# components on a Fedora system. It includes functions for system updates,            #
# firmware checks, and installations of essential fonts and repositories.             #
#                                                                                     #
# Functions:                                                                          #
#   - check_firmware_update: Checks and applies firmware updates.                     #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with DNF and fwupdmgr installed.             #
#   - Internet connection is required for downloading packages and updates.           #
#-------------------------------------------------------------------------------------#

# This Function performs a firmware update and upgrade if needed
check_firmware_update() {
    echo "Checking for Firmware updates..."

    # Ensure fwupdmgr is available
    if ! command -v fwupdmgr >/dev/null 2>&1; then
        echo "fwupdmgr is not installed. Please install it first."
        exit 1
    fi

    # Refresh the firmware metadata
    fwupdmgr refresh --force

    # Get available updates
    fw_update_result=$(fwupdmgr get-updates)

    # Check if there are updates available
    if echo "$fw_update_result" | grep -q "No upgrades for"; then
        update_status="No firmware update available."
    elif echo "$fw_update_result" | grep -q "Upgrade available"; then
        # Perform the firmware update
        fwupdmgr update -y
        update_status="Firmware updated successfully."
    else
        update_status="No updates required."
    fi

    # Clear the screen and show the result in a dialog box
    clear
    dialog --msgbox "$update_status Press OK to continue." 0 0
}
