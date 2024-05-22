#!/bin/bash

# Set your Wi-Fi SSID
WIFI_SSID="Optus_A81151"
sleep 10
# Check if Wi-Fi is connected
if nmcli | grep -q "$WIFI_SSID"; then
    echo "Wi-Fi is connected to $WIFI_SSID"

    # Add your NFS share mount commands here
    # For example:
    #mount -t nfs 10.0.0.10:/mnt/Appz /home/cuey/Nfs/Appz
    mount -t nfs 10.0.0.10:/mnt/data/General /mnt/General
    mount -t nfs 10.0.0.10:/mnt/data/Plex /mnt/jellyfin
# Add as many mount commands as needed

    echo "NFS shares reconnected successfully"
else
    echo "Wi-Fi is not connected to $WIFI_SSID. Exiting..."
fi
