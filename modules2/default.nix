{lib, flake-parts-lib, ...}:
with lib; let
  inherit (flake-parts-lib) mkPerSystemOption;
in {

  imports = [
  ];

  options = {
    perSystem = mkPerSystemOption ({
      config,
      pkgs,
      ...
    }: {
      options = with types; let
        cfg = config.neovim;
      in {
        neovim = {
          package = mkPackageOption pkgs "neovim-unwrapped" {};

          final = mkOption {
            type = package;
            default = let
              settings = pkgs.neovimUtils.makeNeovimConfig {
                withNodeJs = true;
              };
            in
              pkgs.wrapNeovimUnstable cfg.package (settings // {
                wrapperArgs = settings.wrapperArgs
                ++ optionals (cfg.env != {}) (
                  flatten
                    (mapAttrsToList
                      (name: value: [ "--set" "${name}" "${value}" ])
                      cfg.env)
                )
                ++ optionals (cfg.dependencies != []) [
                  "--prefix" "PATH" ":" "${makeBinPath cfg.dependencies}"
                ]
                ++ [
                  "--add-flags"
                  ''--cmd "set runtimepath^=${cfg.configDir}"''
                  "--add-flags"
                  ''-u ${cfg.initLua.final}''
                ];
              }                );
          };

          env = mkOption {
            # TODO:direnvなどでenvを上書きできるか試す
            type = attrs;
            default = {
              NEOVIM_VAR = "this is neovim var???";
              NEOVIM_VAR2 = "this is neovim var2???";
            };
            description = "Environment variables to bake into the final Neovim derivation's runtime";
          };

          dependencies = mkOption {
            type = listOf package;
            default = [
              pkgs.git
              # pkgs.nodejs
            ];
            description = "Additional binaries to bake into the final Neovim derivation's PATH";
          };

          configDir = mkOption {
            #TODO: internalがONでもconfigDirPathを変更できるかチェック
            internal = true;
            type = package;
            default = pkgs.symlinkJoin {
              name = "neovim-config-dir";
              paths = (builtins.path {
                name = "neovim-config-dir-src";
                path = cfg.configPath;
                filter = path: type: type == "directory" || hasSuffix ".lua" path;
              });
            };
          };

          configPath = mkOption {
            type = path;
            default = ./..;
          };

          initLua = {
            preConfig = mkOption {
              type = types.lines;
              default = "";
              description = "Extra contents for init.lua before everything else";
            };

            postConfig = mkOption {
              type = types.lines;
              default = "";
              description = "Extra contents for init.lua before everything else";
            };

            final = mkOption {
              internal = true;
              type = package;
              default = pkgs.writeTextFile {
                name = "init.lua";
                text = ''
                  -- preConfig
                  ${cfg.initLua.preConfig}

                  -- Load ${cfg.configDir}/init.lua
                  ${builtins.readFile "${cfg.configDir}/init.lua"}

                  -- postConfig
                  ${cfg.initLua.postConfig}
                '';
              };
            };
          };
        };
      };
    });
  };
}
