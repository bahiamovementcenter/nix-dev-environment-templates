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
    # Change the version to update the whole stack
    & modules.java { version = 25 },
    # Merge in more above: packages of your own, or other languages from
    # their modules (see organist/modules in the dev-templates repository)
    #   & { shells.dev.packages.jdt-language-server = organist.import_nix "nixpkgs#jdt-language-server" }
    #   & modules.nickel {}
}
  | organist.modules.T
