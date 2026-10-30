# Suspend / s2idle on the IdeaPad Rembrandt

> **Read this before touching anything suspend-related. The workarounds in
> `modules/hardware.nix` and `hardware-configuration.nix` are LOAD-BEARING.
> They have been stripped as "cargo cult" at least twice; each time the
> s2idle resume hang returned within days. Do not remove them without
> evidence from `amd_s2idle.py` proving they are unnecessary.**

## Symptom

Machine enters s2idle and never resumes: lid open, keyboard, touchpad, power
button, and USB receiver all fail to wake it. Hard reboot required. The
journal of the failed boot stops dead at `PM: suspend entry (s2idle)`.

Comes and goes in multi-day streaks, which makes every "fix" look correct
for a while. Always verify over several days and several suspend cycles.

## What it is NOT

Verified live on 2026-10-05, all correctly armed:

- `/proc/acpi/wakeup`: `LID0`, `XHC0`–`XHC4` enabled, everything else
  disabled (enforced by `set-wakeup-sources` at boot, on USB hotplug, and
  before every suspend — see `modules/hardware.nix`). Note: this machine has
  no `PWRB` entry; the power button wakes via a different path.
- `serio0` (internal PS/2 keyboard): `power/wakeup=enabled`.
- `i2c-FTCS0038:00` (touchpad) and `i2c-ITE8350:00` (EC): wakeup enabled.
- USB receiver (HS6209) and all xHCI PCI devices: wakeup enabled.

Wakeup sources were never the problem.

## Root cause (best current understanding)

The platform's **deepest S0ix substate has a broken exit path**. Once the
SoC descends fully, nothing can wake it. Anything that keeps the machine in
a shallower substate masks the bug.

Hard evidence (journal archaeology, 2026-10-05):

- Boot with `cloudflare-warp` installed: **7/7 suspends resumed**, including
  an 8-hour sleep. warp-svc's persistent WireGuard keepalives keep the SoC
  from reaching the deepest state.
- The very next generation removed warp — and **only** warp (verified with
  `nix store diff-closures`; identical kernel, initrd, cmdline, udev rules):
  **4/4 suspends hung** across four consecutive boots.

This also explains the older observations:

- "Caffeine/idle-inhibitor on = suspend works": display on keeps the
  pipeline powered → shallower sleep → resumes.
- "Suspending with outputs off hangs": display off → deeper descent → hang.
- "Randomly comes back every other day": whether the SoC reaches the deepest
  state depends on whatever background activity exists at the time.

## The defense (all layers, all load-bearing)

1. **Kernel params** (`modules/hardware.nix`) — keep devices/links from
   powering down far enough for the SoC to descend fully:
   - `pcie_aspm=off` — PCIe links stay up.
   - `nvme_core.default_ps_max_latency_us=0` — NVMe never enters deep APST.
   - `usbcore.autosuspend=-1` — USB stays runtime-resumed.
   - (`amdgpu.dcdebugmask=0x10`, `amdgpu.sg_display=0`, `amd_pstate=active`
     live in `hardware-configuration.nix`.)
2. **Never suspend with the display pipeline off** — compositor-side:
   - Niri: `suspend` keybind/timeout runs `niri msg action power-on-monitors`
     first, and swayidle's `before-sleep` does the same (`modules/niri.nix`).
     Note: `niri msg output on` is INVALID syntax (needs an output name);
     `power-on-monitors` is the global action. Use `;` not `&&` so an IPC
     failure can't swallow the suspend request.
3. **Wakeup source policy** (`set-wakeup-sources` in `modules/hardware.nix`):
   enforced at boot, on USB hotplug, and before every suspend. Defensive —
   verified not to be the root cause, but cheap insurance.
4. **Diagnostics always on**: `pm_debug_messages=1` via tmpfiles, so the
   next hang's journal shows exactly which device was mid-suspend.

Do NOT add `mem_sleep_default=deep` — firmware doesn't advertise S3; the
failed deep attempt itself breaks resume (amd-s2idle warns about this).

## If it ever hangs again

After the hard reboot:

```bash
# Which device was mid-suspend when it died (pm_debug_messages is on):
journalctl -b -1 | grep -iE "PM:|suspend|s2idle"
```

Then capture an actual s0ix report and use it to justify (or retire) the
kernel params above:

```bash
sudo amd_s2idle.py   # from kernel source tools/amd/pmc; needs a suspend cycle
sudo cat /sys/kernel/debug/amd_pmc/s0ix_stats
```

Only remove the params if the report shows the deepest state is reachable
AND exits cleanly across multiple cycles.

## Testing safely (no risk of losing work)

Program an RTC alarm so the machine wakes itself even if input wake fails:

```bash
sudo rtcwake -m no -s 60
systemctl suspend
# machine must come back on its own within ~60s
```

Then test each wake source: internal keyboard, touchpad, lid open/close,
USB receiver. Note kernel params require a REBOOT to take effect — a plain
`nixos-rebuild switch` is not enough.
