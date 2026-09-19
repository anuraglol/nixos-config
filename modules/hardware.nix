{ pkgs, lib, ... }:

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
}
