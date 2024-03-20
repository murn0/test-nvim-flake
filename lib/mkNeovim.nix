{lib, flake-parts-lib, ...}:
let
  inherit (lib) mkOption mkPackageOption types hasSuffix makeBinPath unique;
  inherit (flake-parts-lib) mkPerSystemOption;

  mkNeovim = { config, pkgs, ... }:
    let
      cfg = config.neovim;
    in
      cfg.wrapper cfg.package (cfg.settings);
in
{
  options = {
  
    perSystem = mkPerSystemOption ({
      config,
      pkgs,
      ...
    }: {
      options = with types; {
        neovim = {
          mkNeovim = mkOption {
            internal = true;
            type = package;
          };
        };
      };

      config = {
        neovim = {
          mkNeovim = mkNeovim {inherit config pkgs;};
        };
      };
    });
  };
}
