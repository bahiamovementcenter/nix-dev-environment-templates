# The official Johnny.Decimal command-line tool (jd). It isn't packaged in
# Nixpkgs, so it's fetched at a pinned revision and wrapped so that jq is
# always on its PATH.
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  jq,
}:

stdenvNoCC.mkDerivation {
  pname = "jd";
  version = "4.4.0";

  src = fetchFromGitHub {
    owner = "johnnydecimal";
    repo = "cli.johnnydecimal.com";
    rev = "863d2e6412b70c385db8bdbcd6e1b3e28e6048f4";
    hash = "sha256-jM0nlEJACeE+5Ojluwpd4Hwkfyvn1Ppnzhqc85PFqtA=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/johnnydecimal $out/bin
    cp -r . $out/share/johnnydecimal/cli

    makeWrapper $out/share/johnnydecimal/cli/bin/jd $out/bin/jd \
      --prefix PATH : ${lib.makeBinPath [ jq ]}

    runHook postInstall
  '';

  meta = {
    description = "The Johnny.Decimal command-line tool";
    homepage = "https://github.com/johnnydecimal/cli.johnnydecimal.com";
    license = lib.licenses.mit;
    mainProgram = "jd";
  };
}
