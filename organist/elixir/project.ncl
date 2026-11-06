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
    # Options: beam_packages (default "beam28Packages"), elixir (default "elixir_1_19")
    & modules.elixir {},
    # Merge in more above: packages of your own, or other languages from
    # their modules (see organist/modules in the dev-templates repository)
    #   & { shells.dev.packages.elixir-ls = organist.import_nix "nixpkgs#elixir-ls" }
    #   & modules.nickel {}
}
  | organist.modules.T
