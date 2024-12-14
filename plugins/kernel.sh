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

#!/bin/bash

# Function to add kernel exclusion to the updates repository
add_exclude_to_updates_repo() {
    local repo_file="/etc/yum.repos.d/fedora-updates.repo"
    local exclude_line="exclude=kernel*"

    if [[ ! -f "$repo_file" ]]; then
        echo "Repository file not found: $repo_file"
        return 1
    fi

    # Create a backup of the repository file
    cp "$repo_file" "${repo_file}.bak"
    echo "Backup created at: ${repo_file}.bak"

    # Add exclusion line in the [updates] section
    sed -i -e '/^\[updates\]/,/^\[/{/skip_if_unavailable=False/a\
'"$exclude_line"'
    }' "$repo_file"

    echo "Updated $repo_file to exclude kernel updates in the [updates] section."
}

# Function to update the kernel using the sentry/kernel-blu COPR repository
kernel_sentry() {
    echo "Enabling the sentry/kernel-blu COPR repository..."
    dnf copr enable sentry/kernel-blu -y || { echo "Failed to enable sentry/kernel-blu COPR."; return 1; }

    echo "Updating the system with --refresh..."
    dnf update --refresh -y || { echo "Failed to update the system."; return 1; }
}

# Function to install the CachyOS kernel
kernel_cachyos() {
    echo "Enabling CachyOS repositories and installing kernel..."
    dnf copr enable bieszczaders/kernel-cachyos -y || { echo "Failed to enable CachyOS COPR."; return 1; }
    dnf install kernel-cachyos kernel-cachyos-devel-matched -y || { echo "Failed to install CachyOS kernel."; return 1; }

    dnf copr enable bieszczaders/kernel-cachyos-addons -y || { echo "Failed to enable CachyOS addons COPR."; return 1; }
    dnf install cachyos-settings -y || { echo "Failed to install CachyOS settings."; return 1; }

    dracut -f --regenerate-all || { echo "Failed to regenerate initramfs."; return 1; }
    grub2-mkconfig -o /boot/grub2/grub.cfg || { echo "Failed to update GRUB configuration."; return 1; }

    echo "CachyOS kernel installed successfully."
}

# Function to remove kernel exclusion from the updates repository
remove_exclude_from_updates_repo() {
    local repo_file="/etc/yum.repos.d/fedora-updates.repo"
    local exclude_line="exclude=kernel*"

    if [[ ! -f "$repo_file" ]]; then
        echo "Repository file not found: $repo_file"
        return 1
    fi

    # Remove exclusion line from the [updates] section
    sed -i -e "/^\[updates\]/,/^\[/{/$exclude_line/d}" "$repo_file"
    echo "Removed $exclude_line from the [updates] section in $repo_file."
}

# Function to remove a specified COPR repository
remove_copr_repo() {
    local repo_name="$1"

    if [[ -z "$repo_name" ]]; then
        echo "Error: No repository name provided."
        return 1
    fi

    echo "Disabling the COPR repository: $repo_name..."
    dnf copr disable "$repo_name" -y || { echo "Failed to disable COPR: $repo_name."; return 1; }
    echo "Removed the COPR repository: $repo_name."
}

# Function to switch to the sentry/kernel-blu kernel
change_kernel() {
    clear
    add_exclude_to_updates_repo
    kernel_sentry
}

# Function to return to the stock Fedora kernel
stock_kernel() {
    clear
    remove_exclude_from_updates_repo

    # Remove sentry/kernel-blu COPR repository
    remove_copr_repo "sentry/kernel-blu"

    # Remove CachyOS kernel COPR repository
    remove_copr_repo "bieszczaders/kernel-cachyos"
    remove_copr_repo "bieszczaders/kernel-cachyos-addons"
}

# Function to display the kernel management menu
kernel_menu() {
    while true; do
        action=$(dialog --clear --title "Kernel Management" --menu "Choose an action:" 15 50 4 \
            1 "Switch to Sentry - Kernel (kernel-blu)" \
            2 "Restore Stock Fedora Kernel" \
            3 "Install and Switch to CachyOS Kernel" \
            4 "Back to Previous Menu" \
            3>&1 1>&2 2>&3)

        case $action in
            1)
                change_kernel
                ;;
            2)
                stock_kernel
                ;;
            3)
                kernel_cachyos
                ;;
            4)
                clear
                return 0
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    done
}

