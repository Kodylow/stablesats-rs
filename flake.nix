{
  description = "Stablesats";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    cargo2nix.url = "github:cargo2nix/cargo2nix/release-0.11.0";
  };

  outputs = { self, nixpkgs, flake-utils, cargo2nix }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [cargo2nix.overlays.default];
      };

      rustPkgs = pkgs.rustBuilder.makePackageSet {
        rustVersion = "1.61.0";
        packageFun = import ./Cargo.nix;
      };

      inherit (pkgs) postgresql redis;
      inherit (pkgs.stdenv.lib) callPackage;

      postgres = postgresql.withPackages (p: [ p.postgis ]);
      redis-server = pkgs.redis.override { enableRedis = true; };

      direnv = callPackage (
        { src, ... }: pkgs.stdenv.mkDerivation {
          pname = "direnv";
          inherit src;
          nativeBuildInputs = [ pkgs.go ];
          buildPhase = ''
            make
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp direnv $out/bin
          '';
        }
      ) {
        src = pkgs.fetchFromGitHub {
          owner = "direnv";
          repo = "direnv";
          rev = "v2.30.2";
          sha256 = "0f8z1lzw9v2n1ks6nz2h6xw8kx0v6gmxn6iahyz6rpzfmis9yxv7";
        };
      };

      env = pkgs.buildEnv {
        name = "direnv-env";
        paths = [
          postgres
          redis-server
          direnv
        ];
      };
    in {
      packages = {
        default = env;
      };

      defaultPackage = self.packages.${system}.default;

      devShell = {
        packages = with pkgs; [
          postgresql
          redis
          direnv
          sqlx-cli
          cargo-nextest
          just
        ];
        LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        DIRENV_FILE = ".envrc";
      };
    });
}
