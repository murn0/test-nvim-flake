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
          extraPackages = mkOption {
            type = listOf package;
            default = [ ];
            example = "[ pkgs.git ]";
            description = "Extra packages to be made available to neovim";
          };

          path = mkOption {
            type = path;
            default = ./..;
          };

          configDir = mkOption {
            type = package;
            default = pkgs.symlinkJoin {
              name = "neovim-config-dir";
              paths = (builtins.path {
                name = "neovim-config-dir-src";
                path = config.neovim.path;
                filter = path: type: type == "directory" || hasSuffix ".lua" path;
              });
            };
          };
        };
      };
    });
  };
}
