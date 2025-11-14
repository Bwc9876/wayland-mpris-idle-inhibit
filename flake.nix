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
            }
          );
        in
        wayland-mpris-idle-inhibit;
    };
}
