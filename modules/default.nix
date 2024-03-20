{lib, flake-parts-lib, ...}:
let
  inherit (lib) mkOption mkPackageOption types;
  inherit (flake-parts-lib) mkPerSystemOption;
in {

  imports = [
    ./build.nix
    ./dependencies.nix
    ./neovim.nix
    ./nightly.nix
  ];

  options = {
    perSystem = mkPerSystemOption ({
      config,
      pkgs,
      ...
    }: {
      options = with types; {
        neovim = {
          package = mkPackageOption pkgs "neovim-unwrapped" {};

          stable = mkOption {
            type = package;
            description = "The stable Neovim derivation, with all user configuration baked in";
          };
        };
      };

      config = {
        neovim = {
          stable = let
            cfg = config.neovim;
            build = config.neovim.build;
          in
            build.wrapper cfg.package (build.settings);

        };
      };
    });
  };
}
