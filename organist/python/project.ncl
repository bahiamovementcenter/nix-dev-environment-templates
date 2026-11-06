let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

# Change this value ({major}.{min}) to update the Python virtual-environment
# version. When you do this, make sure to delete the `.venv` directory to have
# the hook rebuild it for the new version, since it won't overwrite an existing
# one. After this, reload the development shell to rebuild it. You'll see a
# warning asking you to do this when version mismatches are present. For
# safety, removal should be a manual step, even if trivial.
let version = "3.13" in

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

let python_attr =
  std.string.split "." version
  |> std.array.slice 0 2
  |> std.string.join ""
  |> (fun major_minor => "python%{major_minor}")
in
let python_version = organist.import_nix "nixpkgs#%{python_attr}.version" in

organist.OrganistExpression
& {
  Schema,
  config | Schema = {
    shells = organist.shells.Bash,

    shells.build.packages = {},

    shells.dev = {
      # No C compiler in the shell, like `mkShellNoCC`
      env.stdenv = organist.import_nix "nixpkgs#stdenvNoCC",

      env.venvDir = ".venv",

      # Organist always sets `shellHook`, so the venv hook has to be called
      # explicitly. It runs `postShellHook` once the venv is active.
      hooks.venv = "venvShellHook",

      env.postShellHook = nix-s%"
          venvVersionWarn() {
          	local venvVersion
          	venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"

          	[[ "$venvVersion" == "%{python_version}" ]] && return

          	cat <<EOF
          Warning: Python version mismatch: [$venvVersion (venv)] != [%{python_version}]
                   Delete '$venvDir' and reload to rebuild for version %{python_version}
          EOF
          }

          venvVersionWarn
        "%,

      packages =
        with_dev_outputs {
          venvShellHook = organist.import_nix "nixpkgs#%{python_attr}.pkgs.venvShellHook",
          pip = organist.import_nix "nixpkgs#%{python_attr}.pkgs.pip",

          # Add whatever else you'd like here.
          # basedpyright = organist.import_nix "nixpkgs#basedpyright",
          # ruff = organist.import_nix "nixpkgs#ruff",

          nixfmt = organist.import_nix "nixpkgs#nixfmt",
        },
    },
  },
}
  | organist.modules.T
