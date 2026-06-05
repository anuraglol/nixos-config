{ pkgs, lib, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  swapDevices = lib.mkForce [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  # boot.kernelPatches =
  #   let
  #     # The fix is officially built into 7.0.10+ upstream
  #     needsBtfixed = lib.versionOlder pkgs.linuxPackages.kernel.version "7.0.10";
  #   in
  #   if !needsBtfixed then
  #     [ ]
  #   else
  #     [
  #       {
  #         name = "Bluetooth: btmtk: accept too short WMT FUNC_CTRL events";
  #         patch = pkgs.fetchurl {
  #           url = "https://git.kernel.org/pub/scm/linux/kernel/git/bluetooth/bluetooth-next.git/patch/?id=162b1adeb057d28ad84fd8a03f3c50cf08db5c62";
  #           hash = "sha256-ij0hQmC0U++AdXWQy6nycnDe6z4yaMoQIrSiLal5DHc=";
  #         };
  #       }
  #     ];

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
