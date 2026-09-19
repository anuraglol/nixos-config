# Suspend / s2idle on the IdeaPad Rembrandt

## Symptom

After switching from the custom pinned kernel to the NixOS default (6.18.52 LTS on this branch), the laptop enters s2idle but never resumes — lid open, keyboard, power button, and USB receiver all fail to wake it. A hard reboot is required.

## Root cause

The existing `modules/hardware.nix` workarounds only configure **wakeup sources** (`/proc/acpi/wakeup`, PCI/USB `power/wakeup`). On the live system those are already correct:

- `XHC0` / `XHC1` enabled
- `LID0` enabled
- i8042/serio0 `power/wakeup` enabled
- HS6209 receiver `power/wakeup` enabled and `power/control` = `on`

The journal shows the hang happens right at `PM: suspend entry (s2idle)`, before any wake event is processed. That means the kernel is entering a low-power state it cannot exit, not that wakeup sources are misconfigured.

On this Rembrandt IdeaPad the 6.18 LTS kernel leaves **PCIe ASPM** and **USB autosuspend** active in the s2idle path. A device (GPU, NVMe, USB4 controller, or one of the XHCI hubs) enters a power state it cannot reliably resume from, so the platform hangs.

## Fix

Add two kernel parameters in `configuration.nix`:

```nix
boot.kernelParams = [
  "amdgpu.dcdebugmask=0x10"
  "nvme_core.default_ps_max_latency_us=0"

  # Keep PCIe ASPM and USB autosuspend out of s2idle.
  "pcie_aspm=off"
  "usbcore.autosuspend=-1"
];
```

- `pcie_aspm=off` — disables PCIe Active State Power Management so GPU/NVMe/USB4 controllers do not get stuck in low-power link states.
- `usbcore.autosuspend=-1` — disables USB autosuspend globally, so the HS6209 receiver and internal USB-connected devices stay powered and able to signal wake.

## Trade-offs

Idle power consumption will be slightly higher because PCIe links and USB devices no longer autosleep. For a laptop that cannot reliably suspend, this is the practical trade-off.

## If it still hangs

Next knobs to try, in order:

1. `amdgpu.runpm=0` — disable AMDGPU runtime power management (bigger power hit).
2. `processor.max_cstate=1` — limit CPU C-states (drastic, use only as last resort).
3. Unload `ideapad_laptop` around suspend via a pre-sleep/resume service.

## Files involved

- `configuration.nix` — kernel parameters (the actual fix).
- `modules/hardware.nix` — wakeup-source scripting and udev rules; kept in place, comment updated to point at the kernel params.

## Validation

```bash
nixos-rebuild switch --flake .#neko
# then reboot and test suspend
```
