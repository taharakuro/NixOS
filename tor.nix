{ pkgs, ... }:

{
  services.tor = {
    enable = true;

    # Для клиента GeoIP не требуется
    enableGeoIP = false;

    client = {
      enable = true;

      # Создает DNSPort = 127.0.0.1:9053
      dns.enable = true;
    };

    # Позволяет использовать torsocks
    torsocks.enable = true;

    settings = {
      #
      # SOCKS и DNS
      #
      # SOCKSPort НЕ задаем вручную.
      # Его автоматически создает client.enable.
      #

      VirtualAddrNetwork = "10.192.0.0/10";
      AutomapHostsOnResolve = true;
      AutomapHostsSuffixes = [
        ".onion"
        ".exit"
      ];

      #
      # ControlPort
      #
      ControlPort = 9051;
      CookieAuthentication = true;

      #
      # Безопасность
      #
      SafeLogging = true;
      AvoidDiskWrites = true;
      ClientRejectInternalAddresses = true;
      AllowNonRFC953Hostnames = false;

      #
      # Изоляция цепочек
      #
      UseEntryGuards = true;
      EnforceDistinctSubnets = true;

      #
      # Проверка SOCKS
      #
      TestSocks = true;

      #
      # Аппаратное ускорение
      #
      HardwareAccel = true;

      #
      # Предупреждать о незашифрованных сервисах
      #
      WarnPlaintextPorts = [
        21
        23
        25
        80
        109
        110
        119
        143
      ];

      #
      # Bridges
      #
      UseBridges = true;

      ClientTransportPlugin =
        "obfs4 exec ${pkgs.obfs4}/bin/lyrebird";

      Bridge = [
        "obfs4 103.17.154.30:443 720287F3B90A804A3733F4E8DC1DD661B1B436EB cert=dljiSLoiFzk17K7ZWB0mMJQe+/bbFXo/B5SfjMBKDuYeuuGz6iN3+R/KkmjUn0NT2j+rBg iat-mode=0"

        "obfs4 217.217.243.39:8443 9E9968BFEAC4BB0A857400CBD83BD1BC77F64B4B cert=6iEWVvEBy3EaH5ESoimsujsHAhqll6kpJtPDJEJ8LAd9ZZqIzBom79R8mVsJPc8GiCuWCA iat-mode=2"

        "obfs4 95.217.11.29:22134 9859875C752128125D3179F90BA6351744B09040 cert=W+qSHr6JcFY6UyJiXR3Ec5I5bYHFwDAXNq8HRQU3C56h/aJB8PQqbr8Sq04zKvhEWGbxEw iat-mode=0"

        "obfs4 51.68.81.140:2098 F205CB5B969389061477609F8E03470B982F64C1 cert=6hFyrclX8Cg16jHGbtYqZxbGxj+p0flBn2EYZu+hvx/tGL4GROXSvBtwVQ1sRYFbi0++fQ iat-mode=0"
      ];
    };
  };
}
