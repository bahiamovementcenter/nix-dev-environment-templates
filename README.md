# Nix flake templates for easy dev environments

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

To initialize (where `${ENV}` is listed in the table below):

```shell
nix flake init --template "https://flakehub.com/f/the-nix-way/dev-templates/*#${ENV}"
```

You can also use the shorter GitHub form:

```shell
nix flake init -t github:the-nix-way/dev-templates#${ENV}
```

Here's an example (for the [`rust`](./rust) template):

```shell
# Initialize in the current project
nix flake init --template "https://flakehub.com/f/the-nix-way/dev-templates/*#rust"

# or with the short GitHub form
nix flake init -t github:the-nix-way/dev-templates#rust

# Create a new project
nix flake new --template "https://flakehub.com/f/the-nix-way/dev-templates/*#rust" ${NEW_PROJECT_DIRECTORY}
```

## How to use the templates

Once your preferred template has been initialized, you can use the provided shell in two ways:

1. If you have [`nix-direnv`][nix-direnv] installed, you can initialize the environment by running `direnv allow`.
2. If you don't have `nix-direnv` installed, you can run `nix develop` to open up the Nix-defined shell.

## Available templates

| Language/framework/tool  | Template                      |
| :----------------------- | :---------------------------- |
| [Bun]                    | [`bun`](./bun/)               |
| [C] / [C++]              | [`c-cpp`](./c-cpp/)           |
| [Clojure]                | [`clojure`](./clojure/)       |
| [C#][csharp]             | [`csharp`](./csharp/)         |
| [Cue]                    | [`cue`](./cue/)               |
| [Deno]                   | [`deno`](./deno)              |
| [Dhall]                  | [`dhall`](./dhall/)           |
| [Elixir]                 | [`elixir`](./elixir/)         |
| [Elm]                    | [`elm`](./elm/)               |
| Empty (change at will)   | [`empty`](./empty)            |
| [Gleam]                  | [`gleam`](./gleam/)           |
| [Go]                     | [`go`](./go/)                 |
| [gstack] for [Claude Code] | [`gstack`](./gstack/)    |
| [Hashicorp] tools        | [`hashi`](./hashi/)           |
| [Haskell]                | [`haskell`](./haskell/)       |
| [Haxe]                   | [`haxe`](./haxe/)             |
| [Java]                   | [`java`](./java/)             |
| [Johnny Decimal][jd]     | [`johnny-decimal`](./johnny-decimal/) |
| [Jupyter]                | [`jupyter`](./jupyter/)       |
| [Kotlin]                 | [`kotlin`](./kotlin/)         |
| [LaTeX]                  | [`latex`](./latex/)           |
| [Nickel]                 | [`nickel`](./nickel/)         |
| [Nim]                    | [`nim`](./nim/)               |
| [Nix]                    | [`nix`](./nix/)               |
| Other distributions ([Distrobox]) | [`nixtrobox`](./nixtrobox/) |
| [Node.js][node]          | [`node`](./node/)             |
| [OCaml]                  | [`ocaml`](./ocaml/)           |
| [Odin]                   | [`odin`](./odin/)             |
| [Open Policy Agent][opa] | [`opa`](./opa)                |
| [PHP]                    | [`php`](./php/)               |
| [PlatformIO]             | [`platformio`](./platformio/) |
| [Presenterm]             | [`presenterm`](./presenterm/) |
| [PowerShell]             | [`powershell`](./powershell/) |
| [Protobuf]               | [`protobuf`](./protobuf/)     |
| [Pulumi]                 | [`pulumi`](./pulumi/)         |
| [Purescript]             | [`purescript`](./purescript/) |
| [Python]                 | [`python`](./python/)         |
| [R]                      | [`r`](./r/)                   |
| [Ruby]                   | [`ruby`](./ruby/)             |
| [Rust]                   | [`rust`](./rust/)             |
| [Scala]                  | [`scala`](./scala/)           |
| Shell                    | [`shell`](./shell/)           |
| [SWI-prolog]             | [`swi-prolog`](./swi-prolog/) |
| [Swift]                  | [`swift`](./swift)            |
| [Typst]                  | [`typst`](./typst/)           |
| [Vlang]                  | [`vlang`](./vlang/)           |
| [Zig]                    | [`zig`](./zig/)               |

## Template contents

The sections below list what each template includes. In all cases, you're free to add and remove packages as you see fit; the templates are just boilerplate.

### [`bun`](./bun/)

- [bun]

### [`c-cpp`](./c-cpp/)

- [clang-tools]
- [cmake]
- [codespell]
- [conan]
- [cppcheck]
- [doxygen]
- [gdb]
- [gtest]
- [lcov]
- [vcpkg]
- [vcpkg-tool]

### [`clojure`](./clojure/)

- [Clojure]
- [Boot]
- [Leiningen]

### [`csharp`](./csharp/)

- [dotnet]
- [omnisharp-roslyn]
- [Mono]
- [msbuild]

### [`cue`](./cue/)

- [Cue]

### [`dhall`](./dhall)

- [Dhall]
- [dhall-bash]
- [dhall-docs]
- [dhall-json]
- [dhall-lsp-server]
- [dhall-nix]
- [dhall-nixpkgs]
- [dhall-openapi]
- [dhall-toml]
- [dhall-yaml]

### [`elixir`](./elixir/)

- [Elixir], including [mix] and [IEx]
- [gigalixir] (Linux only)

### [`elm`](./elm/)

- [Elm]
- [elm2nix]

### [Empty](./empty/)

A dev template that's fully customizable.

### [`gleam`](./gleam/)

- [Gleam]

### [`go`](./go/)

- [Go]
- Standard Go tools ([goimports], [godoc], and others)
- [golangci-lint]

### [`gstack`](./gstack/)

- [Claude Code], the latest release from npm on every run (`claude`; on NixOS it needs [nix-ld], as the npm package ships a native binary)
- [gstack], installed into the project's `.claude/skills/` the first time you enter the shell or start a Claude Code session there, then kept up to date by gstack's own auto-update
- [Bun], [Node.js][node], [Git] and, on Linux, the Chromium gstack's browser skills drive

Everything gstack writes stays in the project and out of git (`.claude/skills/`, `.claude/settings.local.json`, `.gstack/`). The committed `.claude/settings.json` installs gstack from a SessionStart hook, so Claude Code sessions that don't use the dev shell, such as cloud agents, get it too. In a [Claude Code cloud environment][claude-cloud], running `nix run .#gstack-bootstrap` from the environment's setup script installs it before the session starts.

### [`hashi`](./hashi/)

- [Packer]
- [Terraform]
- [Nomad]
- [Vault]
- [nomad-autoscaler]
- [nomad-pack]
- [levant]
- [damon]
- [Terragrunt]
- [tflint]

### [`haskell`](./haskell/)

- [GHC][haskell]
- [cabal]

### [`haxe`](./haxe/)

- [Haxe]

### [`java`](./java/)

- [Java]
- [Maven]
- [Gradle]
- [jdtls]

### [`johnny-decimal`](./johnny-decimal/)

- [jd][jd-cli], the official Johnny.Decimal command-line tool
- [jdd]

### [`jupyter`](./jupyter/)

- [Jupyter core][jupyter]

### [`kotlin`](./kotlin/)

- [Kotlin]
- [Gradle]

### [`latex`](./latex/)

- [texlive]
- [tectonic]
- [texlab]

### [`lean4`](./lean4/)

- [Lean]

### [`nickel`](./nickel/)

- [Nickel]

### [`nim`](./nim)

- [Nim]
- [nimble]

### [`nix`](./nix/)

- [Cachix]
- [dhall-to-nix]
- [lorri]
- [niv]
- [nixfmt]
- [statix]
- [vulnix]

### [`nixtrobox`](./nixtrobox/)

- [Distrobox] boxes of Arch Linux, Debian, Fedora and Ubuntu, with each image pinned by digest and hash (see its [README](./nixtrobox/README.md))

### [`node`](./node/)

- [Node.js][node]
- [npm]
- [pnpm]
- [Yarn]
- [node2nix]

### [`ocaml`](./ocaml/)

- [OCaml]
- [Dune]
- [odoc]
- [ocamlformat]

### [`odin`](./odin/)

- [Odin]

### [`opa`](./opa/)

- [Open Policy Agent][opa]
- [Conftest]

### [`php`](./php/)

- [PHP]
- [Composer]

### [`platformio`](./platformio/)

- [PlatformIO]

### [`Presenterm`](./presenterm/)

- [Presenterm]
- [Mermaid-cli]
- [Typst]
- [pandoc]
### [`powershell`](./powershell/)

- [Powershell]
- [Powershell Editor Services][powershell-editor-services]

### [`protobuf`](./protobuf/)

- The [Buf CLI][buf]
- [protoc][protobuf]

### [`pulumi`](./pulumi/)

- [Pulumi]
- [Python]
- [Go]
- [Node.js][node]
- [dotnet]
- [Java] and [Maven]
- [jq]

### [`purescript`](./purescript/)

- [Purescript] (purs)
- [Spago]

### [`python`](./python/)

- [Python]
- [pip]

### [`r`](./r/)

- [R]
- [rmarkdown]
- [knitr] ([pandoc] and [texlive])

### [`ruby`](./ruby/)

- [Ruby], plus the standard Ruby tools (`bundle`, `gem`, etc.)

### [`rust`](./rust/)

- [Rust], including [cargo], [Clippy], and the other standard tools. The Rust version is determined as follows, in order:
  - From the `rust-toolchain.toml` file if present
  - From the `rust-toolchain` file if present
  - Version 1.78.0 if neither is present
- [rust-analyzer]
- [cargo-edit]
- [cargo-deny]

### [`scala`](./scala/)

- [Scala] (plus [Java])
- [sbt]

### [`shell`](./shell/)

- [shellcheck]

### [`swi-prolog`](./swi-prolog/)

- [swipl][swi-prolog]

### [`swift`](./swift/)

- [Swift]
- [sourcekit-lsp]

### [`typst`](./typst/)

- [Typst]

### [`vlang`](./vlang/)

- [Vlang]

### [`zig`](./zig/)

- [Zig]
- [LLDB]
- [ZLS]

[boot]: https://boot-clj.com
[buf]: https://github.com/bufbuild/buf
[bun]: https://bun.sh
[C]: https://open-std.org/jtc1/sc22/wg14
[C++]: https://isocpp.org
[cabal]: https://haskell.org/cabal
[cachix]: https://cachix.org
[cargo]: https://doc.rust-lang.org/cargo
[cargo-deny]: https://crates.io/crates/cargo-deny
[cargo-edit]: https://crates.io/crates/cargo-edit
[clang-tools]: https://clang.llvm.org
[claude code]: https://code.claude.com
[claude-cloud]: https://code.claude.com/docs/en/claude-code-on-the-web
[clippy]: https://github.com/rust-lang/rust-clippy
[clojure]: https://clojure.org
[cmake]: https://cmake.org
[codespell]: https://github.com/codespell-project/codespell
[composer]: https://getcomposer.org
[conan]: https://conan.io
[conftest]: https://conftest.dev
[cppcheck]: http://cppcheck.sourceforge.net
[csharp]: https://dotnet.microsoft.com/en-us/languages/csharp
[cue]: https://cuelang.org
[damon]: https://github.com/hashicorp/damon
[deno]: https://deno.com
[dhall]: https://dhall-lang.org
[dhall-bash]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-bash
[dhall-docs]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-docs
[dhall-json]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-json
[dhall-lsp-server]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-lsp-server
[dhall-nix]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-nix
[dhall-nixpkgs]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-nixpkgs
[dhall-openapi]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-openapi
[dhall-to-nix]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-nix
[dhall-toml]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-toml
[dhall-yaml]: https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-yaml
[distrobox]: https://distrobox.it
[dotnet]: https://dotnet.microsoft.com/en-us
[doxygen]: https://doxygen.nl
[dune]: https://dune.build
[elixir]: https://elixir-lang.org
[elm]: https://elm-lang.org
[elm2nix]: https://github.com/cachix/elm2nix
[gdb]: https://gnu.org/software/gdb
[gigalixir]: https://gigalixir.com
[git]: https://git-scm.com
[gleam]: https://gleam.run
[go]: https://go.dev
[godoc]: https://pkg.go.dev/golang.org/x/tools/cmd/godoc
[goimports]: https://pkg.go.dev/golang.org/x/tools/cmd/goimports
[golangci-lint]: https://github.com/golangci/golangci-lint
[gradle]: https://gradle.org
[gstack]: https://github.com/garrytan/gstack
[gtest]: https://github.com/google/googletest
[hashicorp]: https://hashicorp.com
[haskell]: https://haskell.org
[haxe]: https://haxe.org
[iex]: https://hexdocs.pm/iex/IEx.html
[java]: https://java.com
[jdtls]: https://projects.eclipse.org/projects/eclipse.jdt.ls
[jq]: https://jqlang.github.io/jq
[jd]: https://johnnydecimal.com
[jd-cli]: https://github.com/johnnydecimal/cli.johnnydecimal.com
[jdd]: https://github.com/mahyarmirrashed/jdd
[jupyter]: https://jupyter.org
[knitr]: https://yihui.org/knitr
[kotlin]: https://kotlinlang.org
[latex]: https://latex-project.org
[lean]: https://lean-lang.org
[lcov]: https://ltp.sourceforge.net/coverage/lcov.php
[leiningen]: https://leiningen.org
[levant]: https://github.com/hashicorp/levant
[lldb]: https://lldb.llvm.org
[lorri]: https://github.com/target/lorri
[maven]: https://maven.apache.org
[mermaid-cli]: https://github.com/mermaid-js/mermaid-cli
[mix]: https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html
[nickel]: https://nickel-lang.org
[nim]: https://nim-lang.org
[nimble]: https://github.com/nim-lang/nimble
[niv]: https://github.com/nmattia/niv
[nix]: https://nixos.org
[nix-ld]: https://github.com/nix-community/nix-ld
[nixfmt]: https://github.com/serokell/nixfmt
[nix-direnv]: https://github.com/nix-community/nix-direnv
[node]: https://nodejs.org
[node2nix]: https://github.com/svanderburg/node2nix
[nomad]: https://nomadproject.io
[nomad-autoscaler]: https://github.com/hashicorp/nomad-autoscaler
[nomad-pack]: https://github.com/hashicorp/nomad-pack
[npm]: https://npmjs.org
[ocaml]: https://ocaml.org
[ocamlformat]: https://github.com/ocaml-ppx/ocamlformat
[odoc]: https://github.com/ocaml/odoc
[odin]: https://github.com/odin-lang/Odin
[opa]: https://openpolicyagent.org
[pandoc]: https://pandoc.org
[packer]: https://packer.io
[pip]: https://pypi.org/project/pip
[php]: https://php.net
[platformio]: https://platformio.org
[powershell]: https://github.com/PowerShell/PowerShell
[powershell-editor-services]: https://github.com/PowerShell/PowerShellEditorServices
[python]: https://python.org
[pnpm]: https://pnpm.io
[presenterm]: https://github.com/mfontanini/presenterm
[protobuf]: https://developers.google.com/protocol-buffers
[pulumi]: https://pulumi.com
[purescript]: https://github.com/purescript/purescript
[r]: https://r-project.org
[rmarkdown]: https://rmarkdown.rstudio.com
[ruby]: https://ruby-lang.org
[rust]: https://rust-lang.org
[rust-analyzer]: https://rust-analyzer.github.io
[scala]: https://scala-lang.org
[shellcheck]: https://shellcheck.net
[statix]: https://github.com/nerdypepper/statix
[sbt]: https://scala-sbt.org
[sourcekit-lsp]: https://github.com/swiftlang/sourcekit-lsp
[spago]: https://github.com/purescript/spago
[swi-prolog]: https://www.swi-prolog.org
[swift]: https://swift.org
[tectonic]: https://tectonic-typesetting.github.io
[terraform]: https://terraform.io
[terragrunt]: https://terragrunt.gruntwork.io
[texlab]: https://github.com/latex-lsp/texlab
[texlive]: https://tug.org/texlive
[tflint]: https://github.com/terraform-linters/tflint
[typst]: https://typst.app
[vault]: https://vaultproject.io
[vcpkg]: https://vcpkg.io
[vcpkg-tool]: https://github.com/microsoft/vcpkg-tool
[vulnix]: https://github.com/flyingcircusio/vulnix
[yarn]: https://yarnpkg.com
[vlang]: https://vlang.io
[zig]: https://ziglang.org
[zls]: https://github.com/zigtools/zls
