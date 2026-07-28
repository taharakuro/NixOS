{ pkgs, ... }:

# Пользовательские приложения без собственных системных опций. Если
# программе нужен programs.<x>.enable или services.<x> — ей место в
# desktop.nix / gaming.nix / virtualisation.nix, а не здесь.
{
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    fastfetch
    htop
    btop
    tree
    ripgrep
    fd
    telegram-desktop
    discord
    mpvpaper
    vlc
    ffmpeg
    eog
    spotify
    gedit
    obsidian
    jdk21
    distrobox
    fragments
    xdelta
  ];
}
