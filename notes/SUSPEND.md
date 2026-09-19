# Suspend / s2idle on the IdeaPad Rembrandt

## Symptom

After switching from the custom pinned kernel to the NixOS default (`linuxPackages`, 6.18.52 on this branch), the laptop enters s2idle but never resumes — lid open, keyboard, power button, and USB receiver all fail to wake it. A hard reboot is required.

## Diagnosis

- `/proc/acpi/wakeup` showed `XHC0`, `XHC1`, `LID0` enabled.
- `/sys/.../PNP0C0D:00/power/wakeup` and the power button were enabled.
- The HS6209 receiver had `power/wakeup=enabled` and `power/control=on`.
- Journal from failed suspends stopped dead at `PM: suspend entry (s2idle)`.

So wakeup sources were not the problem. The kernel was entering a low-power state it could not exit.

## What was removed

All cargo-cult suspend workarounds were stripped:

- `configuration.nix`: removed `amdgpu.dcdebugmask`, `nvme_core.default_ps_max_latency_us`, `pcie_aspm=off`, `usbcore.autosuspend=-1`.
- `modules/hardware.nix`: removed the `setWakeupSources` script, the PCI/USB wakeup udev rules, and the three pre-sleep/resume systemd services.

## Actual fix

Use NixOS's standard latest kernel, which contains the s2idle fixes the custom 7.x kernel had:

```nix
boot.kernelPackages = pkgs.linuxPackages_latest;
```

This is not a pinned custom kernel — it tracks NixOS's normal `linuxPackages_latest` and gets updates with the rest of the system.

## Files involved

- `modules/hardware.nix` — kernel package selection.
- `configuration.nix` — no suspend-related kernel parameters remain.
- `modules/sway.nix` — keeps the explicit `HandleLidSwitch=suspend` logind setting; this is just the default made explicit.

## Validation

```bash
sudo nixos-rebuild switch --flake .#neko
# reboot, then test lid-close / manual suspend / idle suspend
```

If it still fails, capture:

```bash
journalctl -b 0 | grep -iE "suspend|resume|s2idle|PM:|amdgpu|xhci|nvme|amd_pmc"
```

from the boot after a failed suspend.
