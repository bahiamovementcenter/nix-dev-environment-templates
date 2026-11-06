# Python in a virtual environment (.venv), with pip, as in the python
# template
fun organist common =>
  fun options =>
    let options
      | {
        # The Python version ({major}.{minor}). After changing it, delete
        # .venv and reload the shell to rebuild it for the new version; a
        # warning says so when they don't match.
        version | String | default = "3.13",
      }
      = options
    in
    let python_attr =
      std.string.split "." options.version
      |> std.array.slice 0 2
      |> std.string.join ""
      |> (fun major_minor => "python%{major_minor}")
    in
    let python_version = organist.import_nix "nixpkgs#%{python_attr}.version" in
    {
      shells.dev = {
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

        packages = common.with_dev_outputs {
          venvShellHook = organist.import_nix "nixpkgs#%{python_attr}.pkgs.venvShellHook",
          pip = organist.import_nix "nixpkgs#%{python_attr}.pkgs.pip",
        },
      },
    }
