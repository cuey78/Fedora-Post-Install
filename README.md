# Fedora Post Install Script

## Overview
This script is designed to automate the configuration and installation of various system components and software on Fedora systems. It has been tested on Fedora 41 with KDE but should work seamlessly on Fedora 40 as well.

## Features
The Fedora Post Install Script offers a wide range of functionalities to enhance the Fedora system setup:

- **Virtualization Support:**
  - Installs VirtManager and QEMU for managing virtual machines.
  - Configures PCI passthrough for AMD / NVIDIA or Intel hardware.
  - Sets up Intel GVT-G support for shared virtual GPU.
  - Build in support for evdev passthrough
  
- **Repository and Software Management:**
  - Enables Flathub for Flatpak support.
  - Enables RPM Fusion for additional packages.
  - Adds and installs the Google Chrome repository.

- **Driver Management:**
  - Switches to Mesa Freeworld Drivers for AMD graphics cards.
  - Switches to Intel Media Drivers for Intel Integrated Graphics (e.g., Skylake).

- **System Updates and Firmware:**
  - Checks for and updates system firmware.

- **Networking and File Sharing:**
  - Sets up WiFi NFS Shares Service.
  - Configures NFS via fstab for wired connections.

- **UI Enhancements:**
  - Fixes the Fedora GRUB screen to improve aesthetics.
  - Adjusts the KDE splash screen to match the Fedora logo.

- **Multimedia:**
  - Installs multimedia codecs essential for media playback.

- **System Optimization:**
  - Cleans and adds tweaks to DNF (e.g., `max_downloads=10`) to optimize package handling.

- **Additional Utilities:**
  - Downloads, builds, and installs the Looking Glass Client for desktop streaming in virtualized environments.
  - Download and install msfonts , Jetbrains mono font 
## Compatibility
This script is compatible with:
- Fedora 40 KDE
- Fedora 39 and possibly earlier versions

## Usage

To use this script, ensure you are running it with root privileges to allow for system-level modifications. This can typically be achieved by prefixing the command with `sudo`.

Example 1: ```sudo bash -c "$(curl -sSL https://raw.githubusercontent.com/cuey78/Fedora-Post-Install/main/runme.sh)" ```

Example 2: `chmod +x main.sh then sudo ./main.sh`

### One-line Installation

To install and execute the script in one line:

```bash
curl -sSL https://tinyurl.com/fedorapostinstall | sudo bash -
