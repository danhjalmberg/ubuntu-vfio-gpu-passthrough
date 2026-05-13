# Virtual machine configuration

This document describes the VM setup used in the dual-GPU VFIO workstation.

Focus:
- stable GPU passthrough
- workstation-oriented performance
- reproducible VM definitions
- hardware-specific virtualization

---

## 1. Virtualization stack

| Component    | Purpose                               |
|--------------|---------------------------------------|
| QEMU         | Hardware emulation and virtualization |
| KVM          | Hardware-assisted virtualization      |
| libvirt      | VM management layer                   |
| virt-manager | Graphical VM management               |
| VFIO         | PCIe device passthrough               |
| OVMF         | UEFI firmware for VMs                 |

---

## 2. VM management

- GUI: `virt-manager` for creation, storage management, device inspection  
- CLI: `virsh` for advanced configuration  
- XML editing used for device passthrough and CPU topology tuning

---

## 3. Firmware and machine type

- **UEFI firmware (OVMF)** for Windows 11 compatibility, Secure Boot, GPT, and PCIe passthrough reliability  
- Machine type: **Q35** for modern PCIe topology and GPU passthrough support  

---

## 4. CPU configuration

- Host-passthrough CPU mode: exposes physical CPU features to VM  
- CPU pinning to reduce host/guest contention and improve responsiveness  

---

## 5. Memory configuration

- Fixed memory allocation for predictable VM performance  
- Optional future tuning: hugepages, NUMA awareness  

---

## 6. GPU passthrough

- Devices assigned:
  - NVIDIA GPU
  - GPU audio device  
- Both functions passed through together for compatibility  
- Verified via `lspci -nnk` and `vfio-pci` binding  

---

## 7. USB controller passthrough

- Dedicated PCIe USB controller passed entirely to VM  
- Provides low-latency, stable keyboard/mouse interaction  
- Full details: `docs/input-switching.md`  

---

## 8. Storage configuration

- Disk format: `qcow2`  
- Base VM images + linked clones for experimental/testing VMs  
- Snapshots used selectively to reduce duplication and simplify rollback  
- Verify backing chain:

```bash
qemu-img info --backing-chain <image>
```

---

## 9. Networking

- Two virtual networks:

  - Default: internet access
  - Isolated: host <-> VM communication (Samba file sharing)

- Some interfaces may start down to control connectivity

---

## 10. Samba file sharing

- Ubuntu host exports shared directory
- Windows VM accesses via isolated network:

```text
\\192.168.100.x\vmshare
```

---

## 11. VM XML files

- Located in `configs/vm/`
- Define:

  - CPU topology
  - memory
  - PCIe passthrough devices
  - storage
  - networks
  - firmware

Editing: `virsh edit <vm-name>` or virt-manager XML editor

---

## 12. Common VM issues

| Problem                 | Cause                         |
| ----------------------- | ----------------------------- |
| VM cannot start         | GPU already owned by host     |
| Black screen in guest   | GPU initialization failure    |
| Code 43 in Windows      | NVIDIA driver detection issue |
| No keyboard/mouse in VM | USB controller not passed     |
| Performance instability | CPU or memory contention      |
| Linked clone broken     | Missing backing image         |

---

## 13. Verification commands

```bash
# List VMs
virsh list --all

# Inspect VM XML
virsh dumpxml <vm-name>

# Disk devices
virsh domblklist <vm-name>

# Check qcow2 backing chain
qemu-img info --backing-chain <image>

# Verify PCIe/VFIO devices
lspci -nnk
```

---

## 14. Related configuration files

| File                | Purpose                         |
| ------------------- | ------------------------------- |
| `configs/vm/*.xml`  | VM definitions                  |
| `configs/40_custom` | VFIO GRUB entry and binding     |
| `configs/grub`      | Main GRUB configuration         |

---

## 15. Summary

The VM configuration prioritizes:

- reproducible setups
- predictable hardware ownership
- native GPU and input performance
- workstation stability

over:

- dynamic runtime switching
- minimal reboot frequency
- gaming-oriented optimization

The result is a virtualization environment where the guest VM behaves similarly to a physical workstation with direct hardware access.
