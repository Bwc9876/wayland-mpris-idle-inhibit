{
  description = "Nushell Plugin DBUS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flakelight.url = "github:nix-community/flakelight";
    flakelight.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flakelight,
  }:
    flakelight ./. {
      inherit inputs;
      pname = "wayland-mpris-idle-inhibit";
      package = {
        rustPlatform,
        dbus,
        nushell,
        pkg-config,
        fetchFromGitHub,
        lib,
      }:
        rustPlatform.buildRustPackage {
          pname = "wayland-mpris-idle-inhibit";
          version = "0.1.0";

          src = ./.;

          cargoLock.lockFile = ./Cargo.lock;

          nativeBuildInputs = [
            pkg-config
          ];

          buildInputs = [
            dbus
          ];

          meta = with lib; {
            description = "A program that enables the wl-roots idle inhibitor when MPRIS reports any player";
            license = licenses.mit;
            homepage = "https://github.com/Bwc9876/wayland-mpris-idle-inhibit";
          };
        };
    };
}
