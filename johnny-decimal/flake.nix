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

          # The Wattlebird generator writes a fictional small shop's flat, messy
          # folder for an agent to file into a Johnny.Decimal system, and scores
          # the result, from jd's move journal or a folder listing.
          # generate.py writes its answer key beside itself, which a Nix store
          # path can't hold, so the launcher points it at a state folder
          # instead (WATTLEBIRD_KEY_DIR, by default
          # ~/.local/state/wattlebird-generator), outside any project, where
          # the agent under test won't find it.
          wattlebird = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
            pname = "wattlebird-generator";
            version = "1.2.0";

            src = pkgs.fetchFromGitHub {
              owner = "johnnydecimal";
              repo = "wattlebird-generator";
              tag = "v${finalAttrs.version}";
              hash = "sha256-WNdwEyV21Kixv4VqGHZgOolja1+DOFoFR1pzpAtG6i4=";
            };

            nativeBuildInputs = [ pkgs.python3 ];

            dontBuild = true;

            doCheck = true;
            checkPhase = ''
              runHook preCheck
              python3 -m unittest
              runHook postCheck
            '';

            installPhase =
              let
                share = "${placeholder "out"}/share/wattlebird-generator";
              in
              ''
                runHook preInstall

                mkdir -p ${share} $out/bin
                cp -r generate.py score.py answer-key.csv README.md ${share}/

                cat >$out/bin/wattlebird-generate <<'EOF'
                #!${pkgs.runtimeShell}
                # Usage: wattlebird-generate OUT_DIR [--seed N]
                key_dir="''${WATTLEBIRD_KEY_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/wattlebird-generator}"
                mkdir -p "$key_dir"
                exec ${pkgs.python3}/bin/python3 -c '
                import sys
                from pathlib import Path
                sys.path.insert(0, sys.argv.pop(1))
                key_dir = Path(sys.argv.pop(1)).resolve()
                import generate
                generate.TOOL_DIR = key_dir
                generate.main()
                ' ${share} "$key_dir" "$@"
                EOF

                cat >$out/bin/wattlebird-score <<'EOF'
                #!${pkgs.runtimeShell}
                # Usage: wattlebird-score KEY MAP --journal JOURNAL --root MESS_ROOT
                #        wattlebird-score KEY MAP --listing FOLDER_OR_LS_R_FILE
                exec ${pkgs.python3}/bin/python3 ${share}/score.py "$@"
                EOF

                chmod +x $out/bin/*

                runHook postInstall
              '';

            meta = {
              description = "Generates a messy fictional business to test Johnny.Decimal filing, and scores the result";
              homepage = "https://github.com/johnnydecimal/wattlebird-generator";
              license = pkgs.lib.licenses.mit;
              mainProgram = "wattlebird-generate";
            };
          });

          # jdexmd builds a Johnny.Decimal system from an outline in a TOML file:
          # the folders and notes of a Markdown notes vault (Obsidian, Logseq),
          # a parallel folder tree for other files, and a JDex note listing the
          # whole system. It only creates what's missing, except the JDex note,
          # which it rewrites on every run. Not in Nixpkgs.
          jdexmd = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
            pname = "jdexmd";
            version = "0.1.3";

            src = pkgs.fetchCrate {
              inherit (finalAttrs) pname version;
              hash = "sha256-ZH0LdOQv7YvzIFEWSyHWH4D9UB/5Opj8dSHPRWJkqrg=";
            };

            cargoHash = "sha256-4+cBr4bB9sn3ZPUxW3vV3jnuqZMZgoMNz5ZfA8S4NBI=";

            meta = {
              description = "Generates a Johnny.Decimal system and its JDex for Obsidian and a documents folder";
              homepage = "https://github.com/graysonarts/jdexmd";
              license = pkgs.lib.licenses.mit;
              mainProgram = "jdexmd";
            };
          });
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              jd # Johnny.Decimal CLI: find, create and move IDs
              pkgs.jdd # Johnny Decimal daemon: files new documents into the right folder by name
              wattlebird # wattlebird-generate and wattlebird-score: a test mess for filing agents
              jdexmd # Johnny.Decimal system and JDex from an outline
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
