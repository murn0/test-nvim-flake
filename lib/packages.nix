{lib, flake-parts-lib, ...}:
let
  inherit (lib) mkOption mkPackageOption types hasSuffix;
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
  
    perSystem = mkPerSystemOption ({
      config,
      pkgs,
      ...
    }: let
        cfg = config.neovim;
    in {
      options = with types; {
        neovim = {
          package = mkPackageOption pkgs "neovim-unwrapped" {};

          configDir = mkOption {
            type = package;
            default = pkgs.symlinkJoin {
              name = "neovim-config-dir";
              paths = (builtins.path {
                name = "neovim-config-dir-src";
                path = ./..;
                filter = path: type: type == "directory" || hasSuffix ".lua" path;
              });
            };
          };

          neovimConfig = mkOption {
            type = attrs;
            default = pkgs.neovimUtils.makeNeovimConfig {
              withPython3 = true;
              withNodeJs = true;
              withRuby = true;

              # init.luaのファイル位置を指定するためにfalseに設定
              # https://github.com/NixOS/nixpkgs/blob/0d17fd9524aae7a96bc107b002c6c3781017e9c2/pkgs/applications/editors/neovim/wrapper.nix#L30-L34
              wrapRc = false;
            };
          };

          wrapperArgs = mkOption {
            type = listOf str;
            default = [
              "--add-flags"
              ''--cmd "lua vim.opt.runtimepath:append(\"${cfg.configDir}\")"''
              "--add-flags"
              "--clean"
              "--add-flags"
              ''-u ${cfg.configDir}/init.lua''
            ];
          };

          settings = mkOption {
            type = attrs;
            default = cfg.neovimConfig // {
              wrapperArgs = cfg.neovimConfig.wrapperArgs ++ cfg.wrapperArgs;
            };
          };

          wrapper = mkOption {
            type = attrs;
            default = pkgs.wrapNeovimUnstable;
            description = "wrapper";
          };
        };
      };
    });
  };
}
