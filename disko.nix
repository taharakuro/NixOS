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
          # ВАЖНО: resumeDevice = true подразумевает гибернацию (сон на
          # диск). Для неё своп должен быть >= объёма RAM. Если у машины
          # больше 4 ГБ памяти, гибернация с текущим размером не сработает —
          # либо увеличьте size, либо уберите resumeDevice, если гибернация
          # не нужна.
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
              };
            };
          };
        };
      };
    };
  };
}
