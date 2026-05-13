#!/bin/bash

# List PCIe devices grouped by IOMMU isolation group.
# Useful when evaluating whether GPUs, USB controllers, or other
# PCIe devices can be safely passed through via VFIO.

for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    lspci -nns $(basename -a $g/devices/*)
    echo
done
