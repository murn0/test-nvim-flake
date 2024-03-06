{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-flake = { url = "github:neovim/neovim?dir=contrib"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      perSystem = { config, inputs', lib, pkgs, system, ... }: {
        # _module.args.pkgs = import inputs.nixpkgs {
        #   inherit system;
        #   overlays = [
        #     inputs.neovim-nightly-overlay.overlay
        #   ];
        # };


        # formatter = pkgs.alejandra;

        packages.default = config.packages.neovim;
        packages.neovim = let
          neovim-unwrapped = inputs'.neovim-flake.packages.neovim;

          config-dir = pkgs.symlinkJoin {
            name = "neovim-config-dir-src";
            paths = (builtins.path {
              name = "neovim-config-dir-src";
              path = ./.;
              filter = path: type: type == "directory" || lib.hasSuffix ".lua" path;
            });
          };

          neovim-with-plugins = pkgs.wrapNeovimUnstable neovim-unwrapped (
            (pkgs.neovimUtils.makeNeovimConfig {
                withPython3 = false;
                withNodeJs = true;
                withRuby = false; 
            }) // {
              wrapperArgs = "";
              wrapRc = false;
            });
        in
        pkgs.stdenvNoCC.mkDerivation {
          name = "neovim";

          buildInputs = [
            pkgs.makeWrapper
          ];

          dontBuild = true;
          dontUnpack = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            makeWrapper ${neovim-with-plugins}/bin/nvim $out/bin/nvim \
              --add-flags "--cmd 'lua vim.opt.runtimepath:append(\"${config-dir}\")'" \
              --add-flags "--clean" \
              --add-flags "-u ${config-dir}/init.lua"

            runHook postInstall
          '';

          meta = {
            mainProgram = "nvim";
          };
        };

        overlayAttrs = {
          inherit (config.packages) neovim;
        };

      };
};
}
