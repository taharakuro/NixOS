{ pkgs, ... }:

{
  virtualisation = {
    docker.enable = true;
    vmware.host.enable = true;
  };

  environment.systemPackages = [ pkgs.vmware-workstation ];
}
