# Suspend / s2idle on the IdeaPad Rembrandt

## Symptom

After switching from the custom pinned kernel to the NixOS default (`linuxPackages`, 6.18.52 on this branch), the laptop enters s2idle but never resumes — lid open, keyboard, power button, and USB receiver all fail to wake it. A hard reboot is required.

Later observation: the hang only happens when the waybar **caffeine/idle inhibitor is off**. With the inhibitor on, suspend and resume work reliably.

## Diagnosis

- `/proc/acpi/wakeup` showed `XHC0`, `XHC1`, `LID0` enabled.
- `/sys/.../PNP0C0D:00/power/wakeup` and the power button were enabled.
- The HS6209 receiver had `power/wakeup=enabled` and `power/control=on`.
- Journal from failed suspends stopped dead at `PM: suspend entry (s2idle)`.
- Wakeup sources were not the problem.

The caffeine clue points to `swayidle`: when the idle inhibitor is off, `swayidle` turns the display off at 300s and suspends at 600s. Suspending while Sway has the display powered off hangs this AMD Rembrandt platform in s2idle. With caffeine on, the display never auto-powers off, so suspend resumes normally.

Confirmed by running `systemctl suspend` directly while the display had been powered off by `swayidle`: the system did not resume.

## What was removed

All cargo-cult suspend workarounds were stripped:

- `configuration.nix`: removed `amdgpu.dcdebugmask`, `nvme_core.default_ps_max_latency_us`, `pcie_aspm=off`, `usbcore.autosuspend=-1`.
- `modules/hardware.nix`: removed the `setWakeupSources` script, the PCI/USB wakeup udev rules, and the three pre-sleep/resume systemd services.

## Actual fix

Two parts:

1. Use NixOS's standard latest kernel (7.2.6 on this branch), which contains the s2idle fixes the custom 7.x kernel had:

   ```nix
   # modules/hardware.nix
   boot.kernelPackages = pkgs.linuxPackages_latest;
   ```

2. **Never suspend while Sway has powered the outputs off.**

   - Removed the 300s `output * power off` timeout from `swayidle`. The display stays on until the 600s auto-suspend.
   - Added a `suspendCmd` that wakes outputs before suspending, used by:
     - the `Mod+Shift+z` keybinding,
     - the 600s `swayidle` auto-suspend timeout,
     - the `before-sleep` event (runs before `swayidle` triggers suspend).

   ```nix
   # modules/sway-home.nix
   suspendCmd = "${swaymsg} 'output * power on' && ${systemctl} suspend";
   ```

This avoids entering s2idle while the display is in the powered-off state that triggers the hang.

## Files involved

- `modules/hardware.nix` — kernel package selection.
- `modules/sway-home.nix` — suspend command and `swayidle` config.
- `configuration.nix` — no suspend-related kernel parameters remain.
- `modules/sway.nix` — keeps the explicit `HandleLidSwitch=suspend` logind setting.

## Trade-offs

The display now stays on for the full 10-minute idle period instead of blanking at 5 minutes. This costs a little idle battery life, but it keeps s2idle reliable. The screen still locks at 5 minutes for security.

## Validation

```bash
sudo nixos-rebuild switch --flake .#neko
```

Then test with caffeine **off**:
1. `Mod+Shift+z` → wait 5s → keypress.
2. Leave idle for 10+ minutes so `swayidle` auto-suspends → keypress.
3. Close lid → open lid.

If any path still fails, capture from the next boot:
```bash
journalctl -b 0 | grep -iE "suspend|resume|s2idle|PM:|amdgpu|xhci|nvme|amd_pmc|swayidle"
```
