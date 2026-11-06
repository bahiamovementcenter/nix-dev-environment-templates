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
| Agent conventions (layer) | [`agents`](./agents/)        |
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

## Agent conventions

The [`agents`](./agents/) template sets a project up for AI coding agents, following the cross-tool standards where they exist and Claude Code's conventions where they don't:

| What | Standard | Files |
| :-- | :-- | :-- |
| Instructions for any agent | [AGENTS.md] | `AGENTS.md` (nested ones for subprojects; the nearest wins) |
| Claude Code's instructions | Claude Code | `CLAUDE.md`, which imports `AGENTS.md`; Claude Code reads `AGENTS.md` on its own only when there's no `CLAUDE.md` |
| Skills | [Agent Skills] | `.agents/skills/<name>/SKILL.md`, the cross-client location, with `.claude/skills` a symlink to it for Claude Code |
| Settings, permissions, hooks | Claude Code | `.claude/settings.json`, committed, created when a project needs settings (`check-agents` validates it); `.claude/settings.local.json`, gitignored |
| MCP servers | Claude Code | `.mcp.json` |

It's deliberately unopinionated: it sets up only what these standards define, with placeholder headings in `AGENTS.md` and no skills, subagents, hooks or permissions of its own, so it can serve as the base for more opinionated setups. It has no `flake.nix`, `.envrc`, `.gitignore` or `.claude/settings.json`, so it layers onto any project, including one made from another template (`gstack` too, in either order):

```shell
nix flake init -t github:bahiamovementcenter/nix-dev-environment-templates#python
nix flake init -t github:bahiamovementcenter/nix-dev-environment-templates#agents
```

Without Nix, extract it from the repository's tarball (GNU tar; `--skip-old-files` keeps files you already have):

```shell
curl -sL https://github.com/bahiamovementcenter/nix-dev-environment-templates/archive/refs/heads/main.tar.gz \
  | tar -xz --strip-components=2 --skip-old-files --wildcards '*/agents/'
```

`nix develop --command check-agents [DIR…]` validates a project's skills with the Agent Skills reference validator (`agentskills`), its `.claude/settings.json` against the [Claude Code settings schema](https://json.schemastore.org/claude-code-settings.json), and the `.claude/skills` symlink. Keep personal notes in `CLAUDE.local.md`, and add it to your `.gitignore`.

## Organist templates

The [`organist`](./organist/) directory has versions of four templates defined with [Organist], which describes the development shell in [Nickel] (`project.ncl`) instead of Nix:

| Language/framework/tool | Template                                     | Ported from               |
| :---------------------- | :------------------------------------------- | :------------------------ |
| [Elixir]                | [`organist-elixir`](./organist/elixir/)      | [`elixir`](./elixir/)     |
| [Java]                  | [`organist-java`](./organist/java/)          | [`java`](./java/)         |
| [Nickel]                | [`organist-nickel`](./organist/nickel/)      | [`nickel`](./nickel/)     |
| [Python]                | [`organist-python`](./organist/python/)      | [`python`](./python/)     |

They're initialized the same way (for example `nix flake init -t github:bahiamovementcenter/nix-dev-environment-templates#organist-java`; they aren't in the upstream repo) and give the same shell as the template they were ported from, plus [Nickel] and its language server for editing `project.ncl`.

### Combining languages

Each Organist template is one module from [`organist/modules`](./organist/modules/), merged into a base shell, so a project that needs several languages merges several modules. The [`organist`](./organist/compose/) template starts with Python and Nickel:

```shell
nix flake init -t github:bahiamovementcenter/nix-dev-environment-templates#organist
```

```nickel
config | Schema =
  modules.base
  & modules.python { version = "3.13" }
  & modules.nickel {}
  & modules.java { version = 25 }
  & { shells.dev.packages.ruff = organist.import_nix "nixpkgs#ruff" },
```

Each module takes a record of options, all optional (`{}` for the defaults); a misspelled option is an error. The modules come from this repository through the `dev-templates` flake input, which Organist's `lockFileContents` makes importable from `nickel.lock.ncl`. That input also provides the packages the modules use that aren't in Nixpkgs, built with the project's own Nixpkgs (`inputs.nixpkgs.follows`). Two modules that set the same thing differently, such as a different `postShellHook`, fail to merge rather than one silently winning.

Modules so far: `base`, `elixir`, `java`, `nickel` and `python`.

> [!NOTE]
> With [Determinate Nix][determinate-nix], these templates fail to evaluate (`path '…-regenerate-files.drv' is not valid`) unless its lazy trees are turned off, for example with `NIX_CONFIG='lazy-trees = false' nix develop`. Organist imports Nix expressions it generates during evaluation, and lazy trees leave the derivations those refer to unwritten. Upstream Nix is unaffected.

Organist evaluates `project.ncl` with [import from derivation][ifd], so `nix flake check --all-systems` can't evaluate these templates for other systems from a single machine. They're left out of the `build` and `check` scripts, and checked by `check-organist` instead, which compares each one with its original on the current system:

```shell
nix develop --command check-organist          # all templates
nix develop --command check-organist java     # just one
```

It evaluates both shells against the Nixpkgs revision locked in this repo's `flake.lock` and compares which package provides each command, the shell's variables and functions, and the output of a few commands run in both shells. The commands, and any intended differences, are listed in [`organist/parity.json`](./organist/parity.json). The composed `organist` template is checked against each template it combines: every command they provide must come from the same package, and their smoke tests must give the same output. The check builds the Organist templates from this checkout's modules and packages, not the published ones.

## Packages that aren't in Nixpkgs

Some templates need tools Nixpkgs doesn't have (`jd`, `jdexmd`, `wattlebird-generator`, `json-schema-to-nickel`, `tf-ncl`, `schema-merge`). Each is defined once in [`pkgs/`](./pkgs/) and exported by this repo's flake, so you can use them without a template:

```shell
nix run github:bahiamovementcenter/nix-dev-environment-templates#json-schema-to-nickel -- schema.json
```

or add them to your own Nixpkgs with the flake's `overlays.default`. The templates that use one keep an identical copy in their own `pkgs/` folder, so each template still works on its own; `nix develop --command check-vendored` (run in CI) checks that the copies match.

## Template contents

The sections below list what each template includes. In all cases, you're free to add and remove packages as you see fit; the templates are just boilerplate.

### [`agents`](./agents/)

- [AGENTS.md] and a `CLAUDE.md` that imports it
- An empty [Agent Skills] folder, `.agents/skills/`, with `.claude/skills` linked to it
- `.mcp.json` for Claude Code, and `.claude/.gitignore` for personal settings

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

Everything gstack writes stays in the project and out of git (`.claude/skills/`, `.claude/settings.local.json`, `.gstack/`). Its instructions for Claude Code are in `.claude/rules/gstack.md`, not `CLAUDE.md`, so the template layers with [`agents`](#agent-conventions); there, `.claude/skills` links to `.agents/skills`, and `gstack-bootstrap` keeps gstack's skills out of git through the clone's `.git/info/exclude`. The committed `.claude/settings.json` installs gstack from a SessionStart hook, so Claude Code sessions that don't use the dev shell, such as cloud agents, get it too. In a [Claude Code cloud environment][claude-cloud], running `nix run .#gstack-bootstrap` from the environment's setup script installs it before the session starts.

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
- [Tf-Ncl], [Nickel] and [nls], for writing Terraform configurations in Nickel, checked against contracts for the providers you select in `flake.nix`:
  - `link-schema` links the contracts into the project as `tf-ncl-schema.ncl`, for `main.ncl` to import
  - `run-nickel` evaluates `main.ncl` into `main.tf.json`
  - `run-terraform …` runs `run-nickel`, then Terraform with those arguments

  A minimal `main.ncl`, with `hashicorp_null` selected:

  ```nickel
  let Tf = import "./tf-ncl-schema.ncl" in
  {
    config.resource.null_resource.hello.provisioner.local-exec = [
      { command = "echo 'Hello from Nickel'" },
    ],
  } | Tf.Config
  ```

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
- [wattlebird-generator]: `wattlebird-generate` writes a messy fictional business for an agent to file, and `wattlebird-score` scores the result (the answer key goes to `~/.local/state/wattlebird-generator`, out of the agent's reach)
- [jdexmd], which builds a system's folders, notes and JDex from an outline in a TOML file

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

- [Nickel], which also formats Nickel code (`nickel format`)
- [nls], the Nickel language server
- [json-schema-to-nickel], which converts a JSON schema into a Nickel contract (`json-schema-to-nickel schema.json > contract.ncl`)

### [`nim`](./nim)

- [Nim]
- [nimble]

### [`nix`](./nix/)

- [Cachix]
- [dhall-to-nix]
- [lorri]
- [nh]
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

- [Typst], with [Tinymist] and [typstyle]
- [Typix], which compiles `main.typ` with Nix, using the fonts and files listed in `flake.nix`:
  - `nix run .#build` writes `main.pdf` (or the path given)
  - `nix run .#watch` recompiles it whenever its sources change
  - `nix build` builds it into `result`

### [`vlang`](./vlang/)

- [Vlang]

### [`zig`](./zig/)

- [Zig]
- [LLDB]
- [ZLS]

[agent skills]: https://agentskills.io/specification
[agents.md]: https://agents.md
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
[determinate-nix]: https://docs.determinate.systems/determinate-nix
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
[ifd]: https://nix.dev/manual/nix/stable/language/import-from-derivation
[java]: https://java.com
[jdexmd]: https://github.com/graysonarts/jdexmd
[jdtls]: https://projects.eclipse.org/projects/eclipse.jdt.ls
[jq]: https://jqlang.github.io/jq
[jd]: https://johnnydecimal.com
[jd-cli]: https://github.com/johnnydecimal/cli.johnnydecimal.com
[jdd]: https://github.com/mahyarmirrashed/jdd
[json-schema-to-nickel]: https://github.com/nickel-lang/json-schema-to-nickel
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
[nh]: https://github.com/nix-community/nh
[nickel]: https://nickel-lang.org
[nim]: https://nim-lang.org
[nimble]: https://github.com/nim-lang/nimble
[niv]: https://github.com/nmattia/niv
[nix]: https://nixos.org
[nix-ld]: https://github.com/nix-community/nix-ld
[nixfmt]: https://github.com/serokell/nixfmt
[nix-direnv]: https://github.com/nix-community/nix-direnv
[nls]: https://github.com/nickel-lang/nickel/tree/master/lsp
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
[organist]: https://github.com/nickel-lang/organist
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
[tf-ncl]: https://github.com/nickel-lang/tf-ncl
[tflint]: https://github.com/terraform-linters/tflint
[tinymist]: https://github.com/Myriad-Dreamin/tinymist
[typix]: https://github.com/loqusion/typix
[typst]: https://typst.app
[typstyle]: https://github.com/typstyle-rs/typstyle
[vault]: https://vaultproject.io
[vcpkg]: https://vcpkg.io
[vcpkg-tool]: https://github.com/microsoft/vcpkg-tool
[vulnix]: https://github.com/flyingcircusio/vulnix
[wattlebird-generator]: https://github.com/johnnydecimal/wattlebird-generator
[yarn]: https://yarnpkg.com
[vlang]: https://vlang.io
[zig]: https://ziglang.org
[zls]: https://github.com/zigtools/zls
