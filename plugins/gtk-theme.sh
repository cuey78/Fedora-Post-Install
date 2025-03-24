#!/bin/bash
# theme.sh - GTK Theme Selector for GNOME Desktop
#
# This script provides a simple, text-based interface for changing the GTK theme on GNOME Desktop environments.
# It allows users to select from a predefined list of GTK themes and applies the chosen theme using the `gsettings` command.
#
# Dependencies:
# - dialog (for text-based UI)
# - gnome-themes-extra (for additional GTK themes)
# - gsettings (for applying the selected theme)
#
# Usage:
# - Run the script, and a dialog menu will appear with a list of available GTK themes.
# - Select the desired theme, and the script will apply it to the GNOME Desktop environment.
# - If the required `gnome-themes-extra` package is not installed, the script will automatically install it.
#
# Notes:
# - The script currently supports the following themes: Adwaita, Adwaita-dark, HighContrast, and Raleigh.
# - The script is designed to work on systems using the `dnf` package manager (e.g., Fedora).
#
# Author: cuey
# License: MIT

set_gtk_theme() {
    local theme_name="$1"
    
    # Install the required package if missing
    if ! rpm -q gnome-themes-extra &>/dev/null; then
        echo "Installing gnome-themes-extra..."
        sudo dnf install -y gnome-themes-extra
    fi
    
    # Set the GTK theme
    #echo "Setting GTK theme ..."
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name"
    dialog --msgbox "GTK theme successfully changed to $theme_name" 0 0
}

choose_gtk_theme() {
# Show dialog menu for theme selection
CHOICE=$(dialog --clear --title "GTK Theme Selector" \
    --menu "Choose a GTK theme:" 15 40 4 \
    1 "Adwaita" \
    2 "Adwaita-dark" \
    3 "HighContrast" \
    4 "Raleigh" \
    3>&1 1>&2 2>&3)

clear  # Clear dialog output

# Map user choice to theme name
case $CHOICE in
    1) set_gtk_theme "Adwaita" ;;
    2) set_gtk_theme "Adwaita-dark" ;;
    3) set_gtk_theme "HighContrast" ;;
    4) set_gtk_theme "Raleigh" ;;
    *) echo "No selection made. Exiting."; return 1 ;;
esac
}
