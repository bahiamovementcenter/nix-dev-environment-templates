# Turns merged Terraform provider schemas into a Nickel contract; see
# https://github.com/nickel-lang/tf-ncl. Not in Nixpkgs, released or tagged,
# so it's built from a pinned commit.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "tf-ncl";
  version = "0-unstable-2026-02-03";

  src = fetchFromGitHub {
    owner = "nickel-lang";
    repo = "tf-ncl";
    rev = "53f3c469d6c40b8bbff92ddb6f48cc5249af75fd";
    hash = "sha256-CKWiknhAFv3gk/CTb4Mv3vxvONftfMe8jlNmmv+HdJQ=";
  };

  cargoHash = "sha256-J0ZOW5EKzdjqa3rRCxmpbwCAHRxQTEcn6ffRksUp+hk=";

  # Upstream's CI runs the tests; the shell only needs the binary
  doCheck = false;

  meta = {
    description = "Generate Nickel contracts for Terraform providers";
    homepage = "https://github.com/nickel-lang/tf-ncl";
    license = lib.licenses.mit;
    mainProgram = "tf-ncl";
  };
}
