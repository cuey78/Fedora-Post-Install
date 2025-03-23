#!/bin/bash

# Function to display the GNOME tweaks menu
tweaks_gnome() {
    while true; do
        # Display the menu using dialog
        dialog --clear \
            --backtitle "Fedora 41 GNOME Tweaks" \
            --title "GNOME Tweaks Menu" \
            --menu "Select an option:" 0 0 0 \
            1 "Set Custom Location for GNOME Weather" \
            2 "Set GTK Theme for non GTK Apps" \
            3 "Set GDM login Screen to Primary Monitor" \
            4 "Install Custom set of Gnome Extensions:" \
            b "Back" 2>menu_selection

        # Read the user's choice
        choice=$(<menu_selection)
        rm -f menu_selection

        # Handle the user's choice
        case $choice in
            1)
                gnome_weather
                ;;
            2)
                choose_gtk_theme
                ;;
            3)
                fix_gdm_login
                ;;
            4)  gnome_extensions_main
                ;;
            b)
                return # Exit the function to go back to the main menu
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac

    done
}

# Function to apply KDE tweaks (placeholder)
tweaks_kde() {
    echo "KDE tweaks are not yet implemented."
    # Placeholder for future KDE tweaks
}

