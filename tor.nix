{ lib, pkgs, ... }:

{
  # Реальные адреса/сертификаты мостов теперь лежат в
  # ./secrets/tor-bridges.nix, который НЕ коммитится (добавьте его в
  # .gitignore). Если файла нет (например, на свежем клоне репозитория),
  # он просто не импортируется — но тогда UseBridges = true ниже останется
  # без списка мостов, и Tor не запустится, пока вы не положите файл на
  # место (или временно не поставите UseBridges = false).
  imports = lib.optional (builtins.pathExists ./tor-bridges.nix)
    ./tor-bridges.nix;

  services.privoxy = {
    enable = true;

    settings = {
      "listen-address" = "127.0.0.1:8118";
      "forward" = "/ .";
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
      # Раньше здесь стоял dns.enable = true — убрал: сам по себе этот
      # флаг лишь поднимает у tor отдельный DNS-резолвер на
      # 127.0.0.1:9053 (плюс AutomapHostsOnResolve для .onion), но
      # ничего не резолвит, пока какой-то системный DNS реально на
      # него не указывает (networking.nameservers = [ "127.0.0.1" ]
      # + settings.DNSPort). Без этой второй половины флаг был мёртвым
      # кодом — ничего не делал и ничему не мешал.
      #
      # Не стал доводить до конца сознательно: тогда ВЕСЬ системный
      # DNS пошёл бы через Tor, а не только домены из forward-socks5t
      # выше, — а смысл этого файла как раз в точечном, а не
      # поголовном пробросе через Tor. Домены из forward-socks5t и так
      # резолвятся анонимно: forward-socks5t (в отличие от
      # forward-socks5) означает, что privoxy передаёт Tor'у само имя
      # хоста, а не IP, и резолвит его уже exit-нода — отдельный
      # DNS-резолвер этому не нужен.
      #
      # Если всё же захотите весь системный DNS через Tor — берите
      # рецепт целиком с https://wiki.nixos.org/wiki/Tor
      # (client.dns.enable + settings.DNSPort + networking.nameservers
      # +, по желанию, services.resolved как кэширующий слой поверх),
      # а не только эту строку.
    };
    settings = {
      ## Использовать мосты
      UseBridges = true;
      ## obfs4 (Lyrebird)
      ClientTransportPlugin = "obfs4 exec ${pkgs.obfs4}/bin/lyrebird";
      ## Мосты — см. ./secrets/tor-bridges.nix (не в git)

      # "Быстрый" SOCKS без строгой изоляции — для nix-daemon ниже.
      # Обычный клиентский порт 9050 client.enable = true открывает сам,
      # трогать его не нужно; конфликта с этим отдельным портом нет,
      # т.к. адреса разные (9050 vs 9063).
      SOCKSPort = [
        {
          addr = "127.0.0.1";
          port = 9063;
        }
      ];

      ## Безопасность
      CookieAuthentication = true;
      SafeLogging = true;
      AvoidDiskWrites = true;
      HardwareAccel = true;
      ClientUseIPv4 = true;
      ClientUseIPv6 = true;
    };
  };

  environment.systemPackages = [
    pkgs.torsocks
  ];
}
