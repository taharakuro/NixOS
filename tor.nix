{ pkgs, ... }:

{
  services.tor = {
    enable = true;
    client.enable = true;
    settings = {
      SocksPort = 9050;
      UseBridges = true;
      ClientTransportPlugin = "obfs4 exec ${pkgs.obfs4}/bin/lyrebird";
    
      # Replace the example bridge line below with your actual bridges
      Bridge = [
        "obfs4 103.17.154.30:443 720287F3B90A804A3733F4E8DC1DD661B1B436EB cert=dljiSLoiFzk17K7ZWB0mMJQe+/bbFXo/B5SfjMBKDuYeuuGz6iN3+R/KkmjUn0NT2j+rBg iat-mode=0"
        "obfs4 217.217.243.39:8443 9E9968BFEAC4BB0A857400CBD83BD1BC77F64B4B cert=6iEWVvEBy3EaH5ESoimsujsHAhqll6kpJtPDJEJ8LAd9ZZqIzBom79R8mVsJPc8GiCuWCA iat-mode=2"
        "obfs4 95.217.11.29:22134 9859875C752128125D3179F90BA6351744B09040 cert=W+qSHr6JcFY6UyJiXR3Ec5I5bYHFwDAXNq8HRQU3C56h/aJB8PQqbr8Sq04zKvhEWGbxEw iat-mode=0"
        "obfs4 51.68.81.140:2098 F205CB5B969389061477609F8E03470B982F64C1 cert=6hFyrclX8Cg16jHGbtYqZxbGxj+p0flBn2EYZu+hvx/tGL4GROXSvBtwVQ1sRYFbi0++fQ iat-mode=0"
      ];
    };
  };
}
