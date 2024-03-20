{lib, flake-parts-lib, ...}:
let
  inherit (lib) makeBinPath mkOption optional types unique hasSuffix;
  inherit (flake-parts-lib) mkPerSystemOption;

  mkNeovimEnv = {config, inputs', pkgs, ...}:
  # {
  #   nightly ? false,
  # }:
  let
    cfg = config.neovim;

    # neovimBuildPackage =
    #   # options.packageが設定されている場合はnightlyの設定を無視する
    #   if cfg.package == null then
    #     if nightly == true then
    #       inputs'.neovim-flake.packages.neovim
    #     else
    #       pkgs.neovim-unwrapped
    #   else
    #     cfg.package;

    runtimeDeps = with pkgs; [
      # Tree sitter
      git
    ];


    # configDir = pkgs.symlinkJoin {
    #   name = "neovim-config-dir";
    #   paths = (builtins.path {
    #     name = "neovim-config-dir-src";
    #     path = ./..;
    #     filter = path: type: type == "directory" || hasSuffix ".lua" path;
    #   });
    # };

    neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
      withPython3 = true;
      withNodeJs = true;
      withRuby = true;

      # init.luaのファイル位置を指定するためにfalseに設定
      # (https://github.com/NixOS/nixpkgs/blob/0d17fd9524aae7a96bc107b002c6c3781017e9c2/pkgs/applications/editors/neovim/wrapper.nix#L30-L34)
      wrapRc = false;
    };
    
    settings = neovimConfig // {
      wrapperArgs = neovimConfig.wrapperArgs
        ++ [
          "--prefix"
          "PATH"
          ":"
          "${makeBinPath (unique runtimeDeps)}"
        ]
        ++ optional (cfg.extraPackages != []) [
          "--prefix"
          "PATH"
          ":"
          "${makeBinPath (unique cfg.extraPackages)}"
        ]
        ++ [
          "--add-flags"
          ''--cmd "lua vim.opt.runtimepath:append(\"${cfg.configDir}\")"''
          "--add-flags"
          "--clean"
          "--add-flags"
          ''-u ${cfg.configDir}/init.lua''
        ];
    };

  in
    # pkgs.wrapNeovimUnstable neovimBuildPackage (settings);
    cfg.wrapper cfg.package (settings);

in {

  imports = [
    ./packages.nix
    ./mkNeovim.nix
    ./nightly.nix
  ];

  options = {
    perSystem = mkPerSystemOption ({config, inputs', pkgs, ...}: {
      options = with types; {
        neovim = {
          extraPackages = mkOption {
            type = listOf package;
            default = [ ];
            example = "[ pkgs.git ]";
            description = "Extra packages to be made available to neovim";
          };

          # package = mkOption {
          #   type = nullOr package;
          #   default = null;
          #   description = "The package to use for neovim.";
          # };

          stable = mkOption {
            type = package;
            description = "The stable Neovim derivation, with all user configuration baked in";
          };

          # nightly = mkOption {
          #   type = package;
          #   description = "The nightly Neovim derivation, with all user configuration baked in";
          # };
        };
      };

      config = {
        neovim = {
          # stable = mkNeovimEnv {inherit config inputs' pkgs;};
          stable = config.neovim.mkNeovim;
          # package = inputs'.neovim-flake.packages.neovim;
          # nightly = mkNeovimEnv {inherit config inputs' pkgs;} { nightly = true; };
        };
      };
    });
};
}
