let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in
# This repository's Organist modules (organist/modules), from the
# dev-templates flake input (see flake.nix)
let modules = inputs.dev-templates organist in

organist.OrganistExpression
& {
  Schema,
  config | Schema =
    # A Bash shell without a C compiler, with nixfmt
    modules.base
    # One module per language: merge in the ones this project uses. Each
    # takes a record of options, all of them optional.
    & modules.python { version = "3.13" }
    & modules.nickel {}
    # & modules.java { version = 25 }
    # & modules.elixir { beam_packages = "beam28Packages", elixir = "elixir_1_19" }

    # Packages of your own
    & {
      shells.dev.packages = {
        # ruff = organist.import_nix "nixpkgs#ruff",
      },
    },
}
  | organist.modules.T
