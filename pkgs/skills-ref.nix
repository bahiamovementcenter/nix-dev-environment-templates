# The Agent Skills reference validator (agentskills.io), whose command is
# `agentskills`; not in Nixpkgs
{ python3Packages, fetchPypi }:

python3Packages.buildPythonApplication rec {
  pname = "skills-ref";
  version = "0.1.1";
  format = "wheel";
  src = fetchPypi {
    pname = "skills_ref";
    inherit version format;
    dist = "py3";
    python = "py3";
    hash = "sha256-0121u43nGuMB2vXKnLcfilVejG+DptQORqW8Cfj0YbU=";
  };
  dependencies = with python3Packages; [
    click
    strictyaml
  ];
  meta.mainProgram = "agentskills";
}
