{ pkgs, ... }:

let
  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "hyprland_kath";
  };
in

# Wayland-сессия: компоситор niri, менеджер входа, XDG-порталы, звук,
# Secret Service и шрифты.
{
  security.polkit.enable = true;

  programs = {
    dconf.enable = true;
    niri.enable = true;
    # Начиная с NixOS 25.11 модуль niri сам добавляет xwayland-satellite
    # в PATH (programs.niri.xwayland-satellite.enable = true по
    # умолчанию, т.к. niri интегрируется с ним "из коробки" с версии
    # 25.08 и запускает по требованию, когда приходит X11-клиент) —
    # раньше пакет приходилось прописывать руками в
    # environment.systemPackages, теперь не нужно. xwayland.enable ниже
    # оставлен: он ставит сам бинарник Xwayland, которым пользуется
    # xwayland-satellite, а не наоборот. См. https://wiki.nixos.org/wiki/Niri
    xwayland.enable = true;
    firefox = {
      enable = true;
      languagePacks = [ "ru" "en-US" ];
      preferences = {
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };
    };
  };

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    wayland.enable = true;
    extraPackages = with pkgs; [
      kdePackages.qtmultimedia # Required for video backgrounds/audio
    ];
    theme = "sddm-astronaut-theme";
  };
  environment.systemPackages = [ sddm-astronaut ];

  # niri по умолчанию (через свой niri-portals.conf) шлёт запросы
  # Screenshot/ScreenCast в xdg-desktop-portal-gnome, а не в -wlr — так что
  # именно gnome-портал и нужно ставить, чтобы шаринг экрана/скриншоты
  # реально работали. -gtk оставляем для FileChooser и обычных GTK-приложений.
  # gnome-портал по умолчанию открывает диалог выбора файла через
  # Nautilus (она уже стоит через home.nix) — без неё портал падает.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };
  security.rtkit.enable = true;

  # Secret Service (хранилище паролей Wi-Fi/браузера/git-credential).
  # Сам демон gnome-keyring уже включён модулем programs.niri
  # (services.gnome.gnome-keyring.enable = lib.mkDefault true в
  # nixos/modules/programs/wayland/niri.nix, nixpkgs release-26.05) —
  # отдельно его тут больше не включаем. А вот enableGnomeKeyring нужен
  # именно под sddm (а не "login"), иначе связка pam+keyring не
  # разблокируется автоматически при входе — этого модуль niri не делает.
  # См. https://wiki.nixos.org/wiki/Secret_Service и
  # https://wiki.nixos.org/wiki/Niri (раздел "Example systemd Setup")
  security.pam.services.sddm.enableGnomeKeyring = true;

  # Тот же раздел wiki рекомендует отдельный PAM-сервис для swaylock —
  # без него он либо не примет пароль, либо упадёт на общий/неверный
  # стек аутентификации. swaylock у нас — аварийный лок на случай, если
  # упадёт сам noctalia (см. home.nix); основной лок — встроенный в
  # noctalia (Mod+Alt+L в keybinds.kdl).
  security.pam.services.swaylock = {};

  services.gvfs.enable = true; # трэш/MTP/сеть для Nautilus

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      font-awesome
      fira-code
      dejavu_fonts
      freefont_ttf
    ];
    fontDir.enable = true;
    fontconfig.enable = true;
  };
}
