{ pkgs, config, lib, pydemo, ... }:

{
  name = "pydemo";
  extraModules = [ ./nixng-module.nix ];

  config = ({ pkgs, config, ... }: {
    config = {
      services.pydemo = {
        enable = true;
        package = pydemo;
      };
    };
  });

}
