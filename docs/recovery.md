# Recovery procedures

This document summarizes actionable steps to recover the VFIO workstation setup in case of:

- graphical login failure
- host display issues
- VFIO boot problems
- broken driver binding
- invalid display configuration
- VM passthrough failures

---

## 1. General recovery strategy

- Recover basic terminal access first
- Restore host display functionality
- Disable VFIO temporarily if needed
- Verify GPU ownership
- Restore VM passthrough after host stability is confirmed

Incremental recovery is more reliable than changing multiple subsystems at once.

---

## 2. Accessing a TTY

If graphical login fails:

```text
Ctrl + Alt + F3
# or Ctrl + Alt + F2-F6
```

Log in via console to perform recovery commands.

---

## 3. Boot into recovery mode

- At GRUB, select "Advanced options for Ubuntu"
- Choose "Recovery mode" for root shell access
- Allows:

  - filesystem repair
  - configuration rollback
  - driver removal

---

## 4. Temporarily disabling VFIO mode

### Option 1 - Use normal Ubuntu GRUB entry

Boot normally to restore host functionality.

---

### Option 2 - Edit VFIO GRUB entry

1. Press `e` at GRUB
2. Remove VFIO-specific parameters:

```text
vfio-pci.ids=
intel_iommu=on
iommu=pt
module_blacklist=
modprobe.blacklist=
```

3. Boot with `Ctrl + X` or `F10`

This allows boot without modifying disk configurations.

---

## 5. Recovering broken Xorg

- Symptoms: black screen, blinking cursor, login loop
- Remove or rename Intel Xorg override:

```bash
sudo mv /etc/X11/xorg.conf.d/10-intel-vfio.conf \
/etc/X11/xorg.conf.d/10-intel-vfio.conf.disabled
sudo reboot
```

- Optional: disable dynamic Xorg service:

```bash
sudo systemctl disable vfio-intel-xorg.service
sudo systemctl stop vfio-intel-xorg.service
sudo reboot
```

---

## 6. Rebuilding initramfs

After changes to VFIO configuration or driver blacklists:

```bash
sudo update-initramfs -u
```

- Prevents stale VFIO binding and driver conflicts

---

## 7. Updating GRUB

After modifying `/etc/default/grub` or `/etc/grub.d/40_custom`:

```bash
sudo update-grub
sudo reboot
```

---

## 8. Recovering incorrect VFIO binding

- Verify current driver ownership:

```bash
lspci -nnk
```

Expected: `nvidia` in normal mode, `vfio-pci` in VFIO mode

- Restore NVIDIA ownership temporarily by removing VFIO parameters in GRUB
- Verify:

```bash
lsmod | grep nvidia
```

---

## 9. Recovering VM XML

- Inspect VM definition:

```bash
virsh dumpxml <vm-name>
```

- Backup Libvirt XML files before major edits:

```bash
virsh dumpxml <vm-name> > backup.xml
```

- Restore from backup if needed:

```bash
virsh define backup.xml
```

---

## 10. Recovering broken qcow2 chains

- Inspect backing chain:

```bash
qemu-img info --backing-chain <image>
```

- Rebase overlay if needed:

```bash
qemu-img rebase -u -F qcow2 -b <base-image> <overlay-image>
```

---

## 11. Restoring monitor output

- Ensure motherboard output -> host
- NVIDIA output -> VM
- Verify active GPU:

```bash
lspci | grep -i vga
```

- Verify loaded drivers:

```bash
lsmod | grep -E 'i915|nvidia|vfio'
```

---

## 12. Recovering USB functionality

- Inspect USB controller ownership:

```bash
lspci -nnk | grep -A 3 USB
```

- Boot into normal Ubuntu if necessary
- Avoid passing through shared onboard controllers

---

## 13. Safe rollback strategy

Recommended order:

1. Disable VFIO temporarily
2. Restore host graphics
3. Restore NVIDIA drivers
4. Restore Xorg functionality
5. Reintroduce VFIO incrementally

Do not change multiple subsystems at once:

- GPU binding
- Xorg
- VM XML
- USB passthrough

---

## 14. Useful commands

```bash
# Kernel logs
journalctl -b

# Boot errors only
journalctl -p err -b

# GPU-related logs
journalctl -b | grep -iE 'gpu|nvidia|vfio|i915'

# Verify VFIO modules
lsmod | grep vfio

# Verify PCIe devices
lspci -nn

# Verify VMs
virsh list --all
```

---

## 15. Key recovery principle

- Restore host functionality first
- Then restore stable Linux boot
- Only reintroduce VFIO and passthrough devices once host is stable

This ensures the system remains recoverable even after misconfiguration.
