{
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

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
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default =
            let
              getSystem = "SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')";
              # Runs `exec` in each directory given as an argument (`check rust go`),
              # or in every directory with a flake.nix when there are none
              forEachDir = exec: ''
                dirs=("$@")
                if [ "''${#dirs[@]}" -eq 0 ]; then
                  for dir in */; do
                    if [ -f "''${dir}flake.nix" ]; then
                      dirs+=("''${dir%/}")
                    fi
                  done
                fi

                for dir in "''${dirs[@]}"; do
                  (
                    cd "''${dir}"

                    ${exec}
                  )
                done
              '';

              script =
                name: runtimeInputs: text:
                pkgs.writeShellApplication {
                  inherit name runtimeInputs text;
                  bashOptions = [
                    "errexit"
                    "pipefail"
                  ];
                };
            in
            pkgs.mkShellNoCC {
              packages = with pkgs; [
                (script "build" [ ] ''
                  ${getSystem}

                  ${forEachDir ''
                    echo "building ''${dir}"
                    nix build ".#devShells.''${SYSTEM}.default"
                  ''}
                '')
                (script "check" [ nixfmt ] (forEachDir ''
                  echo "checking ''${dir}"
                  nix flake check --all-systems --no-build
                  nix develop --command which nixfmt
                ''))
                (script "format" [ nixfmt ] ''
                  git ls-files '*.nix' | xargs nix fmt
                '')
                (script "check-formatting" [ nixfmt ] ''
                  git ls-files '*.nix' | xargs nixfmt --check
                '')
                # Validates agent conventions: skills against the Agent Skills spec,
                # Claude Code subagents (name, description, preloaded skills),
                # .claude/settings.json against its schema, and the .claude/skills
                # symlink. Checks this repo and the agents template, or the
                # directories given.
                (script "check-agents"
                  [
                    self.packages.${system}.skills-ref
                    check-jsonschema
                    (python3.withPackages (ps: [ ps.pyyaml ]))
                  ]
                  ''
                    root="$(git rev-parse --show-toplevel)"
                    dirs=("$@")
                    if [ "''${#dirs[@]}" -eq 0 ]; then
                      dirs=("$root" "$root/agents")
                    fi
                    status=0
                    for dir in "''${dirs[@]}"; do
                      echo "checking $dir"
                      for skill in "$dir"/.agents/skills/*/; do
                        [ -f "$skill/SKILL.md" ] || continue
                        agentskills validate "$skill" || status=1
                      done
                      if [ -d "$dir/.claude/agents" ]; then
                        python3 ${./scripts/check_subagents.py} "$dir" || status=1
                      fi
                      if [ -f "$dir/.claude/settings.json" ]; then
                        check-jsonschema --schemafile https://json.schemastore.org/claude-code-settings.json \
                          "$dir/.claude/settings.json" || status=1
                      fi
                      if [ -e "$dir/.agents/skills" ] && [ "$(readlink "$dir/.claude/skills")" != "../.agents/skills" ]; then
                        echo "$dir/.claude/skills should be a symlink to ../.agents/skills" >&2
                        status=1
                      fi
                    done
                    exit "$status"
                  ''
                )
                # Compares each Organist template with the template it was ported
                # from; see organist/parity.py
                # Checks that every template's copy of a package in pkgs/ is
                # identical to the original, and that every package a template
                # keeps in its own pkgs/ folder is in the root pkgs/ too
                (script "check-vendored" [ diffutils ] ''
                  cd "$(git rev-parse --show-toplevel)"
                  status=0
                  while IFS= read -r copy; do
                    original="pkgs/$(basename "$copy")"
                    if [ ! -f "$original" ]; then
                      echo "$copy: no $original; add it there and copy it here" >&2
                      status=1
                    elif ! cmp -s "$original" "$copy"; then
                      echo "$copy differs from $original:" >&2
                      diff -u "$original" "$copy" >&2 || true
                      status=1
                    fi
                  done < <(git ls-files '*/pkgs/*.nix')
                  exit "$status"
                '')
                (script "check-organist" [ python3 ] ''
                  python3 "$(git rev-parse --show-toplevel)/organist/parity.py" "$@"
                '')

                self.formatter.${system}
              ];
            };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);

      # Packages the templates use that Nixpkgs doesn't have, one file each in
      # pkgs/. Templates keep identical copies in their own pkgs/ folder, so
      # they stay self-contained; check-vendored keeps the copies in step.
      overlays.default =
        final: prev:
        lib.packagesFromDirectoryRecursive {
          inherit (final) callPackage;
          directory = ./pkgs;
        };

      packages = forEachSupportedSystem (
        { pkgs, system }:
        lib.packagesFromDirectoryRecursive {
          inherit (pkgs) callPackage;
          directory = ./pkgs;
        }
        // {
          default = self.packages.${system}.dvt;

          dvt = pkgs.writeShellApplication {
            name = "dvt";
            bashOptions = [
              "errexit"
              "pipefail"
            ];
            text = ''
              if [ -z "''${1}" ]; then
                echo "no template specified"
                exit 1
              fi

              TEMPLATE=$1

              nix \
                --experimental-features 'nix-command flakes' \
                flake init \
                --template \
                "https://flakehub.com/f/the-nix-way/dev-templates/0.1#''${TEMPLATE}"
            '';
          };
        }
      );
    }

    //

      {
        templates = {
          default = self.templates.empty;

          agents = {
            path = ./agents;
            description = "AGENTS.md, Agent Skills and Claude Code settings; no flake.nix, so it layers onto any project";
          };

          bun = {
            path = ./bun;
            description = "Bun development environment";
          };

          c-cpp = {
            path = ./c-cpp;
            description = "C/C++ development environment";
          };

          clojure = {
            path = ./clojure;
            description = "Clojure development environment";
          };

          csharp = {
            path = ./csharp;
            description = "C# development environment";
          };

          cue = {
            path = ./cue;
            description = "Cue development environment";
          };

          dhall = {
            path = ./dhall;
            description = "Dhall development environment";
          };

          elixir = {
            path = ./elixir;
            description = "Elixir development environment";
          };

          elm = {
            path = ./elm;
            description = "Elm development environment";
          };

          empty = {
            path = ./empty;
            description = "Empty dev template that you can customize at will";
          };

          gleam = {
            path = ./gleam;
            description = "Gleam development environment";
          };

          go = {
            path = ./go;
            description = "Go (Golang) development environment";
          };

          gstack = {
            path = ./gstack;
            description = "Claude Code with gstack, installed per project";
          };

          hashi = {
            path = ./hashi;
            description = "HashiCorp DevOps tools development environment";
          };

          haskell = {
            path = ./haskell;
            description = "Haskell development environment";
          };

          java = {
            path = ./java;
            description = "Java development environment";
          };

          johnny-decimal = {
            path = ./johnny-decimal;
            description = "Johnny Decimal development environment";
          };

          jupyter = {
            path = ./jupyter;
            description = "Jupyter development environment";
          };

          kotlin = {
            path = ./kotlin;
            description = "Kotlin development environment";
          };

          latex = {
            path = ./latex;
            description = "LaTeX development environment";
          };

          lean4 = {
            path = ./lean4;
            description = "Lean 4 development environment";
          };

          nickel = {
            path = ./nickel;
            description = "Nickel development environment";
          };

          nim = {
            path = ./nim;
            description = "Nim development environment";
          };

          nix = {
            path = ./nix;
            description = "Nix development environment";
          };

          nixtrobox = {
            path = ./nixtrobox;
            description = "Distrobox containers of other Linux distributions, pinned with Nix";
          };

          node = {
            path = ./node;
            description = "Node.js development environment";
          };

          ocaml = {
            path = ./ocaml;
            description = "OCaml development environment";
          };

          odin = {
            path = ./odin;
            description = "Odin development environment";
          };

          opa = {
            path = ./opa;
            description = "Open Policy Agent development environment";
          };

          organist = {
            path = ./organist/compose;
            description = "Organist development environment combining this repository's modules (Python and Nickel to start)";
          };

          organist-elixir = {
            path = ./organist/elixir;
            description = "Elixir development environment, defined with Organist";
          };

          organist-java = {
            path = ./organist/java;
            description = "Java development environment, defined with Organist";
          };

          organist-nickel = {
            path = ./organist/nickel;
            description = "Nickel development environment, defined with Organist";
          };

          organist-python = {
            path = ./organist/python;
            description = "Python development environment, defined with Organist";
          };

          php = {
            path = ./php;
            description = "PHP development environment";
          };

          platformio = {
            path = ./platformio;
            description = "PlatformIO development environment";
          };

          presenterm = {
            path = ./presenterm;
            description = "Presenterm development environment";
          };

          powershell = {
            path = ./powershell;
            description = "PowerShell development environment";
          };

          protobuf = {
            path = ./protobuf;
            description = "Protobuf development environment";
          };

          pulumi = {
            path = ./pulumi;
            description = "Pulumi development environment";
          };

          purescript = {
            path = ./purescript;
            description = "Purescript development environment";
          };

          python = {
            path = ./python;
            description = "Python development environment";
          };

          r = {
            path = ./r;
            description = "R development environment";
          };

          ruby = {
            path = ./ruby;
            description = "Ruby development environment";
          };

          rust = {
            path = ./rust;
            description = "Rust development environment";
          };

          scala = {
            path = ./scala;
            description = "Scala development environment";
          };

          shell = {
            path = ./shell;
            description = "Shell script development environment";
          };

          swi-prolog = {
            path = ./swi-prolog;
            description = "Swi-prolog development environment";
          };

          swift = {
            path = ./swift;
            description = "Swift development environment";
          };

          typst = {
            path = ./typst;
            description = "Typst development environment";
          };

          vlang = {
            path = ./vlang;
            description = "Vlang developent environment";
          };

          zig = {
            path = ./zig;
            description = "Zig development environment";
          };

          # Aliases
          c = self.templates.c-cpp;
          cpp = self.templates.c-cpp;
        };
      };
}
