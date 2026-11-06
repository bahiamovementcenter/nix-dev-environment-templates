# Elixir and the Erlang/OTP it's built with, plus Git, Node.js and the
# file-watching tools Phoenix uses, as in the elixir template
#
# documentation
# https://nixos.org/manual/nixpkgs/stable/#sec-beam
fun organist common =>
  fun options =>
    let options
      | {
        # Nixpkgs provides one package set per Erlang/OTP release
        # (beam26Packages, beam27Packages, beam28Packages, ...); every package
        # in a set (elixir, rebar3, hex, ...) is compiled with that OTP
        # version. "beamPackages" follows the Nixpkgs default.
        beam_packages | String | default = "beam28Packages",
        # The Elixir in that set ("elixir" follows the set's default)
        elixir | String | default = "elixir_1_19",
      }
      = options
    in
    let elixir_package = organist.import_nix "nixpkgs#%{options.beam_packages}.%{options.elixir}" in

    # the Erlang/OTP of the selected set, so `erl` matches the OTP Elixir uses
    let erlang_package = organist.import_nix "nixpkgs#%{options.beam_packages}.erlang" in

    # Platform checks need Nix, so this calls a bit of it: the package is used
    # on matching platforms only, and replaced by an empty directory elsewhere.
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
    {
      shells.dev.packages = common.with_dev_outputs {
        # will also install OTP, mix, hex, rebar3
        elixir = elixir_package,

        # Erlang/OTP tools (erl, erlc, ...) from the same OTP version as Elixir
        erlang = erlang_package,

        # mix needs it for downloading dependencies
        git = organist.import_nix "nixpkgs#git",

        # probably needed for your Phoenix assets
        nodejs = organist.import_nix "nixpkgs#nodejs_latest",

        # Linux only
        gigalixir = only_on "Linux" "gigalixir",
        inotify-tools = only_on "Linux" "inotify-tools",
        libnotify = only_on "Linux" "libnotify",

        # macOS only
        terminal-notifier = only_on "Darwin" "terminal-notifier",
      },
    }
