{
  description = "A Nix-flake-based Rust development environment for WebAssembly apps configured in Nickel";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
    fenix = {
      url = "https://flakehub.com/f/nix-community/fenix/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: {
        # Stable Rust with the standard library for the browser and edge
        # (wasm32-unknown-unknown) and for WASI hosts such as wasmtime
        # (wasm32-wasip2)
        rustToolchain =
          let
            fenix = inputs.fenix.packages.${prev.stdenv.hostPlatform.system};
          in
          fenix.combine (
            with fenix.stable;
            [
              clippy
              rustc
              cargo
              rustfmt
              rust-src
              fenix.targets.wasm32-unknown-unknown.stable.rust-std
              fenix.targets.wasm32-wasip2.stable.rust-std
            ]
          );
      };

      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          # mkShell, not mkShellNoCC: native builds and tests link with cc
          default = pkgs.mkShell {
            packages = with pkgs; [
              rustToolchain
              rust-analyzer
              cargo-deny
              cargo-watch

              # WebAssembly: run WASI modules and components, inspect them,
              # and generate browser bindings
              wasmtime
              wasm-tools
              wasm-bindgen-cli

              # For writing the configuration: Nickel itself (nickel format,
              # nickel typecheck) and its language server. The app embeds its
              # own interpreter through nickel-embed.
              nickel
              nls

              # Documents rendered from the app's data
              typst

              self.formatter.${system}
            ];

            # Required by rust-analyzer
            env.RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.nixfmt);
    };
}
