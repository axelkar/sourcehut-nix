{}:
#import ./sourcehut (builtins.removeAttrs (import <nixpkgs> {}) [ "system" ])
let
  f = import ./sourcehut;
  pkgs = import <nixpkgs> {};
  fargs = pkgs.lib.functionArgs f; # builtins.functionArgs might work too
in
  {
    sourcehut = f (builtins.intersectAttrs fargs pkgs);
  }
