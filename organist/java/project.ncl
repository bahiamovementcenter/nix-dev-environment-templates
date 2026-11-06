let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

let java_version = 25 in # Change this value to update the whole stack

# `mkShell` adds each package's `dev` output (headers, pkg-config files) to the
# shell, while Organist adds the default output. This restores the former.
let with_dev_outputs =
  std.record.map (fun _name drv =>
    organist.nix.derivation.CallNix
    & {
      function = "{ package }: package.dev or package",
      args.package = drv,
    }
  )
in

let java_jdk = organist.import_nix "nixpkgs#jdk%{std.to_string java_version}" in

# Overrides can't be written in Nickel, so this calls a bit of Nix to build
# `package_name` against the JDK above (passed as its `jdk_arg` argument).
let with_jdk = fun package_name jdk_arg =>
  organist.nix.derivation.CallNix
  & {
    function = "{ package, jdk }: package.override { %{jdk_arg} = jdk; }",
    args = {
      package = organist.import_nix "nixpkgs#%{package_name}",
      jdk = java_jdk,
    },
  }
in

let lombok = with_jdk "lombok" "jdk" in

organist.OrganistExpression
& {
  Schema,
  config | Schema = {
    shells = organist.shells.Bash,

    shells.build.packages = {},

    shells.dev = {
      # No C compiler in the shell, like `mkShellNoCC`
      env.stdenv = organist.import_nix "nixpkgs#stdenvNoCC",

      packages =
        with_dev_outputs {
          gcc = organist.import_nix "nixpkgs#gcc",
          gradle = with_jdk "gradle" "java",
          jdk = java_jdk,
          maven = with_jdk "maven" "jdk_headless",
          ncurses = organist.import_nix "nixpkgs#ncurses",
          patchelf = organist.import_nix "nixpkgs#patchelf",
          zlib = organist.import_nix "nixpkgs#zlib",
          nixfmt = organist.import_nix "nixpkgs#nixfmt",
        },

      hooks.lombok = nix-s%"
          export JAVA_TOOL_OPTIONS="-javaagent:%{lombok}/share/java/lombok.jar${JAVA_TOOL_OPTIONS:+ $JAVA_TOOL_OPTIONS}"
        "%,
    },
  },
}
  | organist.modules.T
