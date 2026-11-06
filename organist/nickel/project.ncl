let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

# `mkShell` adds each package's `dev` output (headers, pkg-config files) to the
# shell, while Organist adds the default output. This restores the former.
let with_dev_outputs =
  std.record.map (fun _name drv =>
    organist.nix.derivation.CallNix
    & {
      function = "{ package }: package.dev or package",
      args.package = drv,
    }
  )
in

organist.OrganistExpression
& {
  Schema,
  config | Schema = {
    shells = organist.shells.Bash,

    shells.build.packages = {},

    shells.dev = {
      # No C compiler in the shell, like `mkShellNoCC`
      env.stdenv = organist.import_nix "nixpkgs#stdenvNoCC",

      packages =
        with_dev_outputs {
          nickel = organist.import_nix "nixpkgs#nickel",
          nixfmt = organist.import_nix "nixpkgs#nixfmt",
        },
    },
  },
}
  | organist.modules.T
