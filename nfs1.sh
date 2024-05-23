#!/bin/bash

# Set your Wi-Fi SSID
WIFI_SSID=""
#Remote Shares
REMOTESHARE_1=""
REMOTESHARE_2=""
#Local Mount Point
LOCALMOUNT1=""
LOCALMOUNT2=""
# Check if Wi-Fi is connected
if nmcli | grep -q "$WIFI_SSID"; then
    echo "Wi-Fi is connected to $WIFI_SSID"

    # Add your NFS share mount commands here
    # For example:
    mount -t nfs $REMOTESHARE_1 $LOCALMOUNT1
    mount -t nfs $REMOTESHARE_2 $LOCALMOUNT2
# Add as many mount commands as needed

    echo "NFS shares reconnected successfully"
else
    echo "Wi-Fi is not connected to $WIFI_SSID. Exiting..."
fi
