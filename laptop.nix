{ ... }:

# Всё, что специфично именно для этого железа: ThinkPad на AMD Ryzen с
# NVMe-диском. На другой машине этот файл, скорее всего, целиком не нужен.
{
  # amd_pstate — родной P-State драйвер для процессоров Zen (ядро 6.3+);
  # "active" отдаёт выбор частоты самому CPU через встроенный
  # EPP-алгоритм вместо generic schedutil/ondemand — обычно лучший
  # баланс производительности и энергопотребления на Ryzen-ноутбуках.
  # См. https://wiki.nixos.org/wiki/AMD
  boot.kernelParams = [ "amd_pstate=active" ];

  # Разрешаем модулю thinkpad_acpi управлять вентилятором
  boot.extraModprobeConfig = "options thinkpad_acpi fan_control=1";

  services.thinkfan = {
    enable = true;

    # Датчики для AMD (материнская плата + процессор k10temp)
    sensors = [
      # Основные термодатчики шасси/платы ThinkPad
      {
        type = "hwmon";
        query = "/sys/devices/platform/thinkpad_hwmon/hwmon/hwmon*/temp*_input";
      }
      # Датчик температуры ядер процессора AMD Ryzen (k10temp)
      {
        type = "hwmon";
        query = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input";
      }
    ];

    # Настройки уровней вращения (оптимизированы под «горячий» буст AMD)
    levels = [
      [0 0 52]      # До 52°C полная тишина (вентилятор выключен)
      [1 48 60]     # Тихий режим для браузера и офиса
      [2 55 65]     # Средние обороты
      [3 60 72]     # Заметный обдув при стабильной нагрузке
      [5 67 80]     # Высокие обороты
      [7 75 32767]  # Максимальные обороты при сильном нагреве (от 75°C и выше)
    ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true; # нужно Steam / Proton для 32-битных игр
    };
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  # SSD/NVMe: fstrim.timer раз в неделю подчищает то, что не покрыто
  # discard=async на btrfs-субволюмах из disko.nix — сам ESP (vfat) под
  # discard=async не подпадает, поэтому периодический fstrim всё ещё
  # нужен. Про TRIM самого раздела подкачки — см. discardPolicy в
  # disko.nix.
  services.fstrim.enable = true;

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
}
