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
        "obfs4 77.172.105.93:9003 A4E5433B40D668BEDFD21C44CE23A3A2B1764E16 cert=ag2zk0U2oQGjuSJrAMMA37pYupOJQIb/TU64WiOjtmSATa21NgxQR70+9dLaiCpZPw48BA iat-mode=0"
        "obfs4 38.244.136.91:4443 00CAFA3AB81AC615BDEA07953944698CE83160D9 cert=0zEMsL4+MbDac0NG3XhvbZcjbmKPtHuLw2vlQqxAW/V2+fszK/ENn6beRuUeK5l2ML+WNg iat-mode=0"
        "obfs4 51.89.231.85:24526 A44162645CEAA39C7106C49A3F36FD99FF8D8A00 cert=cVNRBh1enpvEGxA0ouu568EDFhWPl9taldydYgiJk77OX4MzoYIRz3qx4q7yHL5bRN60Gg iat-mode=0"
        "obfs4 51.89.228.250:21668 BA8BD67D8898CF378D4F73821DEB5657F4BB98DF cert=bEpLLgOwJ9fOJbeHb5r+ronUF2ck5nRd0Jl3zuy7rLoUp732QK2p/CUHjTAfBPCGfcVtSA iat-mode=0"
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
