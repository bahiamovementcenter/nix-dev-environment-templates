{
  description = "An Organist-based Elixir development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs
    organist = {
      url = "github:nickel-lang/organist";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The Organist modules project.ncl is made of (organist/modules), and
    # packages they use that aren't in Nixpkgs, built with the Nixpkgs above
    dev-templates = {
      url = "github:bahiamovementcenter/nix-dev-environment-templates";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # The development shell is defined in project.ncl
  outputs =
    { organist, dev-templates, ... }@inputs:
    organist.flake.outputsFromNickel ./. inputs {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      # What project.ncl can import from nickel.lock.ncl
      lockFileContents = {
        organist = "${organist}/lib/organist.ncl";
        dev-templates = "${dev-templates}/organist/modules/default.ncl";
      };
    };
}
