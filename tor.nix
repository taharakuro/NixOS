{ pkgs, ... }:
{
  services.privoxy = {
    enable = true;

    settings = {
      "listen-address" = "127.0.0.1:8118";
      "forward" = "/ .";

      "forward-socks5t" = [
        ".cache.nixos.org 127.0.0.1:9063 ."
        ".releases.nixos.org 127.0.0.1:9063 ."
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
        "obfs4 185.188.30.72:8450 D9874D876EC1EDF17CF3A1D8D8BD12A8B48E7B30 cert=yQNz/Dehiu2scMuIVdgfJEwLbvvNqWgQ6EI39XO+Hh0lGZ7KpWN8a3UE7omRogl4jR6kCw iat-mode=0"
        "obfs4 178.104.210.11:43103 90BACE93B4760594E5E5F7AA43698B5BA29BBBF0 cert=L46f5XBSKYNNI8FrWO+SHr6zKNL3ipPn8HCSazewvx11p0iTGwlhDHbgfC1x7GDyPSuFfg iat-mode=0"
        "obfs4 15.235.49.224:30844 883533723CE6BCFC59DA6E57C0D735A9DF931732 cert=MhVkLg0fLmmxExvOjltzA/WDZ2m3+Cx5zh8rJnV8YWW6HW7wsv+6Q/rs8xUckXQ5IiNCIA iat-mode=0"
        "obfs4 217.182.93.225:62782 D4FC51091A3D23F098354F660F2D5B17B2F3432C cert=UDjYbRlpv/GEc19L1dPssudaWQE83uxgUKxtUDQ7COumf1ERpup7+mcOvshJdO4Luh/Udw iat-mode=0"
      ];
      # выделенный SOCKS-порт под privoxy, не пересекается со стандартным
      # клиентским 9050 (services.tor.client.enable выше)
      SOCKSPort = [
        {
          addr = "127.0.0.1";
          port = 9063;
          flags = [ "IsolateDestAddr" "IsolateDestPort" ];
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
