{ pkgs, lib, ... }:

let
  # This laptop only resumes reliably from s2idle when LID0 is the sole ACPI
  # wakeup source. USB plug/unplug events re-enable other sources, so this
  # script is invoked at boot and by a udev rule on every USB hotplug.
  setWakeupSources = pkgs.writeShellScript "set-wakeup-sources" ''
    while read -r device _ state _; do
      case "$device" in
        Device|LID0) continue ;;
      esac
      if [ "$state" = "*enabled" ]; then
        echo "$device" > /proc/acpi/wakeup
      fi
    done < /proc/acpi/wakeup
  '';
in
{
  # The 6.18 "LTS" default on this NixOS branch hangs at s2idle entry. The
  # previously-working custom kernel was a 7.x release; use NixOS's standard
  # latest kernel instead of pinning anything.
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  # Keep only LID0 as an ACPI wakeup source. Other sources (XHC0/XHC1/etc.)
  # get re-enabled by USB events and break s2idle resume on this machine.
  services.udev.extraRules = ''
    ACTION=="add|remove", SUBSYSTEM=="usb", RUN+="${setWakeupSources}"
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
