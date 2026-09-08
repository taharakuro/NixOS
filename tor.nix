{ pkgs, ... }:
{

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
        "obfs4 82.67.170.186:59003 1B1238DD7B9BFFFE520B0BEF0C45C397F910BF22 cert=ZOMUyYS/jk4bRfWKD3WR7J/hlxnsoeUBa+uUWPdlV2BXFOwYVw6DP1Qd1vfGMdL8A/hDQw iat-mode=0"
        "obfs4 45.207.201.30:54321 8C237C0280231E1B912ADBD33D3DC28A8591C55B cert=runNUx4uvWyp2sgWMrF7P5XRwNzM8HHXeXovVCSnd5fG3jZjPSFqWG8gVd5UjhJaCHBlUQ iat-mode=0"
        "obfs4 91.134.45.152:60506 7AE2E2B622A5C1EAAB63C203B7C58788F502F4D0 cert=+r7Hj14Ox6vxKCQu5hkGPHp7f0NxAqE3hgysGruyC4yuMaU/9MJuNBXZy0znzk3q6O2cYw iat-mode=0"
        "obfs4 164.132.87.180:18197 C439802F7FEE4DEADD0A9BCF54A9ACA492B211FD cert=s9ZoBNAv9NOxX41LGvqZwU1qPrhpfEytQTdlcWO5Jo3e5sBZ8+FKkghy9LAHkn5D8GCDEw iat-mode=0"
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
