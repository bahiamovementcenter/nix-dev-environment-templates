{
  description = "A Nix-flake-based Nickel development environment";

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
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        let
          # Converts a JSON schema into a Nickel contract. Not in Nixpkgs or on
          # crates.io, and not tagged, so it's built from a pinned commit
          json-schema-to-nickel = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
            pname = "json-schema-to-nickel";
            version = "0.1.0-unstable-2026-09-22";

            src = pkgs.fetchFromGitHub {
              owner = "nickel-lang";
              repo = "json-schema-to-nickel";
              rev = "4793648ac57eaee014f0308dc72034ac16e12be6";
              hash = "sha256-+UdeGOzeCzwmfUd2xuqFD2VaXTXCbjsqO2LExcA9YCU=";
            };

            cargoHash = pkgs.lib.fakeHash;

            # Upstream's CI runs the tests (against the whole JSON Schema test
            # suite); the shell only needs the binary
            doCheck = false;

            meta = {
              description = "Convert JSON schemas into Nickel contracts";
              homepage = "https://github.com/nickel-lang/json-schema-to-nickel";
              license = with pkgs.lib.licenses; [
                mit
                asl20
              ];
              mainProgram = "json-schema-to-nickel";
            };
          });
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              nickel # also formats Nickel: nickel format
              nls # Nickel language server
              json-schema-to-nickel
              self.formatter.${system}
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
