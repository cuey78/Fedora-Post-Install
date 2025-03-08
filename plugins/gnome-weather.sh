#!/bin/bash

#
# gnome_weather.sh - Add locations to GNOME Weather
#
# This script allows users to search for and add a location to GNOME Weather
# (either the system package or the Flatpak version). It queries OpenStreetMap's
# Nominatim API for location data and updates GNOME Weather's stored locations
# using gsettings.
#
# Dependencies:
# - dialog (for text-based UI)
# - curl (for making API requests)
# - bc (for latitude/longitude conversions)
#
# Usage:
# - Run the script and enter a location when prompted.
# - If a matching location is found, confirm whether you want to add it.
# - The location will be added to GNOME Weather if installed.
#
# Notes:
# - If both the system and Flatpak versions of GNOME Weather are installed,
#   the script updates both.
# - API queries are limited to one result to avoid ambiguity.
#
# Author: cuey  
# License: MIT  

current_user=$(logname)

gnome_weather() {
    if command -v gnome-weather &>/dev/null; then
        system=1
    fi

    if flatpak list | grep -q org.gnome.Weather; then
        flatpak=1
    fi

    if [[ -z $system && -z $flatpak ]]; then
        dialog --msgbox "GNOME Weather isn't installed" 0 0
        return 1
    fi

    language=$(locale | sed -n 's/^LANG=\([^_]*\).*/\1/p')

    if [[ -n "$*" ]]; then
        query="$*"
    else
        query=$(dialog --inputbox "Enter location:" 0 0 --stdout)
    fi

    query="$(echo "$query" | sed 's/ /+/g')"
    request=$(curl -s "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1" -H "Accept-Language: $language")

    if [[ $request == "[]" ]]; then
        dialog --msgbox "No locations found, consider removing some search terms" 0 0
        return 1
    fi

    location_name=$(echo "$request" | sed 's/.*"display_name":"//' | sed 's/".*//')
    dialog --yesno "If this is not the location you wanted, consider adding search terms.\n\nAre you sure you want to add \"$location_name\"?" 10 60
    
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Not adding location" 0 0
        return 1
    else
        dialog --msgbox "Adding location" 0 0
    fi

    id=$(echo "$request" | sed 's/.*"place_id"://' | sed 's/,.*//')
    details=$(curl -s "https://nominatim.openstreetmap.org/details.php?place_id=$id&format=json")

    if [[ $details == *"name:$language"* ]]; then
        name=$(echo "$details" | sed "s/.*\"name:$language\": \"//" | sed 's/\".*//')
    else
        name=$(echo "$details" | sed 's/.*"name": "//' | sed 's/".*//')
    fi

    lat=$(echo "$request" | sed 's/.*"lat":"//' | sed 's/".*//')
    lat=$(echo "$lat / (180 / 3.141592654)" | bc -l)

    lon=$(echo "$request" | sed 's/.*"lon":"//' | sed 's/".*//')
    lon=$(echo "$lon / (180 / 3.141592654)" | bc -l)

    # Correct the location format
    location="<(uint32 2, <(\"$name\", \"\", false, [($lat, $lon)], @a(dd) [])>)>"

    if [[ $system == 1 ]]; then
        locations=$(runuser -l "$current_user" -c "gsettings get org.gnome.Weather locations")

        if [[ "$locations" != "@av []" ]]; then
            updated_locations=$(echo "$locations" | sed "s|>]$|>, $location]|")
            sudo -u "$SUDO_USER" gsettings set org.gnome.Weather locations "$updated_locations"
        else
            sudo -u "$SUDO_USER" gsettings set org.gnome.Weather locations "[\"$location\"]"

        fi
    fi

    if [[ $flatpak == 1 ]]; then
        locations=$(runuser -l "$current_user" -c "flatpak run --command=gsettings org.gnome.Weather get org.gnome.Weather locations")

        if [[ "$locations" != "@av []" ]]; then
            updated_locations=$(echo "$locations" | sed "s|>]$|>, $location]|")
           sudo -u "$SUDO_USER" flatpak run --command=gsettings org.gnome.Weather set org.gnome.Weather locations "$updated_locations"
        else
            sudo -u "$SUDO_USER" flatpak run --command=gsettings org.gnome.Weather set org.gnome.Weather locations "[\"$location\"]"

        fi
    fi
}


