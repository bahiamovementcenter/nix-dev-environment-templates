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

# Converts a JSON schema into a Nickel contract. Not in Nixpkgs, so it's built
# from a pinned commit, as in the nickel template
let json-schema-to-nickel =
  organist.nix.derivation.CallNix
  & {
    function = m%"
      { pkgs }:
      pkgs.rustPlatform.buildRustPackage {
        pname = "json-schema-to-nickel";
        version = "0.1.0-unstable-2026-09-22";
        src = pkgs.fetchFromGitHub {
          owner = "nickel-lang";
          repo = "json-schema-to-nickel";
          rev = "4793648ac57eaee014f0308dc72034ac16e12be6";
          hash = "sha256-+UdeGOzeCzwmfUd2xuqFD2VaXTXCbjsqO2LExcA9YCU=";
        };
        cargoHash = pkgs.lib.fakeHash;
        doCheck = false;
        meta.mainProgram = "json-schema-to-nickel";
      }
    "%,
    args.pkgs = organist.import_nix "nixpkgs#pkgs",
  }
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
        }
        & { json-schema-to-nickel = json-schema-to-nickel },
    },
  },
}
  | organist.modules.T
