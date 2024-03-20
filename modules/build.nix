{lib, flake-parts-lib, ...}:
let
  inherit (lib) mkOption mkPackageOption makeBinPath optional unique types hasSuffix;
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
            wrapper = mkOption {
              type = attrs;
              default = pkgs.wrapNeovimUnstable;
              description = "wrapper";
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
              description = "neovim config";
            };

            settings = mkOption {
              type = attrs;
              default = cfg.neovimConfig // {
                wrapperArgs = cfg.neovimConfig.wrapperArgs ++ cfg.wrapperArgs;
              };
            };

            wrapperArgs = mkOption {
              type = listOf str;
              default = [
                "--prefix"
                "PATH"
                ":"
                "${makeBinPath (unique cfg.runtimeDeps)}"
              ]
              ++ optional (config.neovim.extraPackages != []) [
                "--prefix"
                "PATH"
                ":"
                "${makeBinPath (unique config.neovim.extraPackages)}"
              ]
              ++ [
                "--add-flags"
                ''--cmd "lua vim.opt.runtimepath:append(\"${config.neovim.configDir}\")"''
                "--add-flags"
                "--clean"
                "--add-flags"
                ''-u ${config.neovim.configDir}/init.lua''
              ];
            };
          };
        };
      };
    });
  };
}
