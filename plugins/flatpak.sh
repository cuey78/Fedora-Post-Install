#!/bin/bash
# Fedora Post-Installation Utility Script

# Set environment variables for Flatpak
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_DATA_DIRS="/usr/local/share/:/usr/share/:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"

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
        echo "Flathub Enabled"
    else
        echo "Failed to add Flathub repository."
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
                enable_flathub ;;
            2)
                install_flatpaks ;;
            3)
                break ;;
            *)
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
        dialog --msgbox "File $file not found!" 5 40
        sleep 2
        return 1
    fi

    # Read the file into an array of options for the checklist
    local options=()
    local i=0
    while IFS= read -r line; do
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            options+=("$i" "$line" "off")  # Store index and app name
            ((i++))
        fi
    done < "$file"

    if [[ ${#options[@]} -eq 0 ]]; then
        dialog --msgbox "No apps found in $file" 5 40
        sleep 1
        return 1
    fi

    # Use dialog to create a checklist for the user to select apps
    local choices=$(dialog --title "Select Flatpak Apps to Install" --checklist "Select apps:" 15 60 10 "${options[@]}" 3>&1 1>&2 2>&3)

    # Check if the user made any selections
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "No apps selected." 5 40
        return 1
    fi

    # Create a temporary script to execute the Flatpak commands
    TEMP_SCRIPT=$(mktemp /tmp/install_flatpaks.XXXXXX.sh)
    echo "#!/bin/bash" > "$TEMP_SCRIPT"
    echo "set -e" >> "$TEMP_SCRIPT"  # Exit on error

    # Prepare commands for the selected apps
    IFS=' ' read -r -a selected_indices <<< "$choices"
    for index in "${selected_indices[@]}"; do
        local app="${options[index*3+1]}"  # Each app name is 3 elements away from the index
        echo "flatpak install -y flathub \"$app\" || { echo 'Failed to install $app'; exit 1; }" >> "$TEMP_SCRIPT"
    done

    # Remove any wait commands
    # Simply close the terminal after execution
    chmod +x "$TEMP_SCRIPT"

    # Spawn a new terminal to run the temporary script as the standard user
    # Change 'gnome-terminal' to your preferred terminal emulator if necessary
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "$TEMP_SCRIPT; rm -f \"$TEMP_SCRIPT\"; exit"
    elif command -v konsole &> /dev/null; then
        konsole -e bash -c "$TEMP_SCRIPT; rm -f \"$TEMP_SCRIPT\"; exit"
    else
        dialog --msgbox "No suitable terminal emulator found. Please install gnome-terminal or konsole." 5 40
        return 1
    fi

    return 0
}

