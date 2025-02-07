{
  description = "Flake for wayland-mpris-idle-inhibit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    pkgsFor = system: import nixpkgs {inherit system;};
    common = pkgs:
      with pkgs; [
        gcc
        pkg-config
        dbus
      ];
  in {
    packages = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.rustPlatform.buildRustPackage rec {
        pname = "wayland-mpris-idle-inhibit";
        version = "0.1.0";

        src = with pkgs.lib.fileset;
          toSource {
            root = ./.;
            fileset = unions [
              ./src
              ./Cargo.toml
              ./Cargo.lock
            ];
          };

        useFetchCargoVendor = true;

        cargoLock = {
          lockFile = ./Cargo.lock;
        };

        nativeBuildInputs = common pkgs;
        buildInputs = common pkgs;

        doCheck = false;

        meta = with pkgs.lib; {
          description = "A small utility to inhibit idle on wayland for mpris clients";
          homepage = "https://github.com/Bwc9876/wayland-mpris-idle-inhibit";
          license = licenses.gpl3;
          maintainers = with maintainers; [bwc9876];
        };
      };
    });
    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.mkShell {
        name = "mpris-idle-inhibit-dev-shell";
        buildInputs = with pkgs;
          [
            rustc
            cargo
            clippy
            rustfmt
          ]
          ++ common pkgs;
        shellHook = '''';
      };
    });
    formatter = forAllSystems (system: (pkgsFor system).alejandra);
  };
}
