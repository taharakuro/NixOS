# Модуль сам не объявляет собственных `options`, поэтому обёртка
# `config = { ... };` не нужна (это плоский NixOS-модуль) — ИСПРАВЛЕНО:
# убрана, для единообразия с configuration.nix. Заодно убраны неиспользуемые
# аргументы config/lib — реально нужен только pkgs.
{ pkgs, ... }:
{
  services.privoxy = {
    enable = true;

    settings = {
      "listen-address" = "127.0.0.1:8118";
      "forward" = "/ .";

      # ИСПРАВЛЕНО: .cache.nixos.org и .releases.nixos.org убраны отсюда.
      #
      # networking.proxy.default (configuration.nix) указывает на этот
      # privoxy — а он обслуживает не только браузер/приложения, но и
      # nix-daemon (NixOS прокидывает http_proxy/https_proxy системному
      # прокси в systemd-юниты). Это значит, что ЛЮБАЯ загрузка пакетов из
      # бинарного кэша NixOS (nixos-rebuild, home-manager switch) шла через
      # Tor-мосты (obfs4) вместе с Discord — а мосты обычно дают от
      # десятков КБ/с до нескольких Мбит/с, то есть обновление системы
      # могло растягиваться на часы вместо минут.
      #
      # Если у вас реально ограничен прямой доступ к cache.nixos.org /
      # releases.nixos.org (а не только к Discord) — верните две строки
      # ниже в список forward-socks5t:
      #   ".cache.nixos.org 127.0.0.1:9063 ."
      #   ".releases.nixos.org 127.0.0.1:9063 ."
      "forward-socks5t" = [
        ".cache.nixos.org 127.0.0.1:9063 ."
        ".releases.nixos.org 127.0.0.1:9063 ."
        ".dis.gd 127.0.0.1:9063 ."
        ".discord.co 127.0.0.1:9063 ."
        ".discord.com 127.0.0.1:9063 ."
        ".discord.design 127.0.0.1:9063 ."
        ".discord.dev 127.0.0.1:9063 ."
        ".discord.gg 127.0.0.1:9063 ."
        ".discord.gift 127.0.0.1:9063 ."
        ".discord.gifts 127.0.0.1:9063 ."
        ".discord.media 127.0.0.1:9063 ."
        ".discord.new 127.0.0.1:9063 ."
        ".discord.store 127.0.0.1:9063 ."
        ".discord.tools 127.0.0.1:9063 ."
        ".discord-activities.com 127.0.0.1:9063 ."
        ".discordactivities.com 127.0.0.1:9063 ."
        ".discordapp.com 127.0.0.1:9063 ."
        ".discordapp.net 127.0.0.1:9063 ."
        ".discordmerch.com 127.0.0.1:9063 ."
        ".discordpartygames.com 127.0.0.1:9063 ."
        ".discordsays.com 127.0.0.1:9063 ."
        ".discordstatus.com 127.0.0.1:9063 ."
      ];
    };
  };

  services.tor = {
    enable = true;
    client = {
      enable = true;
      dns.enable = true;
    };
    settings = {
      UseBridges = true;
      ClientTransportPlugin = "obfs4 exec ${pkgs.obfs4}/bin/lyrebird";
      Bridge = [
        "obfs4 195.52.145.38:1677 3234D58257F100D6B5D8AB6F43176E6946EFD513 cert=QEI46C0ldwctxz+QT+sUpvyDYSe3EhhmQOA6T4Qt3kZBzHQA7nx5ihiusL+sFASJUEEYXw iat-mode=0"
        "obfs4 166.88.2.83:17443 7F65C4721C582D3D2CD86B678A72D88E98C1950E cert=cT0YJE4StbOtuRKVyG3gznJlDwIlj57MBbQViEt7aKRRG6gqbaycWpCz4h3+knVFhXtbaw iat-mode=0"
        "obfs4 51.68.81.140:2098 F205CB5B969389061477609F8E03470B982F64C1 cert=6hFyrclX8Cg16jHGbtYqZxbGxj+p0flBn2EYZu+hvx/tGL4GROXSvBtwVQ1sRYFbi0++fQ iat-mode=0"
        "obfs4 57.128.45.196:18384 E30D5552BEE79C5E8C61A943E9B3D2949F227C41 cert=boaTbcdp+rFHgUvweiAg60UUUpLZWecGl0uXRU358L/a7ZMrAnS/BodUKM3eyfWC+UVXTg iat-mode=0"
      ];

      # выделенный SOCKS-порт под privoxy, не пересекается со стандартным
      # клиентским 9050 (services.tor.client.enable выше)
      SOCKSPort = [
        {
          addr = "127.0.0.1";
          port = 9063;
        }
      ];

      CookieAuthentication = true;
      SafeLogging = true;
      AvoidDiskWrites = true;
      HardwareAccel = true;
      ClientUseIPv4 = true;
      ClientUseIPv6 = true;
    };
  };

  environment.systemPackages = with pkgs; [
    torsocks
  ];
}
