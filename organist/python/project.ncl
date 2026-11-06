let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in
# This repository's Organist modules (organist/modules), from the
# dev-templates flake input (see flake.nix)
let modules = inputs.dev-templates organist in

organist.OrganistExpression
& {
  Schema,
  config | Schema =
    modules.base
    # Change the version to switch Python, then delete .venv and reload
    & modules.python { version = "3.13" },
    # Merge in more above: packages of your own, or other languages from
    # their modules (see organist/modules in the dev-templates repository)
    #   & { shells.dev.packages.ruff = organist.import_nix "nixpkgs#ruff" }
    #   & modules.nickel {}
}
  | organist.modules.T
