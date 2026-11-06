{
  description = "A Nix-flake-based development environment for Terraform, Packer, and Nomad";

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
              config.allowUnfree = true;
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        let
          # Terraform in Nickel: link-schema, run-nickel and run-terraform
          # (see tf-ncl.nix)
          tf-ncl = import ./tf-ncl.nix {
            inherit pkgs;
            # The Terraform providers to write Nickel contracts for, from
            # Nixpkgs' terraform-providers; they're also built into terraform.
            # With none, the contracts cover Terraform's own settings only.
            providers = p: {
              # inherit (p) hashicorp_aws hashicorp_random;
            };
          };
        in
        {
          default = pkgs.mkShellNoCC {
            packages =
              with pkgs;
              [
                packer
                tf-ncl.terraform
                tflint
                nomad
                vault
                nomad-autoscaler
                nomad-pack
                levant
                damon
                terragrunt
                nickel
                nls # Nickel language server
                self.formatter.${system}
              ]
              ++ tf-ncl.scripts;
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
