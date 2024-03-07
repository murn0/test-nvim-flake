{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    neovim-flake = { url = "github:neovim/neovim?dir=contrib"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      perSystem = { config, inputs', lib, pkgs, system, ... }:
      let
        runtimeDeps = with pkgs; [
          # Tree sitter
          git
        ];

        configDir = pkgs.symlinkJoin {
          name = "neovim-config-dir";
          paths = (builtins.path {
            name = "neovim-config-dir-src";
            path = ./.;
            filter = path: type: type == "directory" || lib.hasSuffix ".lua" path;
          });
        };

        cfg = let
          neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
            withPython3 = false;
            withNodeJs = true;
            withRuby = false;
            wrapRc = false;
          };
        in 
          neovimConfig // {
            wrapperArgs = 
              neovimConfig.wrapperArgs ++
              [
                "--prefix"
                "PATH"
                ":"
                "${lib.makeBinPath runtimeDeps}"
              ] ++
              [
                "--add-flags"
                ''--cmd "lua vim.opt.runtimepath:append(\"${configDir}\")"''
                "--add-flags"
                "--clean"
                "--add-flags"
                ''-u ${configDir}/init.lua''
              ];
          };
      in
      {
        packages.default = config.packages.neovim;
        packages.neovim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (cfg);
        packages.nightly = pkgs.wrapNeovimUnstable inputs'.neovim-flake.packages.neovim (cfg);

        overlayAttrs = {
          inherit (config.packages) neovim nightly;
        };

      };
    };
}
