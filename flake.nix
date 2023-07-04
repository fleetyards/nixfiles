{
  description = "Fleetyards related nix config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    nix.url = "github:NixOS/nix";
    colmena.url = "github:zhaofengli/colmena";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "/nixpkgs";
    };
    kleonk = {
      url = "github:kloenk/nixfiles";
      inputs.nixpkgs.follows = "/nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "/nixpkgs";
    };
  };

  outputs =
    inputs@{ self, nixpkgs, nix, colmena, devenv, kloenk, sops-nix, ... }:
    let
      overlayCombinded = system: [
        (final: prev: { nix = nix.packages.${system}.nix; })
        colmena.overlay
      ];

      systems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aaarch64-darwin" ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # Memoize nixpkgs for different platforms
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = (overlayCombinded system);
        });
    in {
      legacyPackages = nixpkgsFor;

      nixosConfigurations =
        let hive = inputs.colmena.lib.makeHive self.outputs.colmena;
        in hive.nodes;

      colmena = {
        meta = {
          nixpkgs = import nixpkgs {
            system = "aarch64-linux";
            overlays = (overlayCombinded "aarch64-linux");
          };
          #nodeNixpkgs.social.nixpkgs = import nixpkgs {
          #  system = "aarch64-linux";
          #  overlays = (overlayCombinded "aaarch64-linux");
          #};

          specialArgs.inputs = inputs;
        };

        defaults = { pkgs, ... }: {
          imports = [
            ./configuration/common
            (kloenk + "/configuration/common/common.nix")
            (kloenk + "/configuration/common/nginx")
            (kloenk + "/configuration/common/kloenk.nix")
            ./configuration/common/mortik.nix

            sops-nix.nixosModules.sops
            kloenk.nixosModules.nftables
          ];

          deployment = {
            buildOnTarget = true;
            allowLocalDeployment = true;
          };
        };

        social = { pkgs, nodes, ... }: {
          deployment = {
            targetHost = "starcitizen.social";
            tags = [ "hetzner" "remote" ];
          };
          imports = [ ./configuration/hosts/social ];
        };
      };

      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          devenv = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              ({ pkgs, ... }: { packages = [ pkgs.colmena ]; })
              {
                languages.nix.enable = true;

                pre-commit.hooks.actionlint.enable = true;
                pre-commit.hooks.nixfmt.enable = true;
              }
            ];
          };
          default = self.devShells.${system}.devenv;
        });

      formatter = forAllSystems (system: self.legacyPackages.${system}.nixfmt);

      checks = forAllSystems
        (system: { devenv = self.devShells.${system}.devenv.ci; });
    };
}
