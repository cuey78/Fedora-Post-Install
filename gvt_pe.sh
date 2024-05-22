#!/bin/bash
modprobe kvmgt mdev vfio-iommu-type1
echo "37d7d57d-de7b-47e0-ae05-d6e69b98d629" > "/sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_2/create"

