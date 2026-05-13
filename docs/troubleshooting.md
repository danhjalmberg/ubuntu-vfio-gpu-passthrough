# Troubleshooting

This document provides project-specific troubleshooting for the VFIO GPU passthrough workstation.

Focus:

- GPU passthrough binding
- Xorg/display startup
- VM initialization and passthrough devices
- USB and IOMMU-related issues

The intent is to allow fast diagnosis and recovery rather than explain VFIO theory.

---

## 1. General strategy

- Verify IOMMU activation
- Verify PCIe device isolation
- Verify VFIO binding
- Verify display server behavior
- Verify VM configuration

Debug one subsystem at a time; avoid changing kernel parameters, Xorg, VM XML, and drivers simultaneously.

---

## 2. Black screen during boot

**Symptoms:** monitor stays black, no login, SSH may still work.

**Common causes:**

| Cause                         | Explanation                             |
|-------------------------------|-----------------------------------------|
| Missing Intel Xorg config     | Host cannot initialize fallback display |
| NVIDIA GPU detached           | Host tries to use GPU now bound to VFIO |
| Monitor connected incorrectly | Display attached to passthrough GPU     |
| Broken Xorg config            | Display server fails                    |

**Resolution:**

- Ensure iGPU enabled in BIOS
- Connect monitor to motherboard output
- Verify Intel Xorg override
- Confirm NVIDIA GPU bound to VFIO

---

## 3. Blinking cursor / login loop

**Symptoms:** graphical login never appears or returns to login screen.

**Common causes:**

| Cause                   | Explanation                      |
|-------------------------|----------------------------------|
| Xorg startup failure    | Display server cannot initialize |
| Incorrect GPU ownership | Host still expects detached GPU  |
| Broken display manager  | GDM fails to start               |

**Resolution:**

- Correct Intel Xorg config
- Remove conflicting NVIDIA modules
- Ensure monitor is connected to iGPU output
- Verify VFIO binding

Switch to TTY (`Ctrl + Alt + F3`) to inspect logs:

```bash
journalctl -b -xe
journalctl -u gdm
```

---

## 4. GPU not bound to VFIO

**Symptoms:** `lspci -nnk` shows `nvidia` instead of `vfio-pci`.

**Common causes:**

| Cause                           | Explanation                    |
| ------------------------------- | ------------------------------ |
| Wrong `vfio-pci.ids`            | GPU IDs missing or incorrect   |
| Missing initramfs update        | VFIO configuration not applied |
| NVIDIA modules loaded too early | VFIO loses device ownership    |
| Incomplete blacklist            | NVIDIA claims device           |

**Resolution:**

```bash
sudo update-initramfs -u
sudo update-grub
reboot
```

Verify device binding:

```bash
lspci -nnk
```

---

## 5. VM cannot start

**Symptoms:** VM exits immediately, libvirt reports PCIe errors.

**Common causes:**

| Cause                   | Explanation                 |
| ----------------------- | --------------------------- |
| GPU owned by host       | VFIO binding failed         |
| IOMMU disabled          | PCI passthrough unavailable |
| Wrong PCIe address      | VM XML mismatch             |
| Device already assigned | Resource conflict           |

**Resolution:**

- Confirm GPU bound to VFIO
- Verify PCIe addresses in VM XML
- Confirm IOMMU enabled in BIOS
- Reboot into VFIO mode

---

## 6. No display inside VM

**Symptoms:** VM runs but no monitor output.

**Causes:** GPU not initialized, incomplete passthrough, incorrect monitor connection, OVMF mismatch.

**Resolution:**

- Pass both GPU functions (graphics + audio)
- Verify OVMF firmware
- Verify monitor connected to GPU output
- Confirm GPU bound to VFIO

---

## 7. USB devices unavailable in VM

**Symptoms:** Keyboard/mouse unavailable or unstable.

**Causes:** Wrong USB controller, shared IOMMU group, individual device passthrough, controller not bound to VFIO.

**Resolution:**

- Use dedicated PCIe USB controller
- Pass through entire controller
- Avoid onboard shared controllers
- Verify IOMMU grouping

---

## 8. Host loses display after VM startup

**Symptoms:** Ubuntu display disappears.

**Causes:** Host still expects NVIDIA GPU, Intel GPU not configured, monitor connected incorrectly.

**Resolution:**

- Ensure host uses Intel iGPU
- Connect monitor to motherboard output
- Do not rely on detached NVIDIA GPU

---

## 9. Linked clone qcow2 problems

**Symptoms:** VM fails, overlay missing backing image.

**Causes:** Base image moved/renamed, storage migration incomplete.

**Resolution:**

```bash
qemu-img info --backing-chain <image>
qemu-img rebase -u -F qcow2 -b <base-image> <overlay-image>
```

---

## 10. IOMMU group problems

**Symptoms:** Devices cannot be isolated, passthrough affects host.

**Causes:** Shared PCIe/IOMMU groups, chipset limitations, ACS restrictions.

**Resolution:**

- Use dedicated PCIe cards
- Different PCIe slots
- Avoid unsafe group separation

---

## 11. Useful verification commands

```bash
# VFIO modules
lsmod | grep vfio

# Kernel boot parameters
cat /proc/cmdline

# PCIe devices
lspci -nn

# Active VMs
virsh list --all

# GPU driver ownership
lspci -nnk
```

---

## 12. References to related documents

| Document                   | Purpose                     |
| -------------------------- | --------------------------- |
| `docs/boot-modes.md`       | VFIO boot workflow          |
| `docs/display-handling.md` | Xorg and GPU ownership      |
| `docs/input-switching.md`  | USB and KM workflows        |
| `docs/vm-configuration.md` | VM architecture and storage |
| `docs/recovery.md`         | Recovery procedures         |

---

## 13. Troubleshooting philosophy

- Prioritize explicit hardware ownership and predictable startup
- Debug one subsystem at a time: GPU -> display -> VM -> USB
- Most issues stem from:

  - incorrect GPU ownership
  - Xorg misconfiguration
  - VFIO binding errors
  - IOMMU/PCIe group constraints
  - incorrect monitor input connection
