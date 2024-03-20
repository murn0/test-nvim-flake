{lib, flake-parts-lib, ...}:
let
  inherit (lib) mkOption mkPackageOption types hasSuffix makeBinPath unique;
  inherit (flake-parts-lib) mkPerSystemOption;
  
  mkNeovimNightly = { config, inputs', ... }:
    let
      cfg = config.neovim;
    in
      cfg.wrapper inputs'.neovim-flake.packages.neovim (cfg.settings);
in
{
  options = {
  
    perSystem = mkPerSystemOption ({
      config,
      inputs',
      pkgs,
      ...
    }: {
      options = with types; {
        neovim = {
          mkNeovimNightly = mkOption {
            internal = true;
            type = package;
          };

          nightly = mkOption {
            type = package;
            description = "The nightly Neovim derivation, with all user configuration baked in";
          };
        };
      };

      config = {
        neovim = {
          mkNeovimNightly = mkNeovimNightly {inherit config inputs';};

          nightly = config.neovim.mkNeovimNightly;
        };
      };
    });
  };
}
