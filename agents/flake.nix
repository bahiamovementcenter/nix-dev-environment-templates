{
  description = "A Nix-flake-based AI coding agents development environment";

  # Pre-built binaries from Numtide's cache. Without this, agents build from source.
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

    # Deliberately does NOT follow our nixpkgs: its package revisions must match
    # the cache. Pin it with the lockfile and update on purpose, not on a whim.
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

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
            pkgs = import inputs.nixpkgs { inherit system; };
          }
        );
    in
    {
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        let
          llm = inputs.llm-agents.packages.${system};

          # Keep only packages that exist for this system, so a platform-limited
          # tool (e.g. a Linux-only sandbox) doesn't break the shell elsewhere.
          pick = names: map (n: llm.${n}) (builtins.filter (n: builtins.hasAttr n llm) names);

          # Edit these lists. Fewer agents means a smaller closure and attack surface.
          agents = pick [
            "claude-code"
            "codex"
            "opencode"
          ];

          sandboxes = pick [
            "claudebox" # sandboxed environment for Claude Code
            "sandbox-runtime" # filesystem and network restrictions for any command
          ];
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.nodejs
              self.formatter.${system}
            ]
            ++ agents
            ++ sandboxes;

            shellHook = ''
              echo "Agents run as YOUR user with YOUR environment. Prefer the sandbox tools for untrusted work."
            '';
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
