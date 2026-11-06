# Nickel, its language server (nls, which every Organist shell has) and
# json-schema-to-nickel, as in the nickel template
fun organist common =>
  fun options =>
    let _options | {} = options in
    {
      shells.dev.packages =
        common.with_dev_outputs {
          nickel = organist.import_nix "nixpkgs#nickel",
        }
        & {
          # Not in Nixpkgs: built by the dev-templates flake (pkgs/)
          json-schema-to-nickel = organist.import_nix "dev-templates#json-schema-to-nickel",
        },
    }
