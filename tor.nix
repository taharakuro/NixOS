# Tor-клиент с мостами obfs4 (обход DPI-блокировок). Всё слушает только
# на 127.0.0.1 — наружу ничего не торчит, firewall трогать не нужно.
{ pkgs, ... }:

{
  services.tor = {
    enable = true;

    client = {
      # ВАЖНО: без client.enable = true модуль принудительно выставляет
      # SOCKSPort = [ 0 ] (полностью глушит SOCKS), даже если ниже задан
      # свой SOCKSPort в settings — открытый баг nixpkgs #445350.
      enable = true;

      # По умолчанию client.enable сам добавляет ещё один SOCKSPort
      # 127.0.0.1:9050 (свой дефолт) вдобавок к нашему — с тем же
      # адресом:портом это дублирующее связывание, из-за которого демон
      # не стартует (nixpkgs #48622). "0" отключает автодобавление,
      # порт целиком описываем сами в settings.SOCKSPort ниже.
      socksListenAddress = 0;

      # Та же история с DNSPort — без dns.enable = true он тоже рискует
      # быть проигнорирован/обнулён модулем.
      dns.enable = true;
    };

    settings = {
      VirtualAddrNetwork = "10.192.0.0/10";
      AutomapHostsOnResolve = true;
      AutomapHostsSuffixes = ".exit,.onion";

      SOCKSPort = [
        {
          addr = "127.0.0.1";
          port = 9050;
          IsolateClientAddr = true;
          IsolateSOCKSAuth = true;
          IsolateClientProtocol = true;
          IsolateDestPort = true;
          IsolateDestAddr = true;
        }
      ];
      TransPort = [
        {
          addr = "127.0.0.1";
          port = 9040;
          IsolateClientAddr = true;
          IsolateSOCKSAuth = true;
          IsolateClientProtocol = true;
          IsolateDestPort = true;
          IsolateDestAddr = true;
        }
      ];
      # DNSPort сюда специально не пишем: тип этой опции — не строка, а
      # число/сабмодуль { addr; port; } (или список таких), обычная
      # строка "127.0.0.1:9053" не проходит проверку типов. При этом
      # client.dns.enable = true выше уже сам добавляет слушатель ровно
      # на 127.0.0.1:9053 — то, что нужно, без лишней ручной записи.

      ControlPort = 9051;
      HashedControlPassword = "16:FDE8ED505C45C8BA602385E2CA5B3250ED00AC0920FEC1230813A1F86F";

      # Sandbox 1 не включаем: пакет tor в nixpkgs не собран с
      # --enable-seccomp, эта опция требует его (как и было
      # закомментировано в исходном конфиге).

      HardwareAccel = true;
      TestSocks = true;
      AllowNonRFC953Hostnames = false;
      WarnPlaintextPorts = "23,109,110,143,80";
      ClientRejectInternalAddresses = true;
      NewCircuitPeriod = 40;
      MaxCircuitDirtiness = 600;
      MaxClientCircuitsPending = 48;
      UseEntryGuards = true;
      EnforceDistinctSubnets = true;

      UseBridges = true;
      # Пакет и бинарник называются obfs4 / lyrebird в текущем nixpkgs —
      # апстрим переименовал obfs4proxy в lyrebird; /usr/bin/obfs4proxy
      # из исходного конфига на NixOS просто не существует.
      ClientTransportPlugin = "obfs4 exec ${pkgs.obfs4}/bin/lyrebird";
      Bridge = [
        "obfs4 94.156.153.217:31337 AF9EABB157AE185E3D0F030D6F21C2044A794976 cert=Gg+YPaGTlB30p7x45igqEJQ4Af/8HqgbIzwJ1GBzqto1xSDS/k5H83mttmUh0Zob+vrQWw iat-mode=0"
        "obfs4 85.215.50.238:10007 D27430CDF128406ED556434E8F908749EE6D0198 cert=GBiBNfVY/4VSWG6Qx7HmsPMB6WAq80HIr8JUUkTdxsk2L5QdrjdZap8WjyrpaizU58SQGA iat-mode=0"
        "obfs4 138.199.220.200:22884 B5ECD5289F4F663B9A4C468D36CCFFD312FE77CD cert=xpoNaNFgDPxfa3SKpVrrNp7fSJiTVmzrwLZhIAN8KD/b1O8EL8w3qO5+Msjo9y5AxI3iSA iat-mode=0"
        "obfs4 51.38.220.56:34330 77A68E8693D3FE3A97BCC1E616CA4A04E49EABC8 cert=xcMquIYqYnUgL3FOPKLrujmGy/dTGVbo4asFt5UHWn3OSQ1/dpwfWUIeCMNmPC8fpN9/LQ iat-mode=0"
      ];
    };
  };
}
