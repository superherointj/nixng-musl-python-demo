{ pkgs, config, lib, pydemo, ... }:

{
  name = "pydemo";
  extraModules = [ ./nixng-module.nix ];

  config = ({ pkgs, config, ... }: {
    config = {
      dumb-init = {
        enable = true;
        type.services = { };
      };
      services.pydemo = {
        enable = true;
        package = pydemo; # .override({ withSystemd = false; });
      };
    };
  });
}
