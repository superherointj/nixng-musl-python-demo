{ pkgs, config, lib, nglib, ... }:

with nglib;
with lib;

let
  name = "pydemo";
  cfg = config.services.pydemo;
  dataDir = "/var/${name}";
in

{
  ### OPTIONS ###
  options.services.pydemo = {
    enable = mkEnableOption "Enable ${name}";

    package = mkOption {
      description = "${name} package to use.";
      # default = pkgs.pydemo;
      type = types.package;
    };

    # config = mkOption {
    #   description = ''
    #     Configuration options for ${name}.
    #   '';
    #   type = format.type;
    #   default = {};
    # };

    user = mkOption {
      description = "${name} user.";
      type = types.str;
      default = "${name}";
    };

    group = mkOption {
      description = "${name} group.";
      type = types.str;
      default = "${name}";
    };
  };

  ### CONFIG ###
  config = mkIf cfg.enable {

    ###############
    # Init System #
    ###############

    dumb-init = {
      enable = lib.mkDefault true;
      type.services = lib.mkDefault { };
    };

    init.services.pydemo = {
      enabled = true;
      script = pkgs.writeShellScript "pydemo-start.sh" ''
        echo "Starting pydemo..."
        ${cfg.package}/bin/pydemo
        exit 0
      '';
      finish = pkgs.writeShellScript "pydemo-end.sh" ''
        echo "Pydemo ended."
        exit 0
      '';
      shutdownOnExit = true;
    };

    # init.services.${name} = {
    #   enabled = true;
    #   script = pkgs.writeShellScript "${name}-run"
    #     ''
    #       mkdir -p ${dataDir}/{.,storage,data,config}

    #       chown -R ${cfg.user}:${cfg.group} ${dataDir}
    #       chmod -R u=rwX,g=r-X,o= ${dataDir}

    #       export PATH=$PATH:${cfg.package}/bin \
    #             HOME=${dataDir}/storage

    #       # chpst -u ${cfg.user}:${cfg.group} -b ${name} ${name} serve \
    #       #   --config=${dataDir}/config
    #     '';
    # };

    # runit = {
    #   enable = false;
    # };

    ### End of Init System

    environment.systemPackages = with pkgs; [ cfg.package ];

    users.users.${cfg.user} = mkDefaultRec {
      description = "${name}";
      group = cfg.group;
      createHome = false;
      home = "/var/empty";
      useDefaultShell = true;
      uid = 420; #config.ids.uids.pydemo;
    };

    users.groups.${cfg.group} = mkDefaultRec {
      gid = 420; #config.ids.gids.pydemo;
    };

  };
}
