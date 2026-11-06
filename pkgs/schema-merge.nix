# Merges the schemas Terraform reports for each provider with Terraform's own
# configuration schema, for tf-ncl. Part of the tf-ncl repository, and built
# from the same pinned commit.
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

let
  src = fetchFromGitHub {
    owner = "nickel-lang";
    repo = "tf-ncl";
    rev = "53f3c469d6c40b8bbff92ddb6f48cc5249af75fd";
    hash = "sha256-CKWiknhAFv3gk/CTb4Mv3vxvONftfMe8jlNmmv+HdJQ=";
  };
in
buildGoModule {
  pname = "schema-merge";
  version = "0-unstable-2026-02-03";

  src = "${src}/schema-merge";

  vendorHash = "sha256-JWHyBLu5hqO+ed2SwdmLabwbPeKAM30UirfksI3aSPc=";

  meta = {
    description = "Merge Terraform provider schemas for tf-ncl";
    homepage = "https://github.com/nickel-lang/tf-ncl";
    license = lib.licenses.mit;
    mainProgram = "schema-merge";
  };
}
