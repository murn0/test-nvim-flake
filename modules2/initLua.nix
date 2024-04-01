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
          initLua = {
            node = mkOption {
              type = package;
            };

            final = mkOption {
              type = package;
              default = pkgs.writeTextFile {
                name = "init.lua";
                text = ''
                  -- Generated by Nix (via github:willruggiano/neovim.nix)
                  ${builtins.readFile "${config.neovim.configDir}/init.lua"}
                '';
              };
            };
          };
        };
      };

      # config = {
      #   neovim = {
      #     
      #   };
      # };
    });
  };
}
