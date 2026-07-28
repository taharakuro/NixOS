{ pkgs, lib, inputs, ... }:

# Игры и Windows-совместимость: Steam/Proton, Wine, PrismLauncher.
let
  # Бинарник берётся прямо из апстримного флейка PrismLauncher (см.
  # комментарий у prismlauncher.url в flake.nix) в обход обычной обёртки
  # wrapGAppsHook, которую даёт версия из nixpkgs. Из-за этого GLib/GIO
  # внутри программы не находит скомпилированные GSettings-схемы
  # (например, при открытии нативного диалога выбора файла) и падает с
  # "GLib-GIO-ERROR: No GSettings schemas are installed on the system"
  # (SIGABRT/SIGTRAP) — типовая проблема на не-GNOME/KDE окружениях
  # вроде niri. symlinkJoin + wrapProgram донабрасывают нужные пути в
  # XDG_DATA_DIRS/GIO_EXTRA_MODULES, как это делает для GTK-приложений
  # сам wrapGAppsHook в nixpkgs.
  prismlauncher-wrapped = pkgs.symlinkJoin {
    name = "prismlauncher-wrapped";
    paths = [ inputs.prismlauncher.packages.${pkgs.system}.prismlauncher ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/prismlauncher \
        --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}" \
        --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
        --prefix GIO_EXTRA_MODULES : "${lib.getLib pkgs.dconf}/lib/gio/modules"
    '';
  };
in
{
  programs = {
    steam.enable = true;
    gamemode.enable = true;
    obs-studio.enable = true;
  };

  environment.systemPackages = [
    prismlauncher-wrapped
    pkgs.wineWow64Packages.waylandFull
    pkgs.winetricks
  ];
}
