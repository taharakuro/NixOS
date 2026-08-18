{
  disko.devices.disk.nvme = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        swap = {
          size = "12G";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd:3" "noatime" "discard=async" ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd:3" "noatime" "discard=async" ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd:3" "noatime" "discard=async" ];
              };
              "@snapshots" = {
                mountpoint = "/.snapshots";
                mountOptions = [ "compress=zstd:3" "noatime" "discard=async" ];
                # Используется services.snapper.configs.root в
                # configuration.nix — сама по себе эта субволюм ничего
                # не снапшотит.
              };
            };
          };
        };
      };
    };
  };
}
