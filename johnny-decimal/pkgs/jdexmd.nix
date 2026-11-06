# jdexmd builds a Johnny.Decimal system from an outline in a TOML file: the
# folders and notes of a Markdown notes vault (Obsidian, Logseq), a parallel
# folder tree for other files, and a JDex note listing the whole system. It
# only creates what's missing, except the JDex note, which it rewrites on
# every run. Not in Nixpkgs.
{
  lib,
  rustPlatform,
  fetchCrate,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "jdexmd";
  version = "0.1.3";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-ZH0LdOQv7YvzIFEWSyHWH4D9UB/5Opj8dSHPRWJkqrg=";
  };

  cargoHash = "sha256-4+cBr4bB9sn3ZPUxW3vV3jnuqZMZgoMNz5ZfA8S4NBI=";

  meta = {
    description = "Generates a Johnny.Decimal system and its JDex for Obsidian and a documents folder";
    homepage = "https://github.com/graysonarts/jdexmd";
    license = lib.licenses.mit;
    mainProgram = "jdexmd";
  };
})
