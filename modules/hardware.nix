{ pkgs, lib, ... }:

let
  # Enforce the exact ACPI wakeup source policy:
  #   - LID0 (lid open), PWRB (power button), and XHC* (USB controllers) must
  #     be *enabled* so the laptop can be woken by opening the lid, pressing
  #     the power button, or external USB keyboards/mice.
  #   - Everything else must be *disabled*. Some firmware/ACPI devices get
  #     re-enabled by USB hotplug events and have broken s2idle resume on this
  #     machine in the past.
  # The script is invoked at boot and by a udev rule on every USB hotplug.
  setWakeupSources = pkgs.writeShellScript "set-wakeup-sources" ''
    while read -r device _ state _; do
      [ "$device" = "Device" ] && continue
      case "$device" in
        LID0|PWRB|XHC*)
          # Ensure these are enabled so lid, power button, and USB can wake.
          [ "$state" = "*enabled" ] || echo "$device" > /proc/acpi/wakeup
          ;;
        *)
          # Disable everything else; some get re-enabled by USB events and
          # have broken s2idle resume on this machine.
          [ "$state" = "*enabled" ] && echo "$device" > /proc/acpi/wakeup
          ;;
      esac
    done < /proc/acpi/wakeup
  '';
in
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # s2idle reliability workarounds — LOAD-BEARING, do not remove without
  # evidence from amd_s2idle.py. They look like cargo cult and have been
  # stripped as such at least twice; each time the s2idle resume hang
  # returned within days. See notes/SUSPEND.md.
  #
  # Root cause they mitigate: this platform's deepest S0ix substate has a
  # broken exit path — once the SoC descends fully, no wake source (keyboard,
  # lid, power button, RTC) can bring it back and the journal stops dead at
  # "PM: suspend entry (s2idle)". Verified 2026-10-05: suspend worked 7/7
  # (incl. an 8h sleep) in the boot where cloudflare-warp's keepalive traffic
  # kept the SoC shallow, and hung 4/4 across boots after it was removed,
  # with byte-identical kernel/initrd/cmdline/udev rules.
  #
  # These params keep PCIe links, the NVMe, and USB devices from powering
  # down far enough for the SoC to reach that state. They cost some idle
  # battery life; reliability is the priority here.
  boot.kernelParams = [
    # PCIe links stay up -> shallower s0ix, no L1.2 exit problems.
    "pcie_aspm=off"
    # NVMe never enters deep APST states (a common s0ix exit blocker).
    "nvme_core.default_ps_max_latency_us=0"
    # USB devices stay runtime-resumed so they can't block s0ix entry/exit.
    "usbcore.autosuspend=-1"
  ];

  # Log per-device suspend/resume timings. If a suspend ever hangs again, the
  # previous boot's journal will show exactly which device was mid-suspend
  # when it died: journalctl -b -1 | grep -iE "PM:|suspend"
  systemd.tmpfiles.rules = [
    "w /sys/power/pm_debug_messages - - - - 1"
  ];

  # NOTE: do NOT add mem_sleep_default=deep on this AMD machine. The firmware
  # doesn't advertise S3, so the kernel tries deep sleep, fails, exits, and
  # then falls back to s2idle. That failed deep-sleep attempt causes resume
  # problems and is explicitly warned against by amd-s2idle.

  swapDevices = lib.mkForce [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
      libva
      libva-utils
      mesa.opencl
    ];
  };

  environment.variables = {
    AMD_VULKAN_ICD = "RADV";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Enforce LID0/PWRB/XHC* as the only enabled ACPI wakeup sources. The rule
  # runs on every USB hotplug because USB events can re-enable other sources
  # (or even disable XHC*). Also enable wakeup for the internal PS/2 keyboard
  # (serio0) and the I2C HID touchpad so they can wake the machine from s2idle.
  services.udev.extraRules = ''
    ACTION=="add|change|remove", SUBSYSTEM=="usb", RUN+="${setWakeupSources}"
    ACTION=="add", SUBSYSTEM=="serio", KERNEL=="serio0", ATTR{power/wakeup}="enabled"
    ACTION=="add", SUBSYSTEM=="i2c", KERNEL=="i2c-ELAN0000:00", ATTR{power/wakeup}="enabled"
  '';

  systemd.services.set-wakeup-sources = {
    description = "Enforce ACPI wakeup source policy (LID0/PWRB/XHC* enabled)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${setWakeupSources}";
    };
  };

  # Re-assert the same policy right before every suspend, so a mid-session
  # USB hotplug event can never leave a wakeup source in the wrong state
  # for that suspend cycle.
  systemd.services.set-wakeup-sources-suspend = {
    description = "Re-assert ACPI wakeup source policy before suspend";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${setWakeupSources}";
    };
  };
}
