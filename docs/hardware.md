# Hardware considerations

This document summarizes the hardware used in this dual-mode Ubuntu GPU passthrough workstation and highlights requirements for reproducible VFIO operation.

The focus is on components necessary for GPU passthrough, stable host operation, and low-latency VM interaction.

---

## 1. Core hardware requirements

### CPU with IOMMU support

- Required for PCIe passthrough
- Intel: VT-d, AMD: AMD-Vi / IOMMU
- Verify with:

```bash
dmesg | grep -i iommu
```

---

### Dedicated GPU for VM passthrough

- In this setup: NVIDIA Quadro P4000
- Both GPU and GPU audio must be passed together
- Verify PCI device IDs:

```bash
lspci -nn
```

---

### Secondary GPU for host display

- Recommended: Integrated GPU (iGPU) or second dedicated GPU
- Needed so host retains display in VFIO mode
- Verify iGPU:

```bash
lspci | grep -i vga
```

Typical example:

```
Intel Corporation UHD Graphics 630
NVIDIA Corporation GP104GL [Quadro P4000]
```

---

## 2. USB controller passthrough

### Dedicated PCIe USB controller

- Current setup: Renesas uPD720202
- Provides:

  - Native keyboard/mouse input
  - Reduced latency
  - Host/VM isolation

- Entire controller passed through to VM

### Onboard USB limitations

- Motherboard controllers often share IOMMU groups
- Cannot safely isolate individual ports
- Passing through onboard USB can break host functionality
- Dedicated PCIe controller avoids this

### Inspect IOMMU groups

```bash
for g in /sys/kernel/iommu_groups/*; do
  echo "IOMMU Group ${g##*/}:"
  lspci -nns $(basename -a $g/devices/*)
done
```

Check USB, PCI bridges, GPU devices.

---

## 3. Monitor setup

### Single-monitor workflow (current setup)

- One monitor with multiple inputs
- Connections:
  - iGPU -> Ubuntu host
  - NVIDIA GPU -> Windows VM
- Manual monitor input switching
- KM switch for keyboard/mouse
- Advantages: minimal hardware
- Disadvantages: cannot view host and VM simultaneously

### Dual-monitor alternative

- Separate monitors for host and VM
- Advantages: simultaneous visibility, no input switching
- Disadvantages: more hardware and desk space

---

## 4. KM / KVM switching

### Current setup

- KM switch used for USB switching
- Monitor input switched manually
- Full KVM switch could combine video + USB but was not used

---

## 5. Current hardware snapshot

| Component           | Hardware               |
| ------------------- | ---------------------- |
| CPU                 | Intel Xeon E-2174G     |
| Host GPU            | Intel UHD Graphics 630 |
| Passthrough GPU     | NVIDIA Quadro P4000    |
| PCIe USB controller | Renesas uPD720202      |
| Host OS             | Ubuntu 24.04           |
| Guest OS            | Windows 11             |
| Virtualization      | QEMU/KVM + libvirt     |

---

## 6. Design priorities

Hardware configuration emphasizes:

- Stability and predictability
- Explicit device ownership
- Native input handling
- Workstation usability

Optional components (enhancements, not required):

- Additional monitors
- Full KVM switch for input + video
- Extra PCIe USB devices
