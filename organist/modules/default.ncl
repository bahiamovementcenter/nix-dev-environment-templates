# Organist modules for this repository's templates. Each adds what its
# template's shell has, so a project can combine languages by merging them:
#
#   config | Schema = modules.base & modules.python {} & modules.nickel {},
#
# Every module but `base` takes a record of options, all optional (`{}` for
# the defaults). A project gets these modules through a flake input named
# `dev-templates`, listed in Organist's lockFileContents; see the organist
# template's flake.nix.
fun organist =>
  let common = (import "./common.ncl") organist in
  {
    # A Bash shell without a C compiler, like `mkShellNoCC`, with nixfmt
    base = common.base,

    elixir = (import "./elixir.ncl") organist common,
    java = (import "./java.ncl") organist common,
    nickel = (import "./nickel.ncl") organist common,
    python = (import "./python.ncl") organist common,
  }
