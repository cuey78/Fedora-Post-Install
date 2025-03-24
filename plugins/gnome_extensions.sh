#!/bin/bash

# Define the array of GNOME extension UUIDs
EXTENSIONS=(
    "openbar@neuromorph"
    "dash-to-dock@micxgx.gmail.com"
    "add-to-desktop@tommimon.github.com"
    "trayIconsReloaded@selfmade.pl"
    "auto-accent-colour@Wartybix"
    "reboottouefi@ubaygd.com"
    "no-overview@fthx"
    "accent-directories@taiwbi.com"
    "lan-ip-address@mrhuber.com"
    "editdesktopfiles@dannflower"
    "tiling-assistant@leleat-on-github"
    "caffeine@patapon.info"
    "gamemodeshellextension@trsnaqe.com"
    "quick-settings-audio-panel@rayzeq.github.io"
    "apps-menu@gnome-shell-extensions.gcampax.github.com"
    "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
    "places-menu@gnome-shell-extensions.gcampax.github.com"
    "appindicatorsupport@rgcjonas.gmail.com"
)

# Function to fetch the download URL for a given extension UUID
fetch_download_url() {
    local UUID="$1"
    local API_URL="https://extensions.gnome.org/extension-info/?uuid=${UUID}&shell_version=44"  # Adjust shell_version as needed
    local DOWNLOAD_URL=$(curl -s "$API_URL" | jq -r '.download_url')
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "Error: Unable to fetch download URL for extension $UUID."
        return 1
    fi
    echo "https://extensions.gnome.org${DOWNLOAD_URL}"
}

# Function to install GNOME extensions from the array
install_gnome_extensions() {
    local USER=$(logname)  # Capture the current user
    
    # Loop through the extensions in the array and install them
    for EXTENSION_UUID in "${EXTENSIONS[@]}"; do
        # Check if the UUID is not empty
        if [ -n "$EXTENSION_UUID" ]; then
            echo "Downloading and installing extension: $EXTENSION_UUID"
            
            # Fetch the download URL for the extension
            DOWNLOAD_URL=$(fetch_download_url "$EXTENSION_UUID")
            if [ -z "$DOWNLOAD_URL" ]; then
                echo "Skipping extension $EXTENSION_UUID due to missing download URL."
                continue
            fi
            
            # Download the extension
            wget -O /tmp/${EXTENSION_UUID}.zip "$DOWNLOAD_URL"
            
            # Check if the download was successful
            if [ ! -f "/tmp/${EXTENSION_UUID}.zip" ]; then
                echo "Error: Failed to download extension $EXTENSION_UUID."
                continue
            fi
            
	# Install the extension using gnome-extensions tool
    	sudo -u $USER gnome-extensions install /tmp/${EXTENSION_UUID}.zip
    
    	# Enable the extension
    	sudo -u $USER gnome-extensions enable "$EXTENSION_UUID"
            
            # Clean up the downloaded zip file
            rm /tmp/${EXTENSION_UUID}.zip
        else
            echo "Skipping empty UUID in extensions array."
        fi
    done

    echo "Installation complete."
}
gnome_extensions_main(){
	# Call the function to install GNOME extensions
	install_gnome_extensions
}

