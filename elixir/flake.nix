{
  description = "A Nix-flake-based Elixir development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { self, ... }@inputs:

    let
      inherit (inputs.nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default =
        final: prev:
        let
          # documentation
          # https://nixos.org/manual/nixpkgs/stable/#sec-beam

          # ==== BEAM packages ====

          # nixpkgs provides one package set per Erlang/OTP release
          # (beam26Packages, beam27Packages, beam28Packages, ...); every package
          # in a set (elixir, rebar3, hex, ...) is compiled with that OTP version.

          # use whatever OTP version is currently the default in nixpkgs
          # beamPkgs = final.beamPackages;

          # use latest version of Erlang/OTP 28
          beamPkgs = final.beam28Packages;

          # specify exact version of Erlang/OTP: override the erlang member of a
          # set with overrideScope, so the rest of the set is rebuilt against it
          # beamPkgs = final.beam28Packages.overrideScope (
          #   beamFinal: beamPrev: {
          #     erlang = beamPrev.erlang.override {
          #       version = "28.0.2";
          #       sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          #     };
          #   }
          # );
        in
        {
          # ==== Elixir ====

          # use whatever Elixir version is currently the default in the set
          # elixir = beamPkgs.elixir;

          # use latest version of Elixir 1.19
          elixir = beamPkgs.elixir_1_19;

          # specify exact version of Elixir
          # elixir = beamPkgs.elixir.override {
          #   version = "1.19.0";
          #   sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          # };
        };

      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages =
              with pkgs;
              [
                # use the Elixr/OTP versions defined above; will also install OTP, mix, hex, rebar3
                elixir

                # mix needs it for downloading dependencies
                git

                # probably needed for your Phoenix assets
                nodejs_latest

                self.formatter.${system}
              ]
              ++
                # Linux only
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (
                  with pkgs;
                  [
                    gigalixir
                    inotify-tools
                    libnotify
                  ]
                )
              ++
                # macOS only
                pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
                  with pkgs;
                  [
                    terminal-notifier
                  ]
                );
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
