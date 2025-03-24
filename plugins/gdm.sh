#!/bin/bash

fix_gdm_login() {
    clear
    dialog --msgbox "Setting GDM Login to Primary Display" 0 0

    # Get the username of the logged-in user
    local usern
    usern=$(logname)
    if [[ -z "$usern" ]]; then
        dialog --msgbox "Error: Unable to determine the logged-in user." 0 0
        return 1
    fi

    # Get GDM's home directory
    local gdm_home
    gdm_home=$(getent passwd gdm | cut -d: -f6)

    # Check if GDM's home directory was found
    if [[ -z "$gdm_home" ]]; then
        dialog --msgbox "Error: Unable to determine GDM's home directory." 0 0
        return 1
    fi

    # Check if the user's monitors.xml file exists
    local user_monitors_file="/home/$usern/.config/monitors.xml"
    if [[ ! -f "$user_monitors_file" ]]; then
        dialog --msgbox "Error: $user_monitors_file not found. Please configure your displays first." 0 0
        return 1
    fi

    # Create the GDM .config directory if it doesn't exist
    sudo mkdir -p "$gdm_home/.config"

    # Copy the monitors.xml file to GDM's config directory
    if sudo cp -f "$user_monitors_file" "$gdm_home/.config/monitors.xml"; then
        sudo chown gdm:gdm "$gdm_home/.config/monitors.xml"
        dialog --msgbox "GDM login screen monitor configuration updated successfully." 0 0
    else
        dialog --msgbox "Error: Failed to copy monitors.xml to GDM's config directory." 0 0
        return 1
    fi
}
