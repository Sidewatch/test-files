{
  description = "Inventory service: dev shell and package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = "1.4.0";
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "inventory";
          inherit version;
          src = ./.;
          buildInputs = [ pkgs.sqlite ];
          buildPhase = "cc -O2 -o inventory src/*.c -lsqlite3";
          installPhase = ''
            mkdir -p $out/bin
            cp inventory $out/bin/
          '';
          meta = with pkgs.lib; { license = licenses.mit; platforms = platforms.unix; };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ sqlite gnumake clang-tools ];
          shellHook = "echo 'inventory ${version} dev shell'";
        };
      });
}
