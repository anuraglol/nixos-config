{ pkgs, lib, ... }:

let
  # Keep LID0 (lid open), PWRB (power button), and XHC* (USB controllers, so
  # external USB keyboards/mice can wake the machine). The internal keyboard
  # is PS/2 and the touchpad is I2C HID, so those are handled separately via
  # udev rules on their device power/wakeup attributes. Other ACPI wakeup
  # sources get re-enabled by USB events and historically broke s2idle resume
  # on this machine, so this script is invoked at boot and by a udev rule on
  # every USB hotplug.
  setWakeupSources = pkgs.writeShellScript "set-wakeup-sources" ''
    while read -r device _ state _; do
      case "$device" in
        # Keep LID0 so opening the lid wakes the machine, PWRB so the power
        # button can wake it when it suspended while the lid was open, and
        # XHC* so external USB keyboards/mice can wake it.
        Device|LID0|PWRB|XHC*) continue ;;
      esac
      if [ "$state" = "*enabled" ]; then
        echo "$device" > /proc/acpi/wakeup
      fi
    done < /proc/acpi/wakeup
  '';
in
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  # Keep LID0/PWRB/XHC* as ACPI wakeup sources. Other sources get re-enabled
  # by USB events and have broken s2idle resume on this machine in the past.
  # Also enable wakeup for the internal PS/2 keyboard (serio0) and the I2C
  # HID touchpad so they can wake the machine from s2idle.
  services.udev.extraRules = ''
    ACTION=="add|remove", SUBSYSTEM=="usb", RUN+="${setWakeupSources}"
    ACTION=="add", SUBSYSTEM=="serio", KERNEL=="serio0", ATTR{power/wakeup}="enabled"
  '';

  systemd.services.set-wakeup-sources = {
    description = "Disable ACPI wakeup sources except LID0";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${setWakeupSources}";
    };
  };
}
