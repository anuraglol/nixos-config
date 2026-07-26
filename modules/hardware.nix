{ pkgs, lib, ... }:

let
in
{
  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linux_latest.override {
      argsOverride = rec {
        version = "7.0.10";
        modDirVersion = version;
        src = pkgs.fetchurl {
          url = "https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-${version}.tar.xz";
          sha256 = "sha256-CUl362LCDj0ZOf6BqSlYofmH8zlEblMvqGljsoBOMtw=";
        };
      };
    }
  );

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

    # The HS6209 2.4G wireless receiver is the only reliable s2idle wake source
    # on this IdeaPad AMD platform (the internal keyboard / power button do not
    # generate wake events). Keep it enabled and prevent USB autosuspend so it
    # does not flake out between suspend cycles.
    SUBSYSTEM=="usb", ATTR{idVendor}=="32c2", ATTR{idProduct}=="0018", ATTR{power/wakeup}="enabled", ATTR{power/control}="on"
  '';

  systemd.services.disable-gpp-wakeup = {
    path = [
      pkgs.gnugrep
      pkgs.coreutils
    ];
    description = "Disable GPP/GP PCIe bridge wakeup sources";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart =
        let
          script = pkgs.writeShellScript "disable-gpp-wakeup" ''
            for dev in GPP1 GPP6 GPP7 GP19; do
              if grep -q "^''${dev}.*enabled" /proc/acpi/wakeup; then
                echo "$dev" > /proc/acpi/wakeup
                echo "disabled $dev"
              fi
            done
          '';
        in
        "${script}";
    };
  };

  systemd.services.enable-xhci-wakeup = {
    path = [
      pkgs.gnugrep
      pkgs.coreutils
    ];
    description = "Enable XHC0/XHC1 ACPI wakeup sources for USB keyboard/mouse";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart =
        let
          script = pkgs.writeShellScript "enable-xhci-wakeup" ''
            for dev in XHC0 XHC1; do
              if grep -q "^''${dev}.*disabled" /proc/acpi/wakeup; then
                echo "$dev" > /proc/acpi/wakeup
                echo "enabled $dev"
              fi
            done
          '';
        in
        "${script}";
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
