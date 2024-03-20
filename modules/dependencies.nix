{lib, flake-parts-lib, ...}:
let
  inherit (lib) mkOption types hasSuffix;
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
  
    perSystem = mkPerSystemOption ({
      config,
      pkgs,
      ...
    }: let
        cfg = config.neovim.build;
    in {
      options = with types; {
        neovim = {
          build = {
            runtimeDeps = mkOption {
              type = listOf package;
              default = [ ];
              description = "Extra packages to be made available to neovim";
            };
          };
        };
      };

      config = {
        neovim = {
          build = {
            runtimeDeps = with pkgs; [
              git
            ];
          };
        };
      };
    });
  };
}
