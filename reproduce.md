# Storage Migration Log

## Problem

The 327GB data partition (nvme0n1p3) was physically located before the NixOS root partition (nvme0n1p5). Standard filesystem resizing only allows expanding into trailing unallocated space, making a traditional partition merge impossible without a slow and risky block-shifting process via a live USB.
Solution

Heavy home subdirectories were offloaded to the larger partition using system-level bind mounts configured in /etc/nixos/configuration.nix.
Nix

fileSystems."/home/anurag/Downloads" = {
device = "/data/Downloads";
options = [ "bind" "nofail" ];
};

fileSystems."/home/anurag/Videos" = {
device = "/data/Videos";
options = [ "bind" "nofail" ];
};

fileSystems."/home/anurag/Documents" = {
device = "/data/Documents";
options = [ "bind" "nofail" ];
};

## Path Layout and Links

    ~/data is a symlink pointing to /data.

    /data/Documents/nixos-config holds the physical configuration data.

    /etc/nixos is a system symlink pointing to ~/Documents/nixos-config.

    The system mounts /data/Documents directly over ~/Documents during boot/activation.

The Linux kernel resolves the bind mounts at the VFS layer before evaluating the symlinks, allowing the setup to function without recursive loops or breaking the configuration path. Node.js and Rust compilation speeds remain unaffected as both partitions reside on the same physical NVMe drive.
