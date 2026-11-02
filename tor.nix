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
        "obfs4 78.153.140.19:443 539F46F87EDF0A3FFC49D60F89F991BC0134A439 cert=6giqt3Iug4izk1EVd5HVrQsB+rtQ9U7t08zo85FRQq8xN65sfqIZXMN/JHwYcqTPl9uZPA iat-mode=0"
        "obfs4 67.193.154.130:9292 6E6BDC4B32691400CEDDD00F34554C3DFC61322F cert=HhTkzGPANqLEe6FIfxMDFx9osQuXctN5RVkgTgjmr9VRxj7Fx9YsVb42PpekoEaAx7AdSw iat-mode=0"
        "obfs4 91.134.11.193:26598 BDD9CB6525C0E7A53E325DF5418B234219389FD0 cert=LnHIWlJlwoWZVvMYK6OnYdvFpF2clJo8pqrmwI51ub1r0lI3P47xJl58L07LkM0kQERkPw iat-mode=0"
        "obfs4 57.129.117.251:61919 85F9547D13078145C9D894AFB981BA6E4B880B61 cert=TZc+BzJg7PNIxRt0uXt3aYVmALDwV3y0UeYAioxrPfjS3Fz9lE5oTOzoX2ShaCxVtuA+UQ iat-mode=0"
      ];
      # выделенный SOCKS-порт, не пересекается со стандартным клиентским 9050
      # (services.tor.client.enable выше)
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

  environment.systemPackages = [ pkgs.torsocks ];
}
