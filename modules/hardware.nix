{ pkgs, lib, ... }:

let
  setWakeupSources = pkgs.writeShellScript "set-wakeup-sources" ''
    # Disable spurious PCIe bridge wakeup sources.
    for dev in GPP1 GPP6 GPP7 GP19; do
      if grep -q "^''${dev}.*enabled" /proc/acpi/wakeup; then
        echo "$dev" > /proc/acpi/wakeup
        echo "disabled $dev"
      fi
    done

    # Enable primary XHCI controllers so USB keyboard / mouse / dongle can wake.
    for dev in XHC0 XHC1; do
      if grep -q "^''${dev}.*disabled" /proc/acpi/wakeup; then
        echo "$dev" > /proc/acpi/wakeup
        echo "enabled $dev"
      fi
    done
  '';
in
{
  boot.kernelPackages = pkgs.linuxPackages;

  swapDevices = lib.mkForce [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  services.udev.extraRules = ''
    # Disable xhci wakeup for USB4/Thunderbolt controllers only; these are the
    # spurious-wake culprits on Rembrandt laptops. Keep both primary AMD USB
    # controllers (04:00.3 / 04:00.4) enabled so any internally-USB-connected
    # devices (keyboard, trackpad) can also wake the system.
    SUBSYSTEM=="pci", KERNEL=="0000:05:00.0", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"
    SUBSYSTEM=="pci", KERNEL=="0000:05:00.3", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"
    SUBSYSTEM=="pci", KERNEL=="0000:05:00.4", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"

    # Enable wakeup for the primary AMD USB controllers.
    SUBSYSTEM=="pci", KERNEL=="0000:04:00.3", DRIVER=="xhci_hcd", ATTR{power/wakeup}="enabled"
    SUBSYSTEM=="pci", KERNEL=="0000:04:00.4", DRIVER=="xhci_hcd", ATTR{power/wakeup}="enabled"

    # Enable the root hubs so remote-wakeup signals reach the system.
    SUBSYSTEM=="usb", KERNEL=="usb1", ATTR{power/wakeup}="enabled"
    SUBSYSTEM=="usb", KERNEL=="usb2", ATTR{power/wakeup}="enabled"
    SUBSYSTEM=="usb", KERNEL=="usb3", ATTR{power/wakeup}="enabled"
    SUBSYSTEM=="usb", KERNEL=="usb4", ATTR{power/wakeup}="enabled"

    # The HS6209 2.4G wireless receiver is the most reliable s2idle wake source
    # on this IdeaPad AMD platform. Keep it enabled and out of autosuspend so it
    # does not flake out between suspend cycles. (Global USB autosuspend and PCIe
    # ASPM are disabled via kernel params in configuration.nix to avoid the s2idle
    # hang seen on the 6.18 LTS kernel.)
    SUBSYSTEM=="usb", ATTR{idVendor}=="32c2", ATTR{idProduct}=="0018", ATTR{power/wakeup}="enabled", ATTR{power/control}="on"
  '';

  systemd.services.set-wakeup-sources = {
    path = [
      pkgs.gnugrep
      pkgs.coreutils
    ];
    description = "Configure ACPI wakeup sources";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${setWakeupSources}";
    };
  };

  # Re-apply right before suspend/hibernate in case something reset them.
  systemd.services.set-wakeup-sources-pre-sleep = {
    path = [
      pkgs.gnugrep
      pkgs.coreutils
    ];
    description = "Re-apply ACPI wakeup sources before sleep";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${setWakeupSources}";
    };
  };

  # Re-apply after resume as well.
  systemd.services.set-wakeup-sources-resume = {
    path = [
      pkgs.gnugrep
      pkgs.coreutils
    ];
    description = "Re-apply ACPI wakeup sources after resume";
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${setWakeupSources}";
    };
  };

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
}
