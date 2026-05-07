{
  description = "Wayland Mpris Idle Inhibit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flakelight.url = "github:nix-community/flakelight";
    flakelight.inputs.nixpkgs.follows = "nixpkgs";
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flakelight
    , crane
    ,
    }:
    flakelight ./. {
      inherit inputs;
      pname = "wayland-mpris-idle-inhibit";
      devShell =
        pkgs:
        (crane.mkLib pkgs).devShell {
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [
            pkgs.dbus
            pkgs.pkg-config
          ];
        };
      homeModule =
        { config
        , lib
        , pkgs
        , ...
        }:
        {
          options.services.wayland-mpris-idle-inhibit = {
            enable = lib.mkEnableOption "inhibitting idle when MPRIS media is playing";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.system}.default;
            };
            ignorePlayers = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "List of players to ignore the status of, these players will not inhibit idle";
              default = [ ];
              example = [
                "kdeconnect"
                "playerctld"
              ];
            };
            pollInterval = lib.mkOption {
              type = lib.types.number;
              description = "How often to poll MPRIS for player information in seconds, recommended to set this below your timeout";
              default = 10;
            };
          };

          config =
            let
              conf = config.services.wayland-mpris-idle-inhibit;
            in
            lib.mkIf conf.enable {
              systemd.user.services.wayland-mpris-idle-inhibit =
                let
                  target = config.wayland.systemd.target;
                in
                {
                  Install = {
                    WantedBy = [ target ];
                  };

                  Unit = {
                    ConditionEnvironment = "WAYLAND_DISPLAY";
                    Description = "Inhibit idle when MPRIS media is playing";
                    After = [ target ];
                    PartOf = [ target ];
                  };

                  Service = {
                    ExecStart =
                      let
                        ignores = lib.join " " (builtins.map (s: "--ignore ${lib.escapeShellArg s}") conf.ignorePlayers);
                        delay = "--poll-interval ${builtins.toString conf.pollInterval}";
                      in
                      "${lib.getExe conf.package} ${delay} ${ignores}";
                    Restart = "on-failure";
                    RestartSec = "10";
                  };
                };
            };
        };
      package =
        { rustPlatform
        , dbus
        , nushell
        , pkg-config
        , fetchFromGitHub
        , lib
        , pkgs
        ,
        }:
        let
          craneLib = crane.mkLib pkgs;
          src = ./.;
          commonArgs = {
            inherit src;
            strictDeps = true;
            nativeBuildInputs = [
              pkg-config
            ];
            buildInputs = [
              dbus
            ];
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          wayland-mpris-idle-inhibit = craneLib.buildPackage (
            commonArgs
            // {
              inherit cargoArtifacts;

              meta = with lib; {
                mainProgram = "wayland-mpris-idle-inhibit";
                description = "A program that enables the wl-roots idle inhibitor when MPRIS reports any player";
                license = licenses.mit;
                homepage = "https://tangled.org/did:plc:x7tlupbnqot7nu6udnffnv4h/wayland-mpris-idle-inhibit";
              };
            }
          );
        in
        wayland-mpris-idle-inhibit;
    };
}
