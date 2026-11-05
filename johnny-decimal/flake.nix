{
  description = "A Nix-flake-based Johnny Decimal development environment";

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
            };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        let
          # The official Johnny.Decimal command-line tool (jd). It isn't packaged
          # in Nixpkgs, so it's fetched at a pinned revision and wrapped so that
          # jq is always on its PATH.
          jd = pkgs.stdenvNoCC.mkDerivation {
            pname = "jd";
            version = "4.4.0";

            src = pkgs.fetchFromGitHub {
              owner = "johnnydecimal";
              repo = "cli.johnnydecimal.com";
              rev = "863d2e6412b70c385db8bdbcd6e1b3e28e6048f4";
              hash = "sha256-jM0nlEJACeE+5Ojluwpd4Hwkfyvn1Ppnzhqc85PFqtA=";
            };

            nativeBuildInputs = [ pkgs.makeWrapper ];

            dontBuild = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/johnnydecimal $out/bin
              cp -r . $out/share/johnnydecimal/cli

              makeWrapper $out/share/johnnydecimal/cli/bin/jd $out/bin/jd \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.jq ]}

              runHook postInstall
            '';

            meta = {
              description = "The Johnny.Decimal command-line tool";
              homepage = "https://github.com/johnnydecimal/cli.johnnydecimal.com";
              license = pkgs.lib.licenses.mit;
              mainProgram = "jd";
            };
          };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              jd # Johnny.Decimal CLI: find, create and move IDs
              pkgs.jdd # Johnny Decimal daemon: files new documents into the right folder by name
              self.formatter.${system}
            ];

            # jd reads its config from JD_CONFIG, and jdd from the JDD_* variables.
            # The config file isn't included: create it with `jd agent-setup` or
            # by copying the example (`jd paths` shows where the files live).
            env = {
              JDD_LOG_LEVEL = "info";
            };

            shellHook = ''
              export JD_CONFIG="''${JD_CONFIG:-$PWD/.jd/config.json}"
              export JDD_ROOT="''${JDD_ROOT:-$PWD}"
            '';
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
