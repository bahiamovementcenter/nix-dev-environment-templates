# Tf-Ncl (https://github.com/nickel-lang/tf-ncl): Nickel contracts for the
# Terraform providers a project uses, so a configuration written in Nickel is
# checked before Terraform sees it. Adapted from Tf-Ncl's own Nix code, which
# isn't used as a flake input because it brings its own Nixpkgs, Rust
# toolchain and build tooling.
#
# Returns the terraform to put in the shell (with the providers built in, so
# it matches the contracts) and the scripts that use the contracts.
{ pkgs, providers }:

let
  inherit (pkgs) lib;

  # Not in Nixpkgs. The files in pkgs/ are copies of the ones in the
  # dev-templates repository, which checks that they stay identical.
  tf-ncl = pkgs.callPackage ./pkgs/tf-ncl.nix { };
  schema-merge = pkgs.callPackage ./pkgs/schema-merge.nix { };

  selected = providers pkgs.terraform-providers.actualProviders;

  requiredProviders = lib.mapAttrs (
    _: provider: {
      inherit (provider) version;
      source = lib.toLower provider.provider-source-address;
    }
  );

  # With no providers selected, Terraform stays as it is in Nixpkgs, which
  # downloads providers on `terraform init`
  terraform =
    if selected == { } then pkgs.terraform else pkgs.terraform.withPlugins (_: lib.attrValues selected);

  # Asks Terraform for one provider's schema
  providerSchema =
    name: provider:
    pkgs.runCommand "${name}.json" { } ''
      cp ${
        (pkgs.formats.json { }).generate "main.tf.json" {
          terraform.required_providers = requiredProviders {
            ${builtins.replaceStrings [ "_" ] [ "-" ] name} = provider;
          };
        }
      } main.tf.json
      ${pkgs.terraform.withPlugins (_: [ provider ])}/bin/terraform init
      ${pkgs.terraform.withPlugins (_: [ provider ])}/bin/terraform providers schema -json > $out
    '';

  providersJson = (pkgs.formats.json { }).generate "providers.json" (requiredProviders selected);

  schema = pkgs.runCommand "tf-ncl-schema.ncl" { } ''
    mkdir schemas
    ${lib.concatLines (
      lib.mapAttrsToList (
        name: provider: ''ln -s ${providerSchema name provider} schemas/"${name}.json"''
      ) selected
    )}
    ln -s ${providersJson} providers.json
    ${lib.getExe schema-merge} . > schema.json
    ${lib.getExe tf-ncl} providers.json schema.json > $out
  '';
in
{
  inherit terraform;

  scripts = [
    # Links the contracts into the project as tf-ncl-schema.ncl, for main.ncl
    # to import
    (pkgs.writeShellScriptBin "link-schema" ''
      ln -sf ${schema} tf-ncl-schema.ncl
    '')

    # Evaluates main.ncl into main.tf.json, which Terraform reads
    (pkgs.writeShellScriptBin "run-nickel" ''
      set -e
      link-schema
      ${pkgs.nickel}/bin/nickel export --field renderable_config main.ncl > main.tf.json
    '')

    # Evaluates main.ncl, then runs Terraform with the given arguments
    (pkgs.writeShellScriptBin "run-terraform" ''
      set -e
      run-nickel
      ${terraform}/bin/terraform "$@"
    '')
  ];
}
