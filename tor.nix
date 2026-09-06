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
        "obfs4 89.166.191.219:8080 02F00A33017A24E99112E5CA498AECD204F913F3 cert=eWfCYOE/3kdmDpYy/tT0CuKI01dWKY6BtSAMSu0uuD4ixo7RE4/av+0fNjw4sbZmORLKVQ iat-mode=0"
        "obfs4 78.73.63.17:7004 6D97BE5B5D14E804F2FB77D400C56D6DCD48DF14 cert=75oVdEQnnqaofebCJuNwnpst2i+IX5UczCPwh/KTXiy+0CXGzVvKcb2yVffWClfFx7lvfA iat-mode=0"
        "obfs4 54.37.130.137:64989 F49BD145F36A405F1774542E4C276DBE90D4FC37 cert=m1r9Jlm/otc44ofvWggOuIM+s8iSdSd+cBZytcFk7xjZ/fDAQ6Is8jf322ezGVyaLBreOw iat-mode=0"
        "obfs4 145.239.29.43:24844 02B75E3D2513126B44667D28D476CB203A99DFAF cert=nVMhO4Dm2/Zmt1zjUqgS9y2Y2RrKkO/S06EhvU00dLLaToww5SxBXHqLvuDwH4g/Pa7WbQ iat-mode=0"
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
