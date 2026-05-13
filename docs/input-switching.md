# Input switching

This document summarizes input device handling for the VFIO workstation setup.  
It focuses on hardware-based control of keyboard, mouse, and monitor input between the Ubuntu host and Windows VM.

---

## 1. Overview

In VFIO mode:

- NVIDIA GPU is passed directly to the Windows VM
- VM behaves as a physical workstation
- Host input devices and VM input devices are separated via dedicated hardware

Purpose:

- Low-latency native input
- Predictable hardware ownership
- Stable host and VM operation

---

## 2. USB controller passthrough

- Dedicated PCIe USB controller (Renesas uPD720202) assigned fully to the VM
- Provides native keyboard/mouse interaction
- Avoids software-based sharing latency and instability
- Entire controller is unavailable to host while assigned

---

### Why entire controllers are passed through

- VFIO operates at PCIe device level
- Individual USB ports cannot be reliably isolated
- Passing a full controller is more stable than individual device passthrough

---

### Onboard USB limitations

- Often grouped with chipset devices in same IOMMU group
- Cannot be safely isolated without impacting host
- Dedicated PCIe USB controller avoids this limitation

---

### Inspecting IOMMU groups

```bash
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    lspci -nns $(basename -a $g/devices/*)
done
```

Verify USB controllers, PCI bridges, GPU devices, and chipset components.

---

## 3. Alternative input approaches

### Individual USB device passthrough

- Advantage: no extra PCIe card required

- Disadvantages:

  - reconnect issues
  - higher latency
  - less stable long-term behavior

### Software solutions (e.g., Looking Glass)

- Allows host-hosted VM display with shared input

- Advantages:
  - seamless desktop integration
  - no manual switching

- Disadvantages:
  - higher latency
  - additional software complexity
  - reduced predictability

- Not used in this setup

---

## 4. Monitor and KM switch workflow

Current setup:

- Single monitor with multiple inputs
- Host display output -> Ubuntu host
- Passthrough GPU output -> Windows VM
- KM switch used for keyboard/mouse switching

Alternative workflows:

- Dual monitors: one for host, one for VM

  - Advantages: simultaneous visibility
  - Disadvantages: more hardware and desk space

- Full KVM switch for video + USB

  - Advantages: single-button switching
  - Disadvantages: higher cost, compatibility considerations

---

## 5. Design rationale

- Native GPU output and direct USB passthrough prioritized
- Avoid software-based input sharing
- Emphasis on stability, low latency, and predictable device ownership
- Supports CAD and workstation workflows

---

## 6. Common problems

| Problem                             | Typical cause                          |
| ----------------------------------- | -------------------------------------- |
| Keyboard/mouse unavailable in VM    | USB controller not passed through      |
| Host loses USB devices unexpectedly | Wrong controller assignment            |
| Input lag                           | Software-based sharing or indirect USB |
| USB reconnect instability           | Individual device passthrough          |
| VM starts but no usable input       | Devices still owned by host            |

---

## 7. Verification commands

```bash
# List USB controllers
lspci | grep -i usb

# Check VFIO binding
lspci -nnk

# Inspect IOMMU groups
find /sys/kernel/iommu_groups/ -type l
```

---

## 8. Related configuration files

| File                           | Purpose                             |
| ------------------------------ | ----------------------------------- |
| `configs/40_custom`            | VFIO device binding at boot         |
| `configs/vm/*.xml`             | VM passthrough device configuration |
| `scripts/list-iommu-groups.sh` | Helper for IOMMU inspection         |

---

## 9. Summary

The input workflow prioritizes:

- native hardware behavior
- explicit device ownership
- low-latency interaction
- host/VM stability

over:

- software-based input sharing
- dynamic runtime switching

Result: VM behaves like a physical workstation with dedicated input and GPU hardware.
