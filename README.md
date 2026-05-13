# Ubuntu VFIO GPU Passthrough Workstation

## Short overview

This project documents a dual-mode Ubuntu workstation built using QEMU/KVM, libvirt, and VFIO GPU passthrough.

The system is designed to operate in two distinct boot modes:

- **Normal mode**
  - Ubuntu uses the NVIDIA GPU directly for standard desktop and compute workloads

- **VFIO mode**
  - The NVIDIA GPU is detached from the host and passed through to a Windows VM
  - The Ubuntu host instead uses the Intel integrated GPU for display output

The setup was created primarily for GPU-accelerated CAD and workstation software testing inside virtual machines, where traditional hosted hypervisors such as Oracle VirtualBox and VMware Workstation are limited by virtualized graphics performance.

The repository contains:
- configuration files
- VM definitions
- helper scripts
- troubleshooting notes
- architectural documentation

The focus is on documenting a reproducible workstation-oriented GPU passthrough environment rather than providing a minimal quick-start guide.

---

## Motivation

This project started from an interest in virtualization and hardware isolation workflows.

Traditional hosted hypervisors such as Oracle VirtualBox and VMware Workstation are convenient for software experiments and isolated development environments. However, they become limiting when working with GPU-accelerated applications such as CAD and 3D visualization software, where access to dedicated graphics hardware is important for both performance and compatibility.

The primary motivation for this setup was therefore to create a virtualization environment capable of:

- Running GPU-accelerated applications inside a virtual machine
- Achieving near-native graphics performance
- Maintaining a usable Linux host environment at the same time
- Separating experimental or specialized software workflows from the main host system

A second motivation was long-term reproducibility.

GPU passthrough setups often depend on hardware-specific behavior, bootloader configuration, driver interactions, and PCIe/IOMMU topology. Many of these details are difficult to reconstruct after operating system reinstalls, hardware changes, or configuration experiments.

The repository therefore also serves as a technical reference documenting the system configuration, design decisions, and troubleshooting experience behind the setup.

---

## Key features

- Dual-mode Ubuntu boot configuration:
  - Normal desktop mode
  - VFIO passthrough mode

- Full GPU passthrough using:
  - QEMU/KVM
  - libvirt
  - VFIO

- NVIDIA GPU assignment directly to Windows VM

- Intel integrated GPU used as host display device in VFIO mode

- Separate GRUB boot entries controlling GPU ownership at boot time

- UEFI-based virtual machine configuration using OVMF

- Dedicated PCIe USB controller passthrough for:
  - keyboard
  - mouse
  - low-latency input handling

- CPU pinning and host-passthrough CPU configuration

- Virtio-based virtualized devices for improved VM performance

- Isolated host <-> VM network interface for:
  - Samba file sharing
  - independent VM communication

- Dynamic Xorg configuration in VFIO mode using systemd

---

## Architecture summary

The system is built around a dual-GPU architecture where hardware ownership changes depending on the selected boot mode.

The hardware configuration includes:

- An NVIDIA dedicated GPU
  - Used either by the Ubuntu host or by the Windows VM

- An Intel integrated GPU (iGPU)
  - Used as fallback display device for the Ubuntu host in VFIO mode

The setup relies on boot-time hardware ownership rather than dynamic runtime switching.

### Normal mode

In normal Ubuntu mode, the NVIDIA GPU is used directly by the Ubuntu host for desktop rendering and GPU-accelerated workloads. No GPU passthrough is active in this mode.

---

### VFIO mode

In VFIO mode, the NVIDIA GPU is detached from the host during boot, bound to `vfio-pci`, and passed directly to the Windows VM. The Ubuntu host instead uses the Intel iGPU for display output.

---

### Display architecture

In VFIO mode, the host display server is configured to use the Intel iGPU instead of the detached NVIDIA GPU. A dedicated systemd service installs the required Xorg override dynamically during boot.

---

### Virtual machine architecture

The Windows VM uses QEMU/KVM, libvirt, OVMF (UEFI firmware), Virtio devices, and PCIe passthrough. The VM receives direct access to the NVIDIA GPU, GPU audio device, and dedicated PCIe USB controller, allowing near-native graphics and input performance.

---

### Input and display workflow

The setup uses manual monitor input switching together with a KM switch for keyboard and mouse control. The workflow prioritizes explicit hardware ownership, stability, and low-latency input handling over seamless runtime integration.

---

## Repository structure

### `README.md`

Main repository overview and architectural summary.

---

### `configs/`

Configuration files extracted from the working host system.

Examples include:
- GRUB configuration
- VFIO kernel module configuration
- systemd service definitions
- Xorg display configuration

---

### `configs/vm/`

Libvirt XML definitions for virtual machines.

Examples include:
- Base Windows VM
- Linked clone VMs

---

### `scripts/`

Helper scripts related to virtualization and hardware diagnostics.

Current examples include:
- IOMMU group inspection scripts

---

### `docs/`

Additional technical documentation:
- hardware considerations
- troubleshooting
- recovery procedures
- VM and display handling

---

## Design philosophy

### Boot-time hardware ownership

The setup relies on boot-time hardware ownership rather than dynamic runtime switching.

Instead of detaching and reattaching devices while the system is running, the workstation operates in two explicitly separated boot modes:

- Normal Ubuntu mode
- VFIO passthrough mode

This approach prioritizes stability, predictable system state, and reduced driver complexity over seamless runtime switching.

---

### Clear host / guest separation

The setup prioritizes explicit hardware separation between the host and guest systems.

Examples include:
- dedicated GPU ownership
- dedicated USB controller ownership
- separate display handling
- separate input handling

This reduces driver conflicts and improves system stability and recoverability.

---

### Workstation-oriented virtualization

Many GPU passthrough setups are optimized primarily for gaming workloads.

This setup was instead designed mainly around:
- CAD software
- GPU-accelerated workstation software
- isolated experimental environments

As a result, the setup prioritizes stability, reproducibility, native input handling, and long-running usability over performance tuning or seamless runtime integration.

---

## Disclaimer

This repository documents a specific personal hardware and software configuration.

GPU passthrough setups are highly dependent on factors such as:
- hardware topology
- IOMMU grouping
- firmware behavior
- Linux kernel versions
- GPU driver compatibility

As a result, the exact configuration and procedures described here may not work identically on other systems.

---

### Advanced system configuration

The setup involves low-level system configuration including:
- GRUB boot parameters
- GPU driver management
- PCI device ownership
- Xorg display configuration

Incorrect changes may result in:
- boot failures
- black screens
- unavailable input devices
- inaccessible virtual machines

Basic familiarity with Linux system administration and virtualization concepts is assumed.

---

## Status / Future work

The current setup is operational and supports:

- Dual-mode Ubuntu boot workflow
- Stable GPU passthrough to Windows VM
- Intel iGPU fallback for host display in VFIO mode
- Dedicated USB controller passthrough
- VM networking and Samba file sharing
- CPU pinning and performance-oriented VM configuration
- Linked clone virtual machines based on qcow2 backing images

The setup is currently used for:
- virtualization experiments
- GPU-accelerated workstation software
- isolated Windows environments
- infrastructure testing

---

Possible future experiments include:

- Virtio disk migration from SATA emulation
- Additional CPU isolation tuning
- Hugepages memory configuration
- Looking Glass evaluation
- Alternative display server workflows (Wayland)
- Additional VM templates and linked clone workflows
