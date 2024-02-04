{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # NixNG is NixOS but for containers without systemd.
    # For Glibc, use upstream:
    # nixng.url = "github:nix-community/NixNG";
    # nixng.inputs.nixpkgs.follows = "nixpkgs";
    # For Musl, I'm temporarily using a fork with patches (for lack of wrapper in upstream)
    # nixng-musl.url = "github:superherointj/NixNG/master-patched";
    # nixng-musl.inputs.nixpkgs.follows = "nixpkgs";
    # Will test NixNg with Musl directly:
    nixng.url = "github:superherointj/NixNG/master-patched";
    nixng.inputs.nixpkgs.follows = "nixpkgs";
    # nix2container generates containers in a more efficient way
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.flake-utils.follows = "flake-utils";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    # Package overlay with fixes
    nixpkgs-friendly-overlay.url = "github:nixpkgs-friendly/nixpkgs-friendly-overlay";
    nixpkgs-friendly-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixng, nixpkgs, flake-utils, nix2container, nixpkgs-friendly-overlay }@inputs:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              nixpkgs-friendly-overlay.overlays.default
              nixng.overlays.default
            ];
          };

        nixng-import = path: attrs:
          nixng.nglib.makeSystem ((import path attrs) // { inherit system; nixpkgs=nixpkgs; });
      in
      rec {
        defaultPackage = packages.pydemo;
        hydraJobs = if (system == "aarch64-linux" || system == "x86_64-linux") then {
          pydemo = packages.pydemo;
          pydemo-container = packages.pydemo-container;
        } else { };
        packages =
          let liftPackages = thisPkgs:
            with { inherit (thisPkgs) callPackage; };
            rec {
              pydemo = callPackage ./default.nix { };
              pydemo-musl = thisPkgs.pkgsMusl.callPackage ./default.nix { };
              pydemo-container = callPackage ./default-container.nix { inherit pydemo; };
              pydemo-container-musl = thisPkgs.pkgsMusl.callPackage ./default-container.nix { pydemo = pydemo-musl; };

              pydemo-container-nixng-musl = (nixng-import ./default-container-nixng-musl.nix {
                pkgs=pkgs.pkgsMusl;
                pydemo=pydemo-musl;
                inherit config lib;
              }).config.system.build.ociImage.build;

              # pydemo-container-nixng-musl = (nixng-import ./default-container-nixng.nix { pydemo=pydemo-musl; pkgs=pkgs.pkgsMusl; inherit config lib; }).config.system.build.ociImage.build;

              # pydemo-nixng = (nixng-import ./default-container-nixng.nix { pydemo=pydemo; pkgs=pkgs.pkgsMusl; inherit config lib; }).config.system.build.toplevel;
            };
        in
         {
            inherit pkgs;
            pkgsDebug = liftPackages pkgs;
            pkgsMusl = liftPackages pkgs.pkgsMusl;
            pkgsMuslStatic = liftPackages pkgs.pkgsMusl.pkgsStatic;
            pkgsStatic = liftPackages pkgs.pkgsStatic;
          } // (liftPackages pkgs);
        devShell = devShells.pydemo;
        devShells = with pkgs; {
          pydemo = callPackage ./shell.nix { };
        };
      }
    );
}
