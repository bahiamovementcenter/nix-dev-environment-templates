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
          # Converts a JSON schema into a Nickel contract. Not in Nixpkgs; the
          # file in pkgs/ is a copy of the one in the dev-templates repository,
          # which checks that they stay identical.
          json-schema-to-nickel = pkgs.callPackage ./pkgs/json-schema-to-nickel.nix { };
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
