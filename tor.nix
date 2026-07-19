{ pkgs, ... }:

{
  services.tor = {
    enable = true;

    client = {
      enable = true;

      # Отключаем автогенерацию SOCKSPort
      socksListenAddress = 0;

      # DNSPort будет создан автоматически (127.0.0.1:9053)
      dns.enable = true;
    };

    settings = {
      VirtualAddrNetwork = "10.192.0.0/10";
      AutomapHostsOnResolve = true;
      AutomapHostsSuffixes = ".exit,.onion";

      # SOCKS
      SOCKSPort = [{
        addr = "127.0.0.1";
        port = 9050;
        IsolateClientAddr = true;
        IsolateSOCKSAuth = true;
        IsolateClientProtocol = true;
        IsolateDestPort = true;
        IsolateDestAddr = true;
      }];

      # Transparent proxy
      TransPort = [{
        addr = "127.0.0.1";
        port = 9040;
        IsolateClientAddr = true;
        IsolateSOCKSAuth = true;
        IsolateClientProtocol = true;
        IsolateDestPort = true;
        IsolateDestAddr = true;
      }];

      ControlPort = 9051;
      HashedControlPassword =
        "16:FDE8ED505C45C8BA602385E2CA5B3250ED00AC0920FEC1230813A1F86F";

      HardwareAccel = true;
      TestSocks = true;
      AllowNonRFC953Hostnames = false;
      WarnPlaintextPorts = "23,109,110,143,80";
      ClientRejectInternalAddresses = true;

      # Улучшенная политика цепей
      NewCircuitPeriod = 40;
      MaxCircuitDirtiness = 600;
      MaxClientCircuitsPending = 48;
      UseEntryGuards = true;
      EnforceDistinctSubnets = true;

      # Bridges
      UseBridges = true;
      ClientTransportPlugin =
        "obfs4 exec ${pkgs.obfs4}/bin/lyrebird";

      Bridge = [
        "obfs4 94.156.153.217:31337 AF9EABB157AE185E3D0F030D6F21C2044A794976 cert=Gg+YPaGTlB30p7x45igqEJQ4Af/8HqgbIzwJ1GBzqto1xSDS/k5H83mttmUh0Zob+vrQWw iat-mode=0"
        "obfs4 85.215.50.238:10007 D27430CDF128406ED556434E8F908749EE6D0198 cert=GBiBNfVY/4VSWG6Qx7HmsPMB6WAq80HIr8JUUkTdxsk2L5QdrjdZap8WjyrpaizU58SQGA iat-mode=0"
        "obfs4 138.199.220.200:22884 B5ECD5289F4F663B9A4C468D36CCFFD312FE77CD cert=xpoNaNFgDPxfa3SKpVrrNp7fSJiTVmzrwLZhIAN8KD/b1O8EL8w3qO5+Msjo9y5AxI3iSA iat-mode=0"
        "obfs4 51.38.220.56:34330 77A68E8693D3FE3A97BCC1E616CA4A04E49EABC8 cert=xcMquIYqYnUgL3FOPKLrujmGy/dTGVbo4asFt5UHWn3OSQ1/dpwfWUIeCMNmPC8fpN9/LQ iat-mode=0"
      ];
    };
  };
}
