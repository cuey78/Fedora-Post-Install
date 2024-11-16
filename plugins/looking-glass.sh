
#!/bin/bash
#-------------------------------------------------------------------------------------#
# Fedora Post-Installation Script                                                     #
# This script automates the configuration and installation of various software        #
# components on a Fedora system. It includes functions for downloading files using    #
# a web browser and installing Looking Glass.                                         #
#                                                                                     #
# Functions:                                                                          #
#   - download: Downloads a file using a detected web browser.                        #
#   - detect_browser: Detects available browsers (Chromium, Google Chrome, Firefox).  #
#   - install_looking_glass: Downloads and installs the Looking Glass client.         #
#                                                                                     #
# Usage:                                                                              #
#   This script is designed to be run as a plugin module as part of the Fedora        #
#   Post-Installation Script. It does not need to be executed separately.             #
# Prerequisites:                                                                      #
#   - The script assumes a Fedora system with a supported web browser installed.      #
#   - Internet connection is required for downloading files and packages.             #
#   - Additional dependencies may be required for Looking Glass installation.         #
#-------------------------------------------------------------------------------------#

# This function is responsible for downloading the Looking Glass client tar file from a specified URL.
# Example usage: download "looking-glass-client-B4.tar.gz" "https://looking-glass.io/downloads"
download() {
    local filename="$1"
    local url1="$2"
    local USER1=$(logname)

    # Function to detect available browser
    detect_browser() {
        if command -v chromium-browser &> /dev/null; then
            echo "chromium-browser"
        elif command -v google-chrome &> /dev/null; then
            echo "google-chrome"
        elif command -v firefox &> /dev/null; then
            echo "firefox"
        else
            echo "none"
        fi
    }

    browser=$(detect_browser)

    if [[ "$browser" == "none" ]]; then
        echo "No supported browsers found. Please install Chromium, Google Chrome, or Firefox."
        exit 1
    fi

    if [[ -f "$filename" ]]; then
        echo "File exists"
    else
        echo "Downloading $filename using $browser..."

        # Open the URL in the default web browser as the normal user
        runuser -u $USER1 -- $browser "$url1" &> /dev/null &

        # Wait for the browser to open and download the file
        sleep 5
        
        # Use xdotool to simulate the download action if needed (depends on the website behavior)
        # Example for Firefox:
        if [[ "$browser" == "firefox" ]]; then
            window_id=$(xdotool search --onlyvisible --name "Mozilla Firefox")
            xdotool windowactivate $window_id
            xdotool key --delay 200 Return
        fi

        # Wait for the user to download the file
        while [ ! -f "/home/$USER1/Downloads/$filename" ]; do
            echo "Waiting for $filename to be downloaded..."
            sleep 5
        done

        echo "$filename found in Downloads directory."
        echo "Moving $filename to the current directory..."
        mv "/home/$USER1/Downloads/$filename" .

        if [[ -f "$filename" ]]; then
            echo "$filename moved successfully."
        else
            echo "Failed to move $filename."
        fi
    fi
}

# Downloads and Builds and Installs Looking-glass-client and set permisions 
install_looking_glass_client() {
            # Initialize local variables for version selection and file handling
            local version=""
            local stable="looking-glass-B6.tar.gz"
            local rc1="looking-glass-B7-rc1.tar.gz"
            local url="https://looking-glass.io/artifact/stable/source/"
            local url2="https://looking-glass.io/artifact/rc/source/"
            local filestable="looking-glass-B6"
            local filerc1="looking-glass-B7-rc1"
            local filename=""

            # Use dialog to prompt user to select the release version of Looking Glass
            version=$(dialog --title "Looking Glass Version" --stdout --radiolist "Please select the Looking Glass release version:" 0 0 2 \
            1 "$stable" on \
            2 "$rc1" off)

            # Check if the user cancelled the dialog
            if [ "$version" = "" ]; then
               return
            fi

            # Conditional logic to handle different versions based on user selection
            if [ "$version" = "1" ]; then
                # Set filename and download the stable version of Looking Glass
                filename=$filestable
                download "$stable" "$url"
                # Extract the downloaded tar.gz file
                tar -xvzf "$filename.tar.gz"
            else
                # Set filename and download the release candidate version of Looking Glass
                filename=$filerc1
                download "$rc1" "$url2"
                # Extract the downloaded tar.gz file
                tar -xvzf "$filename.tar.gz"
            fi
            
           
            #Build and Install the Looking-Glass-Client tar -xvzf looking-glass-B6.tar.gz
            dnf install cmake gcc gcc-c++ libglvnd-devel fontconfig-devel spice-protocol make nettle-devel \
            pkgconf-pkg-config binutils-devel libXi-devel libXinerama-devel libXcursor-devel \
            libXpresent-devel libxkbcommon-x11-devel wayland-devel wayland-protocols-devel \
            libXScrnSaver-devel libXrandr-devel dejavu-sans-mono-fonts libdecor-devel pipewire-devel libsamplerate-devel pulseaudio-libs-devel libsamplerate-devel -y
            
            dir1=$(pwd)
            cd $filename
            mkdir client/build
            cd client/build
            cmake ..
            make install
            cd $dir1
            rm -rf $filename
            VIRT_USER=`logname`
                   

          # Prompt the user whether to manually edit the username using dialog
            USER_YN=$(dialog --stdout --defaultno --yesno "$VIRT_USER Will be Set to use Looking glass, Do you need to manually edit the username?" 0 0)

            # If the user chooses yes, prompt for a new username using dialog
            if [ "$USER_YN" = "0" ]; then
                USER_YN='n'
            while [ "$USER_YN" = "n" ]; do
                VIRT_USER=$(dialog --stdout --inputbox "Enter the new username:" 0 0)
                USER_YN=$(dialog --stdout --yesno "Is $VIRT_USER correct?" 0 0)
            done
            fi

            # Display the selected username
            dialog --infobox "User $VIRT_USER  has been Selected" 0 0
            
                    
            touch /dev/shm/looking-glass && chown $VIRT_USER:kvm /dev/shm/looking-glass && chmod 660 /dev/shm/looking-glass
            shm=""
            shm=("f /dev/shm/looking-glass 0660 $VIRT_USER kvm -")
            echo $shm > /etc/tmpfiles.d/10-looking-glass.conf
            
            #Set SELINUX permisions
            clear
            echo "Setting SELINUX permisions"
            ausearch -c 'qemu-system-x86' --raw | audit2allow -M my-qemusystemx86 &>/dev/null
            semodule -X 300 -i my-qemusystemx86.pp &>/dev/null
            setsebool -P domain_can_mmap_files 1 &>/dev/null
            clear
            
}
