{
  description = "A Nix-flake-based environment for Claude Code with gstack";

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
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );

      # gstack drives a Chromium through Playwright. On Linux it uses the
      # browsers Nixpkgs builds for its Playwright (the version gstack pins),
      # which also run on NixOS; on macOS gstack uses Aside or downloads its own.
      browserEnv =
        pkgs:
        lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
          PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
        };
    in
    {
      packages = forEachSupportedSystem (
        { pkgs, system }:
        {
          # The latest Claude Code release from npm, on every run. (The npm
          # package ships a native binary, which needs nix-ld on NixOS.)
          claude = pkgs.writeShellApplication {
            name = "claude";
            runtimeInputs = [ pkgs.nodejs_latest ];
            text = ''
              export npm_config_update_notifier=false
              exec npx --yes @anthropic-ai/claude-code@latest "$@"
            '';
          };

          # Installs gstack into the project's .claude/skills, with its hooks
          # in .claude/settings.local.json and its state in .gstack: everything
          # gstack writes stays in the project and out of git. gstack treats
          # ${CLAUDE_CONFIG_DIR}/skills/gstack as its standard install, so setup
          # runs with CLAUDE_CONFIG_DIR pointing at the project's .claude.
          gstack-bootstrap = pkgs.writeShellApplication {
            name = "gstack-bootstrap";
            runtimeInputs = with pkgs; [
              bun
              coreutils
              git
              jq
              nodejs_latest
            ];
            runtimeEnv = browserEnv pkgs;
            text = ''
              project="''${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
              claude_dir="$project/.claude"
              install="$claude_dir/skills/gstack"
              settings="$claude_dir/settings.local.json"
              state="$project/.gstack"

              # gstack puts each of its skills in .claude/skills, which
              # .gitignore covers. When .claude/skills links elsewhere, as the
              # agents template's link to .agents/skills does, the skills next
              # to gstack's are committed, so gstack's own are excluded in this
              # clone's .git/info/exclude instead, one by one.
              exclude_gstack_skills() {
                local skills root exclude gstack entry rel
                skills="$(cd "$claude_dir/skills" 2>/dev/null && pwd -P)" || return 0
                root="$(cd "$project" && pwd -P)"
                [ "$skills" != "$root/.claude/skills" ] || return 0
                exclude="$(git -C "$root" rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null)" || return 0
                gstack="$(cd "$install" 2>/dev/null && pwd -P)" || return 0
                mkdir -p "$(dirname "$exclude")"
                touch "$exclude"
                for entry in "$skills"/*; do
                  if [ "$entry" = "$gstack" ] || [ -f "$entry/.gstack-owned" ] ||
                    [[ "$(readlink -f "$entry")" == "$gstack"/* ]] ||
                    [[ "$(readlink -f "$entry/SKILL.md" 2>/dev/null)" == "$gstack"/* ]]; then
                    rel="/$(realpath -s --relative-to="$root" "$entry")"
                    grep -qxF "$rel" "$exclude" || echo "$rel" >>"$exclude"
                  fi
                done
              }

              if [ -f "$state/bootstrap-done" ] && [ -d "$install" ]; then
                # gstack updates itself, and may add skills
                exclude_gstack_skills
                exit 0
              fi

              mkdir -p "$claude_dir/skills" "$state"
              log="$state/bootstrap.log"
              echo "gstack: installing into .claude/skills (about a minute; log: .gstack/bootstrap.log)" >&2

              if [ ! -d "$install/.git" ]; then
                git clone --quiet --single-branch --depth 1 \
                  https://github.com/garrytan/gstack.git "$install" >"$log" 2>&1
              fi

              # setup runs Claude Code to look for gstack's optional MCP server;
              # with CLAUDE_CONFIG_DIR set, Claude Code would make the project's
              # .claude its home and write account state there. This shim runs
              # it with the user's own configuration instead.
              shims="$(mktemp -d)"
              trap 'rm -rf "$shims"' EXIT
              if real_claude="$(command -v claude)"; then
                # shellcheck disable=SC2016 # "$@" belongs to the shim
                printf '#!/bin/sh\nunset CLAUDE_CONFIG_DIR\nexec %q "$@"\n' "$real_claude" >"$shims/claude"
                chmod +x "$shims/claude"
              fi

              if ! (
                cd "$install" &&
                  PATH="$shims:$PATH" \
                  CLAUDE_CONFIG_DIR="$claude_dir" \
                  GSTACK_STATE_ROOT="$state" \
                  GSTACK_SETTINGS_FILE="$settings" \
                  ./setup --team </dev/null
              ) >>"$log" 2>&1; then
                echo "gstack: setup failed; see .gstack/bootstrap.log" >&2
                exit 1
              fi

              # Every Claude Code session in the project gets gstack's
              # project-scoped settings, and on Linux the Nix-built browsers
              # (kept from garbage collection through .gstack/playwright-browsers)
              env="$(jq -n --arg state "$state" --arg settings "$settings" \
                '{ GSTACK_STATE_ROOT: $state, GSTACK_SETTINGS_FILE: $settings }')"
              if [ -n "''${PLAYWRIGHT_BROWSERS_PATH:-}" ]; then
                if command -v nix-store >/dev/null; then
                  nix-store --add-root "$state/playwright-browsers" --realise "$PLAYWRIGHT_BROWSERS_PATH" >/dev/null
                fi
                env="$(jq --arg path "$PLAYWRIGHT_BROWSERS_PATH" \
                  '. + { PLAYWRIGHT_BROWSERS_PATH: $path, PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD: "1" }' <<<"$env")"
              fi
              [ -f "$settings" ] || echo '{}' >"$settings"
              jq --argjson env "$env" '.env = ((.env // {}) + $env)' "$settings" >"$settings.tmp"
              mv "$settings.tmp" "$settings"

              exclude_gstack_skills
              touch "$state/bootstrap-done"
              echo "gstack: installed; it updates itself from gstack's stable channel" >&2
            '';
          };
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              self.packages.${system}.claude
              self.packages.${system}.gstack-bootstrap
              bun
              git
              nodejs_latest
              self.formatter.${system}
            ];

            env = browserEnv pkgs;

            # Not in CI, where checking the template shouldn't install gstack
            shellHook = ''
              if [ -z "''${CI:-}" ]; then
                gstack-bootstrap || true
              fi
            '';
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
