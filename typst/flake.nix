{
  description = "A Nix-flake-based Typst development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
    # Builds Typst documents in Nix, with fonts and other files pinned
    typix = {
      url = "https://flakehub.com/f/loqusion/typix/0.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

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
            typix = inputs.typix.lib.${system};
          }
        );

      # Shared by the build, `nix run .#watch` and the dev shell, so they all
      # see the same fonts and files
      typstArgs = pkgs: {
        typstSource = "main.typ";

        fontPaths = [
          # Add paths to fonts here
          # "${pkgs.roboto}/share/fonts/truetype"
        ];

        virtualPaths = [
          # Add files or directories Typst must find in the project here
          # {
          #   dest = "icons";
          #   src = "${pkgs.font-awesome}/share/fonts";
          # }
        ];
      };
    in
    {
      # `nix build` compiles main.typ into result
      packages = forEachSupportedSystem (
        { pkgs, typix, ... }:
        {
          default = typix.buildTypstProject (typstArgs pkgs // { src = typix.cleanTypstSource ./.; });
        }
      );

      apps = forEachSupportedSystem (
        { pkgs, typix, ... }:
        {
          # `nix run .#build` compiles main.typ into main.pdf. (Typix's own
          # buildTypstProjectLocal compiles while the flake is evaluated, which
          # `nix flake check` and a project without main.typ yet can't do.)
          build = {
            type = "app";
            program = pkgs.lib.getExe (
              pkgs.writeShellApplication {
                name = "typst-build";
                runtimeInputs = [ pkgs.coreutils ];
                text = ''
                  out="''${1:-main.pdf}"
                  mkdir -p "$(dirname "$out")"
                  result="$(nix build --no-link --print-out-paths .#default)"
                  cp -LT --no-preserve=mode "$result" "$out"
                '';
              }
            );
          };
          # `nix run .#watch` recompiles main.pdf whenever its sources change
          watch = {
            type = "app";
            program = pkgs.lib.getExe (typix.watchTypstProject (typstArgs pkgs));
          };
          default = self.apps.${pkgs.stdenv.hostPlatform.system}.watch;
        }
      );

      devShells = forEachSupportedSystem (
        {
          pkgs,
          typix,
          system,
        }:
        {
          # Typix's dev shell adds typst, and makes the fonts and virtual
          # paths above available to it
          default = typix.devShell {
            inherit (typstArgs pkgs) fontPaths virtualPaths;
            packages =
              with pkgs;
              [
                typstyle
                tinymist
                self.formatter.${system}
              ]
              ++ (with typstPackages; [
                # Typst packages
              ]);
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
