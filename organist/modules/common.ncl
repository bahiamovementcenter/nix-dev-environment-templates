fun organist =>
  # `mkShell` adds each package's `dev` output (headers, pkg-config files) to
  # the shell, while Organist adds the default output. This restores the
  # former.
  let add_dev_outputs =
    std.record.map (fun _name drv =>
      organist.nix.derivation.CallNix
      & {
        function = "{ package }: package.dev or package",
        args.package = drv,
      }
    )
  in
  {
    with_dev_outputs = add_dev_outputs,

    base = {
      shells = organist.shells.Bash,

      shells.build.packages = {},

      shells.dev = {
        # No C compiler in the shell, like `mkShellNoCC`
        env.stdenv = organist.import_nix "nixpkgs#stdenvNoCC",

        packages = add_dev_outputs {
          nixfmt = organist.import_nix "nixpkgs#nixfmt",
        },
      },
    },
  }
