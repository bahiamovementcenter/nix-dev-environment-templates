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

# documentation
# https://nixos.org/manual/nixpkgs/stable/#sec-beam
#
# nixpkgs provides one package set per Erlang/OTP release (beam26Packages,
# beam27Packages, beam28Packages, ...); every package in a set (elixir,
# rebar3, hex, ...) is compiled with that OTP version. "beamPackages" follows
# the nixpkgs default.
let beam_packages = "beam28Packages" in

# use latest version of Elixir 1.19 ("elixir" follows the set's default)
let elixir_package = organist.import_nix "nixpkgs#%{beam_packages}.elixir_1_19" in

# the Erlang/OTP of the selected set, so `erl` matches the OTP Elixir uses
let erlang_package = organist.import_nix "nixpkgs#%{beam_packages}.erlang" in

# Platform checks need Nix, so this calls a bit of it: the package is used on
# matching platforms only, and replaced by an empty directory elsewhere.
let only_on = fun platform package_name =>
  organist.nix.derivation.CallNix
  & {
    function = m%"
      { pkgs, name }:
      if pkgs.stdenv.hostPlatform.is%{platform} then pkgs.${name} else pkgs.emptyDirectory
    "%,
    args = {
      pkgs = organist.import_nix "nixpkgs#pkgs",
      name = package_name,
    },
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
          # will also install OTP, mix, hex, rebar3
          elixir = elixir_package,

          # Erlang/OTP tools (erl, erlc, ...) from the same OTP version as Elixir
          erlang = erlang_package,

          # mix needs it for downloading dependencies
          git = organist.import_nix "nixpkgs#git",

          # probably needed for your Phoenix assets
          nodejs = organist.import_nix "nixpkgs#nodejs_latest",

          nixfmt = organist.import_nix "nixpkgs#nixfmt",

          # Linux only
          gigalixir = only_on "Linux" "gigalixir",
          inotify-tools = only_on "Linux" "inotify-tools",
          libnotify = only_on "Linux" "libnotify",

          # macOS only
          terminal-notifier = only_on "Darwin" "terminal-notifier",
        },
    },
  },
}
  | organist.modules.T
