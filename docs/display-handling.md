# Display handling

This document summarizes display handling for the VFIO workstation setup, focusing on project-specific configuration and practical verification steps.

It explains how Ubuntu uses the Intel iGPU as a host fallback when the NVIDIA GPU is passed through to the VM.

---

## 1. Display devices

| Device                      | Role                                      |
| --------------------------- | ----------------------------------------- |
| NVIDIA Quadro P4000         | Passed to Windows VM via VFIO             |
| Intel integrated GPU (iGPU) | Host display in VFIO mode                 |

- Normal Ubuntu mode: host uses NVIDIA GPU directly  
- VFIO mode: NVIDIA GPU detached, host uses Intel iGPU

---

## 2. Intel iGPU configuration

- Dedicated Xorg override:

```text
/etc/X11/xorg.conf.d/10-intel-vfio.conf
```

Purpose:

- force host to use Intel GPU in VFIO mode
- prevent Xorg from attempting to use detached NVIDIA GPU
- stabilize graphical startup

- Installed dynamically via systemd service:

```text
configs/vfio-intel-xorg.service
```

---

## 3. VFIO display startup workflow

1. Select VFIO GRUB entry at boot
2. NVIDIA GPU binds to VFIO
3. Intel Xorg override installed via systemd
4. Xorg starts with Intel GPU
5. Windows VM starts using NVIDIA GPU passthrough

---

## 4. Monitor and input workflow

Current setup:

- Single monitor with multiple inputs
  - Motherboard output -> host display (Intel iGPU)
  - NVIDIA output -> Windows VM
  - Keyboard/mouse switched using KM switch

Alternative:

- Dual-monitor setup for host and VM
- Advantages: simultaneous visibility
- Disadvantages: additional hardware and desk space

---

## 5. Software alternatives considered

- Looking Glass
- Software display sharing
- Remote desktop workflows

Rejected due to:

- latency
- added complexity
- reduced stability

Current setup prioritizes:

- native GPU output
- minimal latency
- predictable hardware behavior

---

## 6. Wayland

- Xorg is used instead of Wayland for stability and predictability
- Wayland support may be explored in future, but is not part of this setup

---

## 7. Common display problems

| Problem                 | Typical cause                                                   |
| ----------------------- | --------------------------------------------------------------- |
| Black screen            | Missing Intel Xorg configuration, monitor connected incorrectly |
| Login loop              | Host attempting to use detached NVIDIA GPU                      |
| Blinking cursor         | Xorg initialization failure or Intel config missing             |
| Host display disappears | Monitor connected only to VM GPU, Intel GPU not configured      |

---

## 8. Verification commands

```bash
# Active GPU devices
lspci | grep -i vga

# GPU driver binding
lspci -nnk

# Loaded modules
lsmod | grep -E 'vfio|nvidia|i915'

# Display-related logs
journalctl -b | grep -iE 'xorg|gdm|gpu|nvidia|i915'
```

---

## 9. Related configuration files

| File                              | Purpose                             |
| --------------------------------- | ----------------------------------- |
| `configs/10-intel-vfio.conf`      | Intel Xorg override                 |
| `configs/vfio-intel-xorg.service` | Dynamic Xorg configuration handling |
| `configs/grub`                    | Main GRUB configuration             |
| `configs/40_custom`               | VFIO boot entry                     |

---

## 10. Summary

Display handling in VFIO mode prioritizes:

- explicit GPU ownership
- stable host graphical environment
- predictable recovery
- reliable host usability

over dynamic GPU switching or automatic display reassignment.

This ensures the Linux host and Windows VM coexist with clearly separated display responsibilities.
