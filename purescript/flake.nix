{
  description = "A Nix-flake-based Purescript development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs =
    { self, ... }@inputs:

    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
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
      overlays.default = final: prev: {
        # Nixpkgs' purescript 0.15.15 is a dynamically linked release binary
        # patched to use Nix's libraries, and it now segfaults while building.
        # From 0.15.16 the release binaries are statically linked, so they're
        # installed as they are. Drop this once Nixpkgs has 0.15.16
        # (https://github.com/NixOS/nixpkgs/pull/508691).
        purescript = prev.purescript.overrideAttrs (
          old:
          let
            version = "0.15.16";
            url = "https://github.com/purescript/purescript/releases/download/v${version}/";
            sources = {
              x86_64-linux = final.fetchurl {
                url = url + "linux64.tar.gz";
                sha256 = "08lfyddh914z7v2ph6im88g9hjvs6z60ldfmiyg5252fibxrxnj4";
              };
              aarch64-linux = final.fetchurl {
                url = url + "linux-arm64.tar.gz";
                sha256 = "1wr7m59v7nakyzgnq2rbm4a8x0dm8arlx0lhi9hwkn70qv2m7ldq";
              };
              aarch64-darwin = final.fetchurl {
                url = url + "macos-arm64.tar.gz";
                sha256 = "1i7w6a9j1k3v1c20g9jxd2v2jr7nsx54lp02zdhc5vr6w89mmwb3";
              };
            };
          in
          {
            inherit version;
            src = sources.${final.stdenv.hostPlatform.system};
            installPhase = ''
              install -D -m555 -T purs $out/bin/purs
            ''
            + final.lib.optionalString (final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform) ''
              mkdir -p $out/share/bash-completion/completions
              $out/bin/purs --bash-completion-script $out/bin/purs > $out/share/bash-completion/completions/purs-completion.bash
            '';
          }
        );
      };

      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages =
              with pkgs;
              [
                nodejs_latest
                purescript
                spago
                self.formatter.${system}
              ]
              ++ (with nodePackages_latest; [
              ]);
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
