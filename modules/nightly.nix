{lib, flake-parts-lib, ...}:
let
  inherit (lib) mkOption types;
  inherit (flake-parts-lib) mkPerSystemOption;
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
          nightly = mkOption {
            type = package;
            description = "The nightly Neovim derivation, with all user configuration baked in";
          };
        };
      };

      config = {
        neovim = {
          nightly = let
            build = config.neovim.build;
          in
            build.wrapper inputs'.neovim-flake.packages.neovim (build.settings);
        };
      };
    });
  };
}
