#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Configuration Script                                       #
# This script assists in setting up virtualization environments and related           #
# configurations on a Fedora system. It includes functions for configuring IOMMU,     #
# setting up virtualization software, and other system configurations.                #
#                                                                                     #
# Functions:                                                                          #
#   - install_virtualization: Provides a menu for virtualization-related settings.    #
#   - configure_system: Configures system settings based on user input.               #
#   - configure_intel_iommu: Sets up Intel IOMMU.                                     #
#   - configure_amd_iommu: Sets up AMD IOMMU.                                         #
#   - enable_intel_gvt_service: Enables Intel GVT service for virtualization.         #
#   - VIRTMAN: Installs virtualization software.                                      #
#   - IOMMU_SETUP: Enables IOMMU and updates GRUB.                                    #
#   - virtman_noroot: Configures virt-manager to run as non-root.                     #
#   - evdev: Sets up evdev helper for keyboard/mouse passthrough.                     #
#   - ask_yes_no: Utility function for yes/no prompts.                                #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with necessary virtualization capabilities.  #
#   - Internet connection is required for downloading packages and updates.           #
#-------------------------------------------------------------------------------------#

# Main Menu to Install Virtualizaton
install_virtualization() {
    # Virtmanager / GPU Passthrough Menu

    while true; do
        CHOICE=$(dialog --clear \
                --title "Virtualization" \
                --nocancel \
                --menu "Choose an option:" \
                15 60 5 \
                1 "Install Virtualization Software" \
                2 "Enable IOMMU and Update GRUB" \
                3 "Install Looking Glass Client" \
                4 "Enable Intel GVT Service" \
                5 "Run Virt-Manager as Non-Root" \
                6 "Evdev Helper (keyboard /mouse passthrough)" \
                B "Back" \
                3>&1 1>&2 2>&3)

        clear
        case $CHOICE in
            1) VIRTMAN ;;
            2) IOMMU_SETUP ;;
            3) install_looking_glass_client ;;
            4) enable_intel_gvt_service ;;
            5) virtman_noroot ;;
            6) evdev ;;
            B) break ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

# Function to ask yes/no questions
ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Function to configure the system based on user input using dialog
configure_system() {
    # Check if INTEL is set to 1
    if [ "$INTEL" = "1" ]; then
        # Ask if Intel GVT support is required using dialog
        if dialog --title "Intel GVT Support" --yesno "Do you require Intel GVT support?" 7 60; then
            echo "Intel GVT support will be configured."
            # Add the code to configure Intel GVT support here
            GVT="1"
        else
            GVT="0"
            echo "Intel GVT support will not be configured."
        fi
    fi

    # Ask if user wants to passthrough a video and audio device using dialog
    if dialog --title "Device Passthrough" --yesno "Would you like to passthrough a video and audio device?" 7 60; then
        echo "Video and audio passthrough will be configured."
        select_device "VGA"
        vga_device_id="${selected_device_id}"
        vga_device_line="${selected_device_line}"
        select_device "Audio"
        hd_device_id="${selected_device_id}"
        hd_device_line="${selected_device_line}"
        parsed_VIDEO=$(echo "$vga_device_id" | tr -d '[]')
        parsed_AUDIO=$(echo "$hd_device_id" | tr -d '[]')
        echo "Selected VGA device: $parsed_VIDEO"
        echo "Selected HD device: $parsed_AUDIO"
        pass="1"
    else
        echo "Video and audio passthrough will not be configured."
        pass="0"
    fi

    # Ask if user wants to blacklist nouveau using dialog
    if dialog --title "Blacklist Nouveau" --yesno "Would you like to blacklist nouveau?" 7 60; then
        echo "Nouveau will be blacklisted."
        Nouveau="1"
    else
        Nouveau="0"
        echo "Nouveau will not be blacklisted."
    fi

    # Ask if user wants to blacklist amdgpu using dialog
    if dialog --title "Blacklist Amdgpu" --yesno "Would you like to blacklist amdgpu?" 7 60; then
        echo "Amdgpu will be blacklisted."
        Amdgpu="1"
    else
        Amdgpu="0"
        echo "Amdgpu will not be blacklisted."
    fi

    echo "Configuration complete."
}

# Helps Config for Intel CPU
configure_intel_iommu() {
    #asks what user wants to do
    configure_system
    # Check each variable and append corresponding strings to the result
    IOMMU=""
    IOMMU="intel_iommu=on"
    if [ "$GVT" -eq 1 ]; then
        intel1="i915.enable_gvt=1 i915.enable_guc=0"
        IOMMU="$IOMMU $intel1"
    fi

    if [ "$pass" -eq 1 ]; then
        intel2="pcie_aspm=off rd.driver.pre=vfio-pci vfio-pci.ids=$parsed_VIDEO,$parsed_AUDIO"
        IOMMU="$IOMMU $intel2"
    fi

    if [ "$Nouveau" -eq 1 ]; then
        intel3="rd.driver.blacklist=nouveau"
        IOMMU="$IOMMU $intel3"
    fi
    if [ "$Amdgpu" -eq 1 ]; then
        intel4="rd.driver.blacklist=amdgpu"
        IOMMU="$IOMMU $intel4"
    fi
  
}

#get Audio and Video Passthrough ID'S
select_device() {
    local device_type=$1
    local devices=$(lspci -nnk | grep -i "$device_type" | grep -oP '.*\[([0-9a-fA-F]{4}):([0-9a-fA-F]{4})\].*')

    if [ -z "$devices" ]; then
        dialog --msgbox "No $device_type devices found." 10 50
        return 1
    fi

    local index=0
    local device_ids=()
    local device_lines=()
    local device_menu=()
    while read -r device; do
        index=$((index+1))
        device_id=$(echo "$device" | grep -oP '\[([0-9a-fA-F]{4}):([0-9a-fA-F]{4})\]')
        device_ids+=("$device_id")
        device_lines+=("$device")
        device_menu+=("$index" "$device")
    done <<< "$devices"

    local choice=$(dialog --title "Select $device_type Device" --menu "Choose a device:" 15 70 10 "${device_menu[@]}" 3>&1 1>&2 2>&3)

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        dialog --msgbox "Invalid input. Please enter a number." 10 50
        return 1
    fi

    if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#device_ids[@]}" ]; then
        dialog --msgbox "Invalid selection. Please enter a valid number." 10 50
        return 1
    fi

    selected_device_id="${device_ids[$((choice-1))]}"
    selected_device_line="${device_lines[$((choice-1))]}"
    clear
}

#Helps Config IOMMU for AMD
configure_amd_iommu() {
   configure_system
    # Check each variable and append corresponding strings to the result
    IOMMU=""
    IOMMU="amd_iommu=on"

    if [ "$pass" -eq 1 ]; then
        AMD1="pcie_aspm=off rd.driver.pre=vfio-pci vfio-pci.ids=$parsed_VIDEO,$parsed_AUDIO"
        IOMMU="$IOMMU $AMD1"
    fi

    if [ "$Nouveau" -eq 1 ]; then
        AMD2="rd.driver.blacklist=nouveau"
        IOMMU="$IOMMU $AMD2"
    fi
    
    if [ "$Amdgpu" -eq 1 ]; then
        AMD3="rd.driver.blacklist=amdgpu"
        IOMMU="$IOMMU $AMD3"
    fi
}

#Detects AMD or INTEL
DETECT_CPU(){
            ####Detecting CPU
            CPU=$(lscpu | grep GenuineIntel | rev | cut -d ' ' -f 1 | rev )
            INTEL="0"
            if [ "$CPU" = "GenuineIntel" ]
	        then
	            INTEL="1" 
            else
                INTEL="0"
            fi
}

# IOMMU Setup for Intel CPU
IOMMU_SETUP(){
    clear
    #asks if need to delete vfio-pci-override-vga.sh
    if [ -e /sbin/vfio-pci-override-vga.sh ]; then 
        if dialog --yesno "Would you like to delete /sbin/vfio-pci-override-vga.sh?" 10 50; then
            # Attempt to delete the file
            if rm /sbin/vfio-pci-override-vga.sh; then
                dialog --msgbox "File deleted successfully." 10 50
            else
                dialog --msgbox "Failed to delete the file." 10 50
            fi
        else
            dialog --msgbox "File deletion canceled." 10 50
        fi
    fi
    if check_grub_cmdline = 1; then
        return 1  # Stop current function and return to menu
    else
            
    ##Creating backups
    dialog --infobox "Creating backups" 10 50
    sleep 2

    cat /etc/default/grub > grub_backup

    if [ -a /etc/modprobe.d/local.conf ]
    then 
        mv /etc/modprobe.d/local.conf modprobe.backup
    fi

    if [ -a /etc/dracut.conf.d/local.conf ]
    then 
        mv /etc/dracut.conf.d/local.conf local.conf.backup
    fi
     
    echo "install vfio-pci /sbin/vfio-pci-override-vga.sh" > /etc/modprobe.d/local.conf

    cp local.conf /etc/dracut.conf.d/local.conf
    
    cp /etc/default/grub new_grub
    # Detect cpu type
    DETECT_CPU
    if [ "$INTEL" -eq 1 ]; then
        configure_intel_iommu
    else
        configure_amd_iommu
    fi
    #Putting together new grub string
    OLD_OPTIONS=`cat new_grub | grep GRUB_CMDLINE_LINUX | cut -d '"' -f 1,2`

    NEW_OPTIONS="$OLD_OPTIONS $IOMMU\""
    echo $NEW_OPTIONS

    #Rebuilding grub 
    sed -i -e "s|^GRUB_CMDLINE_LINUX.*|${NEW_OPTIONS}|" new_grub

    #User verification of new grub and prompt to manually edit it
    NEW_GRUB_CONTENTS=$($new_grub)
    
    if dialog --yesno "Would you like to view/edit the Grub file?" 10 50; then
        nano new_grub
    fi

    cp new_grub /etc/default/grub

    # Check if passthrough is required
    if [ "$pass" = "1" ]; then
        # Copying necessary scripts
        dialog --infobox "Getting GPU passthrough scripts ready" 10 50
        sleep 2

        cp ./service/vfio-pci-override-vga.sh /sbin/vfio-pci-override-vga.sh

        chmod 755 /sbin/vfio-pci-override-vga.sh

        echo "install vfio-pci /sbin/vfio-pci-override-vga.sh" > /etc/modprobe.d/local.conf

               cp ./service/local.conf /etc/dracut.conf.d/local.conf
    fi
    
    dialog --infobox "Updating grub and generating initramfs" 10 50
    sleep 2
    
    #update grub
    update_grub_config &>/dev/null

    dracut -f --kver `uname -r` &>/dev/null
    fi
}

#Intel GVT surport
enable_intel_gvt_service() {
    clear
    echo "=========================================="
    echo "|   Enable INTEL GVT SERVICE             |"
    echo "=========================================="
    modprobe kvmgt mdev vfio-iommu-type1
    GPU=""
    MAX=0
    UUID=$(uuidgen)
    VIRT_USER=$(logname)

    # Finding the Intel GPU and choosing the one with the highest weight value
    for i in $(find /sys/devices/pci* -name 'mdev_supported_types'); do
        for y in $(find "$i" -name 'description'); do
            WEIGHT=$(cat "$y" | tail -1 | cut -d ' ' -f 2)
            if [ "$WEIGHT" -gt "$MAX" ]; then
                GPU=$(echo "$y" | cut -d '/' -f 1-7)
                MAX="$WEIGHT"
            fi
        done
    done

    if [ -n "$GPU" ]; then
        echo "<hostdev mode='subsystem' type='mdev' managed='no' model='vfio-pci' display='off'>" > virsh.txt
        echo "<source>" >> virsh.txt
        echo "<address uuid=\"$UUID\"/>" >> virsh.txt
        echo "</source>" >> virsh.txt
        echo "</hostdev>" >> virsh.txt

        # Initializing virtual GPU on every startup
        echo "modprobe kvmgt mdev vfio-iommu-type1" >> ./service/gvt_pe.sh
        echo "echo $UUID > $GPU/create" >> ./service/gvt_pe.sh

        # Create a systemd service to initialize the GPU on startup
        cp ./service/gvt_pe.service /etc/systemd/system/gvt_pe.service
        chmod 644 /etc/systemd/system/gvt_pe.service

        mv ./service/gvt_pe.sh /usr/bin/gvt_pe.sh
        chmod +x /usr/bin/gvt_pe.sh
        systemctl enable gvt_pe.service
        systemctl start gvt_pe.service

        chown "$VIRT_USER" virsh.txt
    else
        dialog --msgbox "No Intel GPU found with mdev_supported_types. If you have enabled GVT in IOMMU options, please reboot first." 10 50
    fi
}

# Install Virtualization Software
VIRTMAN(){
    clear
    echo "=========================================="
    echo "|   Installing Virtualization Software   |"
    echo "=========================================="
    dnf install qemu qemu-img nano -y
    dnf groupinstall "Virtualization" -y
}

# Run Virtmanager as non root
virtman_noroot(){
     # Check if the file exists
    conf_file="/etc/libvirt/libvirtd.conf"
    if [ -f "$conf_file" ]; then
        # Uncomment specific lines
        sed -i '/^#unix_sock_group/s/^#//' "$conf_file"
        sed -i '/^#unix_sock_rw_perms/s/^#//' "$conf_file"

        # Verify changes
        echo "Changes made to $conf_file:"
        grep -E '^unix_sock_group|^unix_sock_rw_perms' "$conf_file"
    else
        echo "$conf_file not found."
        return 1
    fi

   # Check if libvirt group exists
    if ! getent group | grep -q "^libvirt:"; then
        dialog --msgbox "libvirt group does not exist." 0 0
        return 1
    fi

    # Check if the current user is already in the libvirt group
    if groups "$(logname)" | grep -q '\blibvirt\b'; then
         dialog --msgbox "Current user is already in the libvirt group." 0 0
         return 1
    else
        # Add the current user to the libvirt group
        usermod -a -G libvirt "$(logname)"
        dialog --msgbox "Added $(logname) to the libvirt group." 0 0
        return 1
    fi

    # Activate changes by switching to the libvirt group
    newgrp libvirt

    # Restart or start libvirtd service
    if systemctl is-active --quiet libvirtd.service; then
        echo "Restarting libvirtd service..."
        systemctl restart libvirtd.service
    else
        echo "Starting libvirtd service..."
        systemctl start libvirtd.service
    fi
    dialog --msgbox "Virtmnger as Non Root Active" 0 0
    return 1
}
# Function to update QEMU configuration
evdev_config() {
    local METHOD="by-id"
    local KBD_COUNT=1
    local MOUSE_COUNT=1

    if [[ $1 == "by-path" ]]; then
        METHOD="by-path"
    fi

    # This needs to run with elevated privileges
    if [ $EUID -ne 0 ]; then
        echo "Please run this as root!"
        exit 1
    fi

    # Checking for evdev devices, removing old changes, updating qemu.conf
    mod_qemu $METHOD

    local NEW_DOMAIN="<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>"

    echo $NEW_DOMAIN > evdev.txt
    echo "" >> evdev.txt

    echo " <qemu:commandline>" >> evdev.txt

    for entry in $(ls -l /dev/input/$METHOD/ | grep "event*"); do
        KBD_M=$(echo "$entry" | rev | cut -c -4 | rev)
        if [ "$KBD_M" = "ouse" ]; then
            echo "    <qemu:arg value='-object'/>" >> evdev.txt
            echo "    <qemu:arg value='input-linux,id=mouse${MOUSE_COUNT},evdev=/dev/input/$METHOD/$entry'/>" >> evdev.txt
            ((++MOUSE_COUNT))
        elif [ "$KBD_M" = "-kbd" ]; then
            echo "    <qemu:arg value='-object'/>" >> evdev.txt
            echo "    <qemu:arg value='input-linux,id=kbd${KBD_COUNT},evdev=/dev/input/$METHOD/$entry,grab_all=on,repeat=on'/>" >> evdev.txt
            ((++KBD_COUNT))
        fi
    done

    echo "  </qemu:commandline>" >> evdev.txt

    dialog msgbox "Success! Results are in evdev.txt" 0 0
}

# Function to modify QEMU configuration
mod_qemu() {
    local METHOD="by-id"

    if [[ $1 == "by-path" ]]; then
        METHOD="by-path"
    fi

    # Deleting old temporary qemu.conf files
    if [ -a .temp.qemu.conf ]; then
        rm .temp.qemu.conf
    fi

    # Create a backup copy of /etc/libvirt/qemu.conf
    if ! [ -a .backup.qemu.conf ]; then
        # Ensuring that apparmor does not block it
        if [ -a /etc/apparmor.d/abstractions/libvirt-qemu ]; then
            echo "/dev/input/* rw," >> /etc/apparmor.d/abstractions/libvirt-qemu
        fi

        cp /etc/libvirt/qemu.conf .backup.qemu.conf
    fi

    cp /etc/libvirt/qemu.conf .temp.qemu.conf

    echo ' ' >> .temp.qemu.conf
    echo 'cgroup_device_acl = [' >> .temp.qemu.conf
    echo '    "/dev/null", "/dev/full", "/dev/zero",' >> .temp.qemu.conf
    echo '    "/dev/random", "/dev/urandom",' >> .temp.qemu.conf
    echo '    "/dev/ptmx", "/dev/kvm", "/dev/kqemu",' >> .temp.qemu.conf
    echo '    "/dev/rtc","/dev/hpet",' >> .temp.qemu.conf

    for entry in $(ls -l /dev/input/$METHOD/ | grep "event*"); do
        KBD_M=$(echo "$entry" | rev | cut -c -4 | rev)
        if [ "$KBD_M" = "ouse" ]; then
            echo '    "/dev/input/'$METHOD'/'$entry'",' >> .temp.qemu.conf
        elif [ "$KBD_M" = "-kbd" ]; then
            echo '    "/dev/input/'$METHOD'/'$entry'",' >> .temp.qemu.conf
        fi
    done

    echo "]" >> .temp.qemu.conf
    echo "" >> .temp.qemu.conf
    echo 'user = "root"' >> .temp.qemu.conf
    echo 'group = "root"' >> .temp.qemu.conf
    echo "" >> .temp.qemu.conf
    echo "clear_emulator_capabilities = 0" >> .temp.qemu.conf

    OLD_PERMISSIONS="#security_default_confined = 1"
    NEW_PERMISSIONS="security_default_confined = 0"

    sed -i -e "s|${OLD_PERMISSIONS}|${NEW_PERMISSIONS}|" .temp.qemu.conf

    cp .temp.qemu.conf /etc/libvirt/qemu.conf
    rm .temp.qemu.conf
    systemctl restart libvirtd

    dialog --msgbox "Done: /etc/libvirt/qemu.conf was successfully modified" 0 0
}

undo_evdev()
{
    if [ -a .backup.qemu.conf ]; then
        cp .backup.qemu.conf /etc/libvirt/qemu.conf
        dialog --msgbox "qemu.conf was successfully modified" 0 0
    else
        dialog --msgbox "No changes made to qemu.conf" 0 0
    fi
}

evdev(){
    local choice

    choice=$(dialog --clear --backtitle "EVDEV Helper Configuration" \
    --title "Select Method" \
    --menu "Choose one of the following options:" 15 50 3 \
    "by-id" "Use by-id for evdev Helper" \
    "by-path" "Use by-path for evdev Helper" \
    "uninstall" "Uninstall evdev Helper configuration" \
    3>&1 1>&2 2>&3)

    clear

    case $choice in
        "by-id")
            evdev_config
            ;;
        "by-path")
           evdev_config by-path
            ;;
        "uninstall")
            undo_evdev
            # Call your function or script for uninstall
            ;;
        *)
            echo "No valid option selected"
            ;;
    esac
}
