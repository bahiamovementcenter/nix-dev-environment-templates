{
  description = "A Nix-flake-based Johnny Decimal development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        let
          # Not in Nixpkgs. The files in pkgs/ are copies of the ones in the
          # dev-templates repository, which checks that they stay identical.
          jd = pkgs.callPackage ./pkgs/jd.nix { };
          wattlebird = pkgs.callPackage ./pkgs/wattlebird-generator.nix { };
          jdexmd = pkgs.callPackage ./pkgs/jdexmd.nix { };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              jd # Johnny.Decimal CLI: find, create and move IDs
              pkgs.jdd # Johnny Decimal daemon: files new documents into the right folder by name
              wattlebird # wattlebird-generate and wattlebird-score: a test mess for filing agents
              jdexmd # Johnny.Decimal system and JDex from an outline
              self.formatter.${system}
            ];

            # jd reads its config from JD_CONFIG, and jdd from the JDD_* variables.
            # The config file isn't included: create it with `jd agent-setup` or
            # by copying the example (`jd paths` shows where the files live).
            env = {
              JDD_LOG_LEVEL = "info";
            };

            shellHook = ''
              export JD_CONFIG="''${JD_CONFIG:-$PWD/.jd/config.json}"
              export JDD_ROOT="''${JDD_ROOT:-$PWD}"
            '';
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
