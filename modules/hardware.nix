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
    SUBSYSTEM=="pci", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"
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
