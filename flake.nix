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
      devShell = pkgs: (crane.mkLib pkgs).devShell {
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.dbus pkgs.pkg-config ];
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
                homepage = "https://github.com/Bwc9876/wayland-mpris-idle-inhibit";
              };
            }
          );
        in
        wayland-mpris-idle-inhibit;
    };
}
