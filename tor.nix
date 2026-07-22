{ config, lib, pkgs, ... }:

{
  config = {
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
        # При необходимости:
        dns.enable = true;
      };
      settings = {
        ## Использовать мосты
        UseBridges = true;
        ## obfs4 (Lyrebird)
        ClientTransportPlugin = "obfs4 exec ${pkgs.obfs4}/bin/lyrebird";
        ## Мосты
        Bridge = [
			"obfs4 195.52.145.38:1677 3234D58257F100D6B5D8AB6F43176E6946EFD513 cert=QEI46C0ldwctxz+QT+sUpvyDYSe3EhhmQOA6T4Qt3kZBzHQA7nx5ihiusL+sFASJUEEYXw iat-mode=0"
			"obfs4 166.88.2.83:17443 7F65C4721C582D3D2CD86B678A72D88E98C1950E cert=cT0YJE4StbOtuRKVyG3gznJlDwIlj57MBbQViEt7aKRRG6gqbaycWpCz4h3+knVFhXtbaw iat-mode=0"
			"obfs4 51.68.81.140:2098 F205CB5B969389061477609F8E03470B982F64C1 cert=6hFyrclX8Cg16jHGbtYqZxbGxj+p0flBn2EYZu+hvx/tGL4GROXSvBtwVQ1sRYFbi0++fQ iat-mode=0"
			"obfs4 57.128.45.196:18384 E30D5552BEE79C5E8C61A943E9B3D2949F227C41 cert=boaTbcdp+rFHgUvweiAg60UUUpLZWecGl0uXRU358L/a7ZMrAnS/BodUKM3eyfWC+UVXTg iat-mode=0"
        ];

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

    environment.systemPackages = with pkgs; [
      torsocks
    ];
  };
}
