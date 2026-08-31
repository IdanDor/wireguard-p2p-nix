# Run nix-build build3.nix

{ pkgs ? import <nixpkgs> {} }:

let
  opendht = pkgs.callPackage ./opendht.nix { };
  
  p2p-tunnler = pkgs.fetchFromGitHub {
    owner = "IdanDor";
    repo = "p2p-tunnler";
    rev = "master";
    hash = "sha256-vEyVHRLaQWcPuCj+i6kw2lFXuqiGOnB5hoW6nyVi24w=";
  };

  customBuildRustCrateForPkgs = pkgs: pkgs.buildRustCrate.override {
    defaultCrateOverrides = pkgs.defaultCrateOverrides // {
      opendht = attrs: {
        # This means build time, unlike buildInputs which is runtime.
        buildInputs = [
          opendht
          pkgs.pkg-config  # required for lookup.
          # required by opendht
          pkgs.gnutls
          pkgs.msgpack-cxx
          pkgs.fmt.dev
        ];
        PKG_CONFIG_PATH = "${opendht}/lib/pkgconfig";
      };
      p2p-tunnler = attrs: {
        buildInputs = [
          pkgs.fmt.dev
          pkgs.openssl.dev
          pkgs.nettle
          pkgs.boost
          pkgs.libargon2
          pkgs.jsoncpp
          pkgs.http-parser
        ];
      };
    };
  };
  # Generate from devenv shell using: `crate2nix generate` in ./wireguard-p2p
  crate = pkgs.callPackage "${p2p-tunnler}/Cargo.nix" {
    buildRustCrateForPkgs = customBuildRustCrateForPkgs;
  };
in
  crate.rootCrate.build
