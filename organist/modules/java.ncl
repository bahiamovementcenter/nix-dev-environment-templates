# A JDK with Maven, Gradle and Lombok built against it, as in the java
# template
fun organist common =>
  fun options =>
    let options
      | {
        # The JDK version, for the whole stack
        version | Number | default = 25,
      }
      = options
    in
    let java_jdk = organist.import_nix "nixpkgs#jdk%{std.to_string options.version}" in

    # Overrides can't be written in Nickel, so this calls a bit of Nix to
    # build `package_name` against the JDK above (passed as its `jdk_arg`
    # argument).
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
    {
      shells.dev = {
        packages = common.with_dev_outputs {
          gcc = organist.import_nix "nixpkgs#gcc",
          gradle = with_jdk "gradle" "java",
          jdk = java_jdk,
          maven = with_jdk "maven" "jdk_headless",
          ncurses = organist.import_nix "nixpkgs#ncurses",
          patchelf = organist.import_nix "nixpkgs#patchelf",
          zlib = organist.import_nix "nixpkgs#zlib",
        },

        hooks.lombok = nix-s%"
            export JAVA_TOOL_OPTIONS="-javaagent:%{lombok}/share/java/lombok.jar${JAVA_TOOL_OPTIONS:+ $JAVA_TOOL_OPTIONS}"
          "%,
      },
    }
