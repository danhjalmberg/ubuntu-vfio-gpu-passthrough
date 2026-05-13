# Boot modes

This document summarizes the two boot modes in the dual-GPU VFIO workstation and their key configuration requirements.

The focus is on practical setup details for hardware ownership and GPU passthrough.

---

## 1. Modes overview

| Mode               | NVIDIA GPU owner | Host display |
|--------------------|------------------|--------------|
| Normal Ubuntu mode | Ubuntu host      | NVIDIA GPU   |
| VFIO mode          | Windows VM       | Intel iGPU   |

Mode selection occurs at boot via GRUB.

---

## 2. Normal Ubuntu mode

- NVIDIA GPU is claimed by the host
- Standard desktop, CAD, and compute workloads run directly
- No VFIO binding or Xorg override is needed

---

## 3. VFIO mode

- NVIDIA GPU is detached from host and bound to `vfio-pci`
- Passed to Windows VM via QEMU/KVM
- Intel iGPU serves as host display
- Additional passthrough devices:
  - GPU audio
  - PCIe USB controller

---

## 4. Boot-time switching rationale

- Hardware ownership is fixed at boot
- Avoids runtime GPU detachment/rebinding
- Improves stability, predictability, and recoverability
- Reduces driver and display server conflicts

---

## 5. GRUB configuration

- Separate entries for normal and VFIO modes
- Custom VFIO entry defined in `/etc/grub.d/40_custom`
- Update GRUB after edits:

```bash
sudo update-grub
```

---

## 6. VFIO kernel parameters

Typical VFIO boot parameters:

```text
intel_iommu=on
iommu=pt
vfio-pci.ids=<GPU IDs>
```

Purpose:

| Parameter        | Function                           |
| ---------------- | ---------------------------------- |
| `intel_iommu=on` | Enable IOMMU support               |
| `iommu=pt`       | Passthrough mode optimization      |
| `vfio-pci.ids=`  | Bind GPU and other devices to VFIO |

Additional options may:

- blacklist NVIDIA drivers
- disable framebuffer drivers
- modify systemd behavior

---

## 7. Device binding

- Verify GPU is bound to `vfio-pci`:

```bash
lspci -nnk
```

Expected: `Kernel driver in use: vfio-pci` for GPU and audio

---

## 8. Driver blacklisting

- NVIDIA modules must be prevented from claiming the GPU
- Handled via the VFIO GRUB entry:
  - `vfio-pci.ids=`
  - NVIDIA driver blacklisting
  - masked NVIDIA-related services

---

## 9. Intel iGPU for host display

- Required for VFIO mode
- Xorg must be configured to use Intel GPU
- Systemd service installs override automatically
- Prevents black screens and login loops

---

## 10. Typical VFIO boot workflow

1. Select VFIO GRUB entry
2. Host boots using Intel iGPU
3. NVIDIA GPU binds to VFIO
4. Start Windows VM with passthrough GPU, audio, and USB
5. Switch monitor input and keyboard/mouse as needed

---

## 11. Verification

- GPU driver binding: `lspci -nnk`
- IOMMU activation: `dmesg | grep -i iommu`
- Loaded VFIO modules: `lsmod | grep vfio`
- Active GPU devices: `lspci | grep -i vga`

---

## 12. Common problems

| Problem                           | Cause                                      |
| --------------------------------- | ------------------------------------------ |
| Black screen during boot          | Missing Intel Xorg configuration           |
| Login loop                        | Host attempting to use detached GPU        |
| VM cannot start                   | GPU not bound to VFIO                      |
| NVIDIA driver loaded in VFIO mode | Missing blacklist or incorrect IDs         |
| No display output in VFIO mode    | Incorrect monitor connection or iGPU setup |

Detailed troubleshooting: `docs/troubleshooting.md`

---

## 13. Related configuration files

| File                              | Purpose                   |
| --------------------------------- | ------------------------- |
| `configs/grub`                    | Main GRUB configuration   |
| `configs/40_custom`               | VFIO boot entry           |
| `configs/10-intel-vfio.conf`      | Xorg Intel override       |
| `configs/vfio-intel-xorg.service` | Dynamic Xorg handling     |

---

## 14. Design summary

- Boot-time hardware ownership improves stability
- VFIO mode isolates the NVIDIA GPU for VM use
- Intel iGPU provides reliable host display
- Workflow favors predictable, reproducible workstation operation over dynamic switching
