#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Utility Script                                             #
# This script facilitates the installation and configuration of various applications  #
# and settings on a Fedora system. It includes functions to manage Flatpak and        #
# install applications via Flatpak.                                                   #
#                                                                                     #
# Functions:                                                                          #
#   - enable_flathub: Adds the Flathub repository and installs Flatpak.               #
#   - flatpak_menu: Provides a menu for Flatpak-related operations.                   #
#   - install_flatpaks: Installs applications via Flatpak (implementation not shown). #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
#                                                                                     #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with DNF installed.                          #
#   - Internet connection is required for downloading packages and updates.           #
#-------------------------------------------------------------------------------------#

# Installs Flatpak and Enables Flathub
enable_flathub() {
    # Check if flatpak is installed
    if ! command -v flatpak &> /dev/null; then
        echo "Flatpak is not installed. Installing flatpak..."
        
        # Install flatpak using dnf
        sudo dnf install -y flatpak
        if [[ $? -ne 0 ]]; then
            echo "Failed to install flatpak. Please check your package manager."
            return 1
        fi
    fi

    # Add the Flathub repository
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    if [[ $? -eq 0 ]]; then
        dialog --msgbox "Flathub Enabled" 0 0
    else
        dialog --msgbox "Failed to add Flathub repository." 0 0
        return 1
    fi
}

flatpak_menu() {
    # Loop indefinitely to show the menu until the user chooses to exit
    while true; do
        # Display a menu using dialog and store the user's choice in the variable CHOICE
        CHOICE=$(dialog --clear \
                --title "Configure Flatpak and Manage Applications" \
                --nocancel \
                --menu "Choose an option:" \
                15 60 3 \
                1 "Enable Flatpak Support" \
                2 "Install Applications via Flatpak" \
                3 "Return to Main Menu" \
                3>&1 1>&2 2>&3)

        # Clear the screen after the dialog closes
        clear
        # Handle the user's choice
        case $CHOICE in
            1) 
                # Option 1: Enable Flatpak through the enable_flathub function
                enable_flathub ;;
            2) 
                # Option 2: Install Flatpak apps through the install_flatpaks function
                install_flatpaks ;;
            3) 
                # Option 3: Exit the menu loop
                break ;;
            *) 
                # Handle any other input as an invalid option
                echo "Invalid option. Please try again." ;;
        esac
    done
}

# Function to install Flatpak apps listed in flatapps.txt
install_flatpaks() {
    clear
    local USER=$(logname)
    local file="./plugins/flatapps.txt"

    if [[ ! -f "$file" ]]; then
        echo "File $file not found!"
        sleep 2
        return 1
    fi
   

    # Read the file into an array of options for the radiolist
    local options=()
    local i=0
    while IFS= read -r line; do
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            options+=($i "$line" off)
            ((i++))
        fi
    done < "$file"

    if [[ ${#options[@]} -eq 0 ]]; then
        dialog --msgbox "No apps found in $file" 0 0
        sleep 1
        return 1
    fi

    # Use dialog to create a radiolist for the user to select apps
    local choices=$(dialog --title "Select Flatpak Apps to Install" --checklist "Select apps:" 15 60 5 "${options[@]}" 3>&1 1>&2 2>&3 3>&-)

    if [[ -z "$choices" ]]; then
        dialog --msgbox "No apps selected." 0 0
        return 1
    fi

    clear
    echo "Installing selected Flatpak Apps"

    # Convert the user's choices into an array of indices
    local selected_indices=($choices)

    # Install the selected apps
    for index in "${selected_indices[@]}"; do
        local app="${options[index*3+1]}"  # Get the app name from options array
        runuser -u "$USER" -- flatpak install -y flathub "$app"
    done

    return 0
}
