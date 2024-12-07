#!/bin/bash
#---------------------------------------------------------------------------------------#
# Fedora Post-Installation Script for GRUB and Theme Configuration                      #
# This script provides utilities to configure GRUB settings and apply theme fixes       #
# for a Fedora system. It includes functions to modify GRUB command lines, update       #
# GRUB timeout, fix GRUB themes, and manage KDE splash screens.                         #
#                                                                                       #
# Functions:                                                                            #
#   - add_exclude_to_updates_repo: Adds kernel exclusion to the updates repository.     #
#   - update_kernel: Updates the kernel using the sentry/kernel-fsync COPR repository.  #
#   - remove_exclude_from_updates_repo: Removes kernel exclusion from updates repo.     #
#   - remove_copr_repo: Disables and removes the specified COPR repository.             #
#   - change_kernel: Adds kernel exclusion and updates to Nobara fsync kernel.          #
#   - stock_kernel: Removes kernel exclusion and COPR repo to return to stock kernel.   #
#   - kernel_menu: Displays a menu for kernel management options.                       #
#                                                                                       #
# Usage:                                                                                #
#   This script is designed to be run as a plugin module as part of the Fedora          #
#   Post-Installation Script. It does not need to be executed separately.               #
# Prerequisites:                                                                        #
#   - The script assumes a Fedora system with GRUB and KDE installed.                   #
#   - Dialog and sed utilities are required.                                            #
#---------------------------------------------------------------------------------------#

# Function to add kernel exclusion to the updates repository
add_exclude_to_updates_repo() {
    local repo_file="/etc/yum.repos.d/fedora-updates.repo"
    local backup_file="${repo_file}.bak"
    local exclude_line="exclude=kernel*"

    if [[ ! -f "$repo_file" ]]; then
        echo "Repository file not found: $repo_file"
        return 1
    fi

    # Create a backup of the original file
    cp "$repo_file" "$backup_file"
    echo "Backup created at: $backup_file"

    # Add exclude=kernel* directly after skip_if_unavailable=False in the [updates] section
    sed -i.bak -e '/^\[updates\]/,/^\[/{ /^\[updates\]/!{/^\[/b; /skip_if_unavailable=False/a\
'"$exclude_line"'
    }; }' "$repo_file"

    echo "Updated $repo_file with exclude=kernel* in the [updates] section."
}

# Function to update the kernel using the  sentry/kernel-blu  COPR repository
update_kernel() {
    echo "Enabling the sentry/kernel-fsync COPR repository..."
    sudo dnf copr enable sentry/kernel-blu  -y

    echo "Updating the system with --refresh..."
    sudo dnf update --refresh -y
}

# Function to remove kernel exclusion from the updates repository
remove_exclude_from_updates_repo() {
    local repo_file="/etc/yum.repos.d/fedora-updates.repo"
    local backup_file="${repo_file}.bak"
    local exclude_line="exclude=kernel*"

    if [[ ! -f "$repo_file" ]]; then
        echo "Repository file not found: $repo_file"
        return 1
    fi

    # Create a backup of the original file
    cp "$repo_file" "$backup_file"
    echo "Backup created at: $backup_file"

    # Remove exclude=kernel* from the [updates] section
    sed -i.bak -e '/^\[updates\]/,/^\[/{ /^\[updates\]/!{/^\[/b; /'"$exclude_line"'/d;}; }' "$repo_file"

    echo "Removed $exclude_line from the [updates] section in $repo_file."
}

# Function to remove the  sentry/kernel-blu  COPR repository
remove_copr_repo() {
    local repo_name="sentry/kernel-blu"

    echo "Disabling the COPR repository: $repo_name..."
    sudo dnf copr disable "$repo_name" -y
    echo "Removed the COPR repository: $repo_name."
}

# Function to change to the sentry/kernel-blu kernel
change_kernel() {
    clear
    add_exclude_to_updates_repo
    update_kernel
}

# Function to return to the stock Fedora kernel
stock_kernel() {
    clear
    remove_exclude_from_updates_repo
    remove_copr_repo
}

# Function to display the kernel management menu
kernel_menu(){
# Show the dialog menu
while true; do
    action=$(dialog --clear --title "Kernel Management" --menu "Choose an option:" 15 50 2 \
        1 "Change to sentry - kernel-blu" \
        2 "Return to Stock Fedora Kernel" \
        3 "Back" \
        3>&1 1>&2 2>&3)

    case $action in
        1)
            change_kernel
            ;;
        2)
            stock_kernel
            ;;
        3)
            clear
            return 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done
}
