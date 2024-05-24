#!/bin/bash
clear
#Making sure this script runs with elevated privileges
if [ $EUID -ne 0 ]
	then
		echo "Please run this as root!" 
		exit 1
fi

# Define functions for each menu option
option1() {
    echo "Fix and Clean Dnf"
    
    # DNF setting
    echo "fastestmirror=true" >> /etc/dnf/dnf.conf
    echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
    echo "countme=false" >> /etc/dnf/dnf.conf

    # Clean Cache DNF
    dnf clean all
    dnf upgrade -y
    clear
}

option2() {
    echo "Check for Firmware update"
    
    # Firmware update if supported
    if command -v fwupdmgr >/dev/null 2>&1; then
       fwupdmgr get-devices
       fwupdmgr refresh --force
       fwupdmgr get-updates -y && fwupdmgr update -y
    fi
    clear
}

option3() {
    echo "Install RPM Fusion"
    # Add your functionality here
    fedora_version=$(rpm -E %fedora)
        
    rpmfusion_free_url=https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm
    rpmfusion_nonfree_url=https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm

    dnf install -y --nogpgcheck "$rpmfusion_free_url" "$rpmfusion_nonfree_url"
    dnf install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data 
    dnf install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted
    clear
}

option4() {
    # Check for rpmfusion-free repository
    free_repo=$(dnf repolist all | grep -i 'rpmfusion-free')

    # Check for rpmfusion-nonfree repository
    nonfree_repo=$(dnf repolist all | grep -i 'rpmfusion-nonfree')

    # Determine if the repositories are installed
    if [[ -n "$free_repo" && -n "$nonfree_repo" ]]; then
        function show_menu() {
    clear
    echo "===================="
    echo "   Main Menu"
    echo "===================="
    echo "1. Mesa FreeWorld Drivers - AMD"
    echo "2. Intel Media Driver"
    echo "B. Back"
    echo "===================="
    echo -n "Please enter your choice: "
}

while true; do
    show_menu
    read choice
    case $choice in
        1)
            # Mesa Freeworld Driver
            echo "Swaping to Mesa Freeworld Drivers"
            sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
            sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
            sleep 1
            ;;
        2)
            # Intel Media Driver
            echo "Install Intel Media Driver"
            dnf install -y intel-media-driver
            sleep 1
            ;;
        [Bb])
            echo "Going back..."
            sleep 1
            break
            ;;
        *)
            echo "Invalid choice. Please try again."
            sleep 1
            ;;
    esac
done

echo "Exited the menu."
    else
        echo "============================"
        echo "|  Enable Rpmfusion First  |"
        echo "============================"
        sleep 5
        clear
    fi
    
}

option5() {
    echo "=========================="
    echo "|  Install Media Codecs  |"
    echo "=========================="
    # Check for rpmfusion-free repository
    free_repo=$(dnf repolist all | grep -i 'rpmfusion-free')

    # Check for rpmfusion-nonfree repository
    nonfree_repo=$(dnf repolist all | grep -i 'rpmfusion-nonfree')

    # Determine if the repositories are installed
    if [[ -n "$free_repo" && -n "$nonfree_repo" ]]; then
    # Install Codecs
    dnf update -y
    dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
    dnf install -y lame* --exclude=lame-devel
    dnf group upgrade -y --with-optional Multimedia
    else
        echo "============================"
        echo "|  Enable Rpmfusion First  |"
        echo "============================"
        sleep 5
        clear
    fi
    
   
} 

option6() {
    echo "Enable Flatpak"
    # Install Flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

option7() {
    echo "Install Google Chrome"
    # Add your functionality here
    #install chrome
    #wget https://www.google.com/chrome/next-steps.html?statcb=0&installdataindex=empty&defaultbrowser=0#
        dnf install -y fedora-workstation-repositories
        dnf config-manager --set-enabled google-chrome
        dnf -y install google-chrome-stable
}

option8() {
    echo "Install Virtualization"
    # Install Virtualization
    if [ -a /sbin/vfio-pci-override-vga.sh ]
	then 
	    echo "Looks like Virtualization has been Installed Please Uninstall First and then ReInstall."iv
    fi
    clear
    function show_menu() {
    #clear
    echo "======================="
    echo "   Virtualization Menu"
    echo "======================="
    echo "1. Install Required packages"
    echo "2. Enable IOMMU and Update Grub"
    echo "3. Install Looking-Glass-Client"
    echo "4. Enable Intel GVT Service"
    echo "B. Back"
    echo "===================="
    echo -n "Please enter your choice: "
}

while true; do
    show_menu
    read choice
    case $choice in
        1)
            clear
            echo "=========================================="
            echo "|   Installing Virtalization Software    |"
            echo "=========================================="
            dnf install qemu qemu-img nano -y
            dnf groupinstall "Virtualization" -y
            ;;
        2)
            clear
            echo "You chose Option 2."
            ##Creating backups
            echo  "Creating backups"

            cat /etc/default/grub > grub_backup

            if [ -a /etc/modprobe.d/local.conf ]
	        then 
	            mv /etc/modprobe.d/local.conf modprobe.backup
            fi

            if [ -a /etc/dracut.conf.d/local.conf ]
	        then 
	            mv /etc/dracut.conf.d/local.conf local.conf.backup
            fi

            cp /etc/default/grub new_grub

            ####Detecting CPU
            CPU=$(lscpu | grep GenuineIntel | rev | cut -d ' ' -f 1 | rev )
            INTEL="0"

            if [ "$CPU" = "GenuineIntel" ]
	            then
	            INTEL="1"
            fi

            #Building string Intel or AMD iommu=on
            if [ $INTEL = 1 ]
	        then
	        IOMMU="intel_iommu=on rd.driver.pre=vfio-pci kvm.ignore_msrs=1 i915.enable_gvt=1 i915.enable_guc=0"
	        echo "Set Intel IOMMU On"
	        else
	        IOMMU="amd_iommu=on rd.driver.pre=vfio-pci kvm.ignore_msrs=1"
	        echo "Set AMD IOMMU On"
            fi

            #Putting together new grub string
            OLD_OPTIONS=`cat new_grub | grep GRUB_CMDLINE_LINUX | cut -d '"' -f 1,2`

            NEW_OPTIONS="$OLD_OPTIONS $IOMMU\""
            echo $NEW_OPTIONS

            #Rebuilding grub 
            sed -i -e "s|^GRUB_CMDLINE_LINUX.*|${NEW_OPTIONS}|" new_grub

            #User verification of new grub and prompt to manually edit it
            echo 
            echo "Grub was modified to look like this: "
            echo `cat new_grub | grep "GRUB_CMDLINE_LINUX"`
            echo 
            echo "Do you want to edit it? y/n"
            read YN

            if [ $YN = y ]
            then
                nano new_grub
            fi

            cp new_grub /etc/default/grub

            #Copying necessary scripts
            echo "Getting GPU passthrough scripts ready"

            cp vfio-pci-override-vga.sh /sbin/vfio-pci-override-vga.sh

            chmod 755 /sbin/vfio-pci-override-vga.sh

            echo "install vfio-pci /sbin/vfio-pci-override-vga.sh" > /etc/modprobe.d/local.conf

            cp local.conf /etc/dracut.conf.d/local.conf

            echo "Updating grub and generating initramfs"

            grub2-mkconfig -o /boot/grub2/grub.cfg
            grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
            dracut -f --kver `uname -r`
            sleep 1
            ;;
        3)
            echo "You chose Option 3."
            sleep 1
            dnf install cmake gcc gcc-c++ libglvnd-devel fontconfig-devel spice-protocol make nettle-devel \
            pkgconf-pkg-config binutils-devel libXi-devel libXinerama-devel libXcursor-devel \
            libXpresent-devel libxkbcommon-x11-devel wayland-devel wayland-protocols-devel \
            libXScrnSaver-devel libXrandr-devel dejavu-sans-mono-fonts libdecor-devel pipewire-devel libsamplerate-devel pulseaudio-libs-devel libsamplerate-devel -y
            tar -xvzf looking-glass-B6.tar.gz
            dir1=$(pwd)
            cd looking-glass-B6
            mkdir client/build
            cd client/build
            cmake ..
            make install
            cd $dir1
            rm -rf looking-glass-B6
            VIRT_USER=`logname`
            #Identifying user to set permissions
            echo 
            echo "User: $VIRT_USER will be using Looking Glass on this PC. "
            echo "If that's correct, press (y) otherwise press (n) and you will be able to specify the user."
            echo 
            echo "y/n?"
            read USER_YN
            

            #Allowing the user to manually edit the Looking Glass user
            if [ $USER_YN = 'n' ] || [ $USER_YN = 'N' ]
	        then
            USER_YN='n'
		    while [ '$USER_YN' = "n" ]; do
			    echo "Enter the new username: "
			    read VIRT_USER
    			echo "Is $VIRT_USER correct (y/n)?"
	    		read USER_YN
		    done
            fi
            echo User $VIRT_USER selected. Press any key to continue:
            read ANY_KEY
                    
            touch /dev/shm/looking-glass && chown $VIRT_USER:kvm /dev/shm/looking-glass && chmod 660 /dev/shm/looking-glass
            shm=""
            shm=("f /dev/shm/looking-glass 0660 $VIRT_USER kvm -")
            echo $shm > /etc/tmpfiles.d/10-looking-glass.conf
            clear
            ;;
        4)
            echo "You chose Option 4."
            clear
            sleep 1
            ;;
        [Bb])
            echo "Going back..."
            sleep 1
            break
            ;;
        *)
            echo "Invalid choice. Please try again."
            sleep 1
            ;;
    esac
done

echo "Exited the menu."

}

option9() {
  while true; do
    # Clear the screen for better readability
    clear

    # Display menu options
    echo "Please choose an option:"
    echo "1. WIFI NFS Shares"
    echo "2. NFS Shares Via FSTAB ( WIRED ONLY )"
    echo "b. Back"
    echo

    # Read user input
    read -p "Enter your choice: " choice

    case $choice in
        1)
            clear #clear screen
            echo "Enable Wifi NFS Shares"
            # Function to update the nfs1.sh script
            # Ask for Wi-Fi SSID
            #read -p "Enter the Wi-Fi SSID: " WIFI_SSID
            # List available Wi-Fi networks and let the user select one
            echo "Scanning for available Wi-Fi networks..."
            AVAILABLE_SSIDS=$(nmcli -t -f SSID dev wifi | sort -u)

            if [ -z "$AVAILABLE_SSIDS" ]; then
                echo "No Wi-Fi networks found. Exiting..."
                exit 1
            fi

            echo "Available Wi-Fi networks:"
            IFS=$'\n'
            select SSID in $AVAILABLE_SSIDS; do
                if [ -n "$SSID" ]; then
                    WIFI_SSID="$SSID"
                break
                else
                    echo "Invalid selection. Please try again."
                fi
            done
            unset IFS

            echo "Selected Wi-Fi SSID: $WIFI_SSID"
    
            # Ask for remote shares
            read -p "Enter the first remote share (e.g., 10.0.0.10:/mnt/data/General): " REMOTESHARE_1
            read -p "Enter the second remote share (e.g., 10.0.0.10:/mnt/data/Plex): " REMOTESHARE_2

            # Ask for local mount points
            read -p "Enter the first local mount point (e.g., /mnt/General): " LOCALMOUNT1
            read -p "Enter the second local mount point (e.g., /mnt/jellyfin): " LOCALMOUNT2

            # Create local mount points if they do not exist
            [ ! -d "$LOCALMOUNT1" ] && mkdir -p "$LOCALMOUNT1"
            [ ! -d "$LOCALMOUNT2" ] && mkdir -p "$LOCALMOUNT2"

            # Path to the nfs1.sh script
            NFS_SCRIPT="nfs1.sh"

            # Use sed to update the nfs1.sh script with the new values
            sed -i "s/^WIFI_SSID=.*/WIFI_SSID=\"$WIFI_SSID\"/" $NFS_SCRIPT
            sed -i "s|^REMOTESHARE_1=.*|REMOTESHARE_1=\"$REMOTESHARE_1\"|" $NFS_SCRIPT
            sed -i "s|^REMOTESHARE_2=.*|REMOTESHARE_2=\"$REMOTESHARE_2\"|" $NFS_SCRIPT
            sed -i "s|^LOCALMOUNT1=.*|LOCALMOUNT1=\"$LOCALMOUNT1\"|" $NFS_SCRIPT
            sed -i "s|^LOCALMOUNT2=.*|LOCALMOUNT2=\"$LOCALMOUNT2\"|" $NFS_SCRIPT
            #Inform User Changes made
            echo "The nfs1.sh script has been updated successfully."
            sleep 2
            #install Service
            cp nfs-start.service /etc/systemd/system/
            cp nfs1.sh /usr/bin/
            systemctl enable nfs-start.service
            systemctl start nfs-start.service
            ;;

        2)
            # Connect NFS Shares VIA FSTAB
            # Function to add NFS entry to /etc/fstab
            clear # clear screen
            echo "NFS Shares Via FSTAB ( WIRED ONLY )"
            add_to_fstab() {
                local nfs_share=$1
                local mount_point=$2
                local options="rw,sync,hard,intr,rsize=8192,wsize=8192,timeo=14"

                # Backup /etc/fstab before making changes (only once)
                if [ ! -f /etc/fstab.bak ]; then
                    cp /etc/fstab /etc/fstab.bak
                fi

                # Append the NFS entry to the end of /etc/fstab
                echo "${nfs_share} ${mount_point} nfs ${options} 0 0" >> /etc/fstab

                echo "Added ${nfs_share} to /etc/fstab"
            }

            # Prompt the user for the number of shares to add
            read -p "How many NFS shares would you like to add? " num_shares

            for (( i=1; i<=num_shares; i++ )); do
            # Prompt the user for the NFS share and mount point
            read -p "Enter the NFS share #$i (e.g., server:/path): " nfs_share
            read -p "Enter the mount point #$i (e.g., /mnt/nfs): " mount_point

            # Create the mount point directory if it doesn't exist
            if [ ! -d "${mount_point}" ]; then
                mkdir -p "${mount_point}"
                echo "Created mount point directory ${mount_point}"
            else
                echo "Mount point directory ${mount_point} already exists"
            fi

            # Add the NFS entry to /etc/fstab
            add_to_fstab "${nfs_share}" "${mount_point}"
            done

            # Mount all NFS shares
            mount -a

            echo "All specified NFS shares have been mounted."
            ;;

        b|B)
            # Back option: exit the loop
            echo "Going back..."
            break
            ;;

        *)
            # Invalid option
            echo "Invalid choice. Please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
done  
  
}

option10() {
    while true; do
        # Clear the screen for better readability
        clear
        echo "==============================="
        echo "|    Fedora Theme Fix         |"
        echo "|                             |"
        echo "==============================="
        # Display menu options
        echo "Please choose an option:"
        echo "1. Fix Fedora grub boot screen"
        echo "2. Fix Fedora Default KDE Splash"
        echo "b. Back"
        echo

        # Read user input
        read -p "Enter your choice: " choice

    case $choice in
        1)
             #Fix Fedora Grub Boot Screen
        GRUB_FILE="/etc/default/grub"
        SEARCH_LINE='GRUB_TERMINAL_OUTPUT="console"'
        COMMENTED_LINE='#GRUB_TERMINAL_OUTPUT="console"'
        THEME_LINE='GRUB_THEME="/boot/grub2/theme/fedora/theme.txt"'

        # Check if the GRUB file exists
        if [[ ! -f "$GRUB_FILE" ]]; then
            echo "Error: $GRUB_FILE does not exist."
            exit 1
        fi

        # Use sed to comment out the search line and add the theme line
        if grep -q "^$SEARCH_LINE" "$GRUB_FILE"; then
        # Create a backup of the original file
            cp "$GRUB_FILE" "${GRUB_FILE}.bak"
    
        # Use sed to perform the required changes
            sed -i "s|^$SEARCH_LINE|$COMMENTED_LINE\n$THEME_LINE|" "$GRUB_FILE"
            echo "Updated $GRUB_FILE successfully."
        else
            echo "Line $SEARCH_LINE not found in $GRUB_FILE."
        fi
        # Source and destination directories
        SOURCE_DIR="theme"
        DEST_DIR="/boot/grub2/theme"
            su -c "mkdir /boot/grub2/theme" root
            sleep 10
        #Copy the directory and all its contents
            su -c "cp -r "$SOURCE_DIR"/* "$DEST_DIR"" root
            echo "Directory $SOURCE_DIR copied to $DEST_DIR successfully."
            sleep 5
            grub2-mkconfig -o /boot/grub2/grub.cfg
            grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
            ;;

        2)
            USER2=$(logname)
            TAR_FILE="FedoraMinimal.tar.gz"
            SOURCE_DIR="FedoraMinimal"
            DEST_DIR="/home/$USER2/.local/share/plasma/look-and-feel/$SOURCE_DIR"

            # Extract the tar.gz file
            echo "Extracting $TAR_FILE..."
            tar -xzf "$TAR_FILE" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Error extracting $TAR_FILE."
                exit 1
            fi

            # Ensure the source directory was extracted
            if [ ! -d "$SOURCE_DIR" ]; then
                echo "Source directory $SOURCE_DIR not found after extraction."
                exit 1
            fi

            # Create the destination directory
            echo "Creating destination directory $DEST_DIR..."
            runuser -u "$USER2" -- mkdir -p "$DEST_DIR"
            if [ $? -ne 0 ]; then
                echo "Error creating destination directory $DEST_DIR."
                exit 1
            fi

            # Copy the files
            echo "Copying files from $SOURCE_DIR to $DEST_DIR..."
            runuser -u "$USER2" -- cp -r "$SOURCE_DIR"/* "$DEST_DIR"
            if [ $? -ne 0 ]; then
                echo "Error copying files to $DEST_DIR."
                exit 1
            fi

            echo "Files copied from $SOURCE_DIR to $DEST_DIR successfully."

            # Define the target file
            FILE="$HOME/.config/ksplashrc"

            # Write the specified lines to the ksplashrc file
            echo -e "[KSplash]\nTheme=FedoraMinimal" > "$FILE"

            # Print a success message
            echo "Fedora KDE Splash Screen Theme Fixed."

            # Pause to give user time to read the final message
            sleep 5
            ;;

        b|B)
            # Back option: exit the loop
            echo "Going back..."
            break
            ;;

        *)
            # Invalid option
            echo "Invalid choice. Please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
done  
        
}

# Function to display the menu
display_menu() {
    clear
    echo "====================================="
    echo "|    Fedora Post Install Script      | "
    echo "|            By Cuey                 |"
    echo "====================================="
    echo "Select an option:"
    echo "1. Update Dnf Settings /  Clean Dnf"
    echo "2. Update Firmware"
    echo "3. Install RPM Fusion"
    echo "4. Install Non Free Video Drivers"
    echo "5. Install Media Codecs"
    echo "6. Enable Flathub"
    echo "7. Install Google Chrome"
    echo "8. Install Virtualization"
    echo "9. Enable Wifi NFS Shares / FSTAB NFS Shares"
    echo "10. Fedora Theme Fixs"
    echo "Q. Quit"
}

#mark scripts as executable
execsh() {
    # Find all .sh files in the current directory
    sh_files=$(find . -maxdepth 1 -type f -name "*.sh")

    # Loop through each .sh file and mark it as executable
    for file in $sh_files; do
        chmod +x "$file" 
        echo "Marked $file as executable."
    done
}

#Downloads looking-glass tar file
download() {
    if [[ -f "looking-glass-B6.tar.gz" ]]; then echo "File exists"; 
    else 
        url1="https://looking-glass.io/artifact/stable/source"
        USER1=$(logname)

        # Open the URL in the default web browser as the normal user
        runuser -u $USER1 -- xdg-open "$url1" &> /dev/null &&
   
        filename="looking-glass-B6.tar.gz"

        # Check if the file exists in the Downloads directory
        if [ -f "/home/"$USER1"/Downloads/$filename" ]; then
            echo "$filename found in Downloads directory."
            echo "Moving $filename to the current directory..."
            mv "/home/"$USER1"/Downloads/$filename" .
            echo "$filename moved successfully."
        else
            echo "$filename not found in Downloads directory."
        fi
    fi
   
}

# Main function
main() {
    while true; do
        display_menu
        read -p "Enter your choice: " choice
        case $choice in
            1) option1 ;;
            2) option2 ;;
            3) option3 ;;
            4) option4 ;;
            5) option5 ;;
            6) option6 ;;
            7) option7 ;;
            8) option8 ;;
            9) option9 ;;
            10) option10 ;;
            [qQ]) echo "Exiting..." ; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
}

#sets scripts in current Dir to execute 
execsh

#checks for looking-glass tar file in current dir if not downloads it
download

#waits for 5sec
sleep 5

#calls main Fuction
main
