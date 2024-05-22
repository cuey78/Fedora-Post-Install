#!/bin/bash

# DNF setting
echo "fastestmirror=true" >> /etc/dnf/dnf.conf
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
echo "countme=false" >> /etc/dnf/dnf.conf

# Clean Cache DNF
dnf clean all
dnf upgrade -y

# Firmware update if supported
if command -v fwupdmgr >/dev/null 2>&1; then
    fwupdmgr refresh
    fwupdmgr get-updates && fwupdmgr update
fi

# Install RPM Fusion
fedora_version=$(rpm -E %fedora)
rpmfusion_free_url=https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm
rpmfusion_nonfree_url=https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm

dnf install -y --nogpgcheck "$rpmfusion_free_url" "$rpmfusion_nonfree_url"
dnf install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data 
dnf install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted

# Install Codecs
dnf install -y gstreamer1-plugin-libav-1.22.12-1.fc40.x86_64 gstreamer1-libav libdvdcss


echo "intell media driver"    
dnf install -y intel-media-driver


# Install Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Virtualization
dnf -y group install virtualization
#virtman as normal user
usermod -a -G libvirt $(whoami)
newgrp libvirt

echo "uncomment lines 85 & 102"
sleep  5
nano /etc/libvirt/libvirtd.conf
systemctl restart libvirtd.service
#install chrome
wget https://www.google.com/chrome/next-steps.html?statcb=0&installdataindex=empty&defaultbrowser=0#
dnf -y install google-chrome-stable_current_x86_64.rpm

