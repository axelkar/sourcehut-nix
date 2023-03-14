{
  description = "sourcehut NixOS module";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }:
    {
      nixosModules = {
        sourcehut = import ./module.nix;
      };
    };
}
