#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Utility Script                                             #
# This script facilitates the installation and configuration of various applications  #
# and settings on a Fedora system. It includes functions to manage system updates,    #
# install essential software, and configure system settings.                          #
#                                                                                     #
# Functions:                                                                          #
#   - fix_and_clean_dnf: Optimizes and updates DNF package manager settings.          #
#   - system_update: Performs a system update using DNF.                              #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with DNF package manager installed.          #
#   - Internet connection is required for downloading packages and updates.           #
#-------------------------------------------------------------------------------------#

# does DNF upgrade and performs a dnf clean updates dnf conf
# adding fastestmirror , max downloads 10, default yes and countme no
function fix_and_clean_dnf {
    local dnf_conf="/etc/dnf/dnf.conf"

    # Ask user if they want to clean dnf
    dialog --title "Clean DNF" --yesno "Would you like to clean the DNF cache before proceeding?" 7 60
    response=$?
    if [[ $response -eq 0 ]]; then
        dnf clean all
        messages+=("'dnf clean all' completed.")
    else
        messages+=("Skipped 'dnf clean all'.")
    fi

    # Define options and their default values for dnf.conf
    declare -A option_values=(
        ["fastestmirror"]="true"
        ["countme"]="false"
        ["defaultyes"]="True"
        ["max_parallel_downloads"]="10"
    )

    # Prepare options for dialog checklist
    local options=()
    local i=0
    for option in "${!option_values[@]}"; do
        current_value="${option_values[$option]}"
        options+=("$i" "$option (Current: $current_value)" off)
        ((i++))
    done

    # Use dialog to create a checklist for the user to select options
    local choices=$(dialog --title "Select DNF Options to Modify" --checklist "Select options:" 15 60 5 "${options[@]}" 3>&1 1>&2 2>&3 3>&-)

    # Check if user cancelled or didn't select any options
    if [[ -z "$choices" ]]; then
        dialog --msgbox "No options selected." 0 0
        return 1
    fi

    # Create an associative array to track selected options
    declare -A selected_options
    for index in $choices; do
        option=$(echo "${options[$((index * 3 + 1))]}" | cut -d' ' -f1)
        selected_options[$option]=true
    done

    # Initialize an array to store messages
    local messages=()

    # Apply selected options and remove unselected options from dnf.conf
    for option in "${!option_values[@]}"; do
        value="${option_values[$option]}"

        if [[ -n "${selected_options[$option]}" ]]; then
            # Option is selected, modify or add it
            if grep -q "^$option=" "$dnf_conf"; then
                sed -i "s/^$option=.*/$option=$value/" "$dnf_conf"
                messages+=("Modified $option=$value in dnf.conf")
            else
                sed -i "/^\[main\]/a $option=$value" "$dnf_conf"
                messages+=("Added $option=$value to dnf.conf")
            fi
        else
            # Option is not selected, remove it if it exists
            if grep -q "^$option=" "$dnf_conf"; then
                sed -i "/^$option=.*/d" "$dnf_conf"
                messages+=("Removed $option from dnf.conf")
            fi
        fi
    done

    # Display messages in a dialog box at the end
    dialog --msgbox "$(printf "%s\n" "${messages[@]}")" 20 70

    return 0
}

system_update(){
   # Ask user if they want to clean dnf
    dialog --title "System Update" --yesno "Would you like to Perform and System Update" 7 60
    response=$?
    if [[ $response -eq 0 ]]; then
        clear
        dnf update && dnf upgrade
        messages+=("'System update completed")
    else
        messages+=("Skipped System Update'.")
    fi
    return 0
}