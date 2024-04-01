{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    
    neovim-flake = { url = "github:neovim/neovim?dir=contrib"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { flake-parts, self, ... } @ inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = ["aarch64-darwin" "x86_64-linux"];
      
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
        # ./modules
        ./modules2
      ];

      # flake = {
      #   flakeModule = {
      #     imports = [./lib/module.nix];
      #   };
      # };

      perSystem = { config, pkgs, ... }: {

        packages = {
          default = config.packages.final;
          final = config.neovim.final;
        };

        overlayAttrs = {
          inherit (config.packages) default final;
        };

        devShells.default = pkgs.mkShell {
          name = "neovim.nix";
          packages = [
            config.neovim.final
          ];
        };

      };
};
}
