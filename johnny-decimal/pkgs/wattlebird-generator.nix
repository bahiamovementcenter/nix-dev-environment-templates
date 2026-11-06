# The Wattlebird generator writes a fictional small shop's flat, messy folder
# for an agent to file into a Johnny.Decimal system, and scores the result,
# from jd's move journal or a folder listing. generate.py writes its answer
# key beside itself, which a Nix store path can't hold, so the launcher points
# it at a state folder instead (WATTLEBIRD_KEY_DIR, by default
# ~/.local/state/wattlebird-generator), outside any project, where the agent
# under test won't find it.
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python3,
  runtimeShell,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "wattlebird-generator";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "johnnydecimal";
    repo = "wattlebird-generator";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WNdwEyV21Kixv4VqGHZgOolja1+DOFoFR1pzpAtG6i4=";
  };

  nativeBuildInputs = [ python3 ];

  dontBuild = true;

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    python3 -m unittest
    runHook postCheck
  '';

  installPhase =
    let
      share = "${placeholder "out"}/share/wattlebird-generator";
    in
    ''
      runHook preInstall

      mkdir -p ${share} $out/bin
      cp -r generate.py score.py answer-key.csv README.md ${share}/

      cat >$out/bin/wattlebird-generate <<'EOF'
      #!${runtimeShell}
      # Usage: wattlebird-generate OUT_DIR [--seed N]
      key_dir="''${WATTLEBIRD_KEY_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/wattlebird-generator}"
      mkdir -p "$key_dir"
      exec ${python3}/bin/python3 -c '
      import sys
      from pathlib import Path
      sys.path.insert(0, sys.argv.pop(1))
      key_dir = Path(sys.argv.pop(1)).resolve()
      import generate
      generate.TOOL_DIR = key_dir
      generate.main()
      ' ${share} "$key_dir" "$@"
      EOF

      cat >$out/bin/wattlebird-score <<'EOF'
      #!${runtimeShell}
      # Usage: wattlebird-score KEY MAP --journal JOURNAL --root MESS_ROOT
      #        wattlebird-score KEY MAP --listing FOLDER_OR_LS_R_FILE
      exec ${python3}/bin/python3 ${share}/score.py "$@"
      EOF

      chmod +x $out/bin/*

      runHook postInstall
    '';

  meta = {
    description = "Generates a messy fictional business to test Johnny.Decimal filing, and scores the result";
    homepage = "https://github.com/johnnydecimal/wattlebird-generator";
    license = lib.licenses.mit;
    mainProgram = "wattlebird-generate";
  };
})
