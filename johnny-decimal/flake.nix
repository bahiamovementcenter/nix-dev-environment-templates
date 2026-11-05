{
  description = "A Nix-flake-based Johnny Decimal development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  # Optional: zsh helpers (jcd, jcp, jmv, jmkarea, jmkcat, jmkuni, jwd).
  # Uncomment this input and the matching lines in the shellHook below.
  # inputs.zsh-johnnydecimal.url = "github:CRTified/zsh-johnnydecimal";

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
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              jdd # Johnny Decimal daemon: files new documents into the right folder by name
              self.formatter.${system}
            ];

            # jdd can be configured through environment variables or a .jd.yaml
            # file; JDD_ROOT is the directory the daemon watches.
            env = {
              JDD_LOG_LEVEL = "info";
            };

            shellHook = ''
              export JDD_ROOT="''${JDD_ROOT:-$PWD}"

              # Optional zsh helpers (requires the zsh-johnnydecimal input above):
              # export JOHNNYDECIMAL_BASE="$JDD_ROOT"
              # exec ${pkgs.zsh}/bin/zsh -c "source ${inputs.zsh-johnnydecimal}/johnnydecimal.zsh; exec zsh -i"
            '';
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
