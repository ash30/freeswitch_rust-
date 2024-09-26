{ pkgs ? import <nixpkgs> { 
    overlays = [ 
       # https://github.com/oxalica/rust-overlay/commit/0bf05d8534406776a0fbc9ed8d4ef5bd925b056a
       # Why does this break?
      (import (fetchTarball "https://github.com/oxalica/rust-overlay/archive/2e7ccf572ce0f0547d4cf4426de4482936882d0e.tar.gz"))
    ];
  } 
}:
let
  pkgs_old = (import (builtins.fetchGit {
      name = "glibc_2_18";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/nixos-19.09";
      rev = "b79f64b5eb5fa8ca2f844ddb4d7c186b6c69a293";
  }) { });

    stdenv_old = (pkgs.overrideCC pkgs.stdenv (pkgs.wrapCCWith {
	  cc = pkgs_old.gcc-unwrapped;
	  bintools = pkgs.wrapBintoolsWith {
	    bintools = pkgs.binutils-unwrapped;
	    libc = pkgs_old.glibc;
	    };
    }));

  rustPlatform = pkgs.makeRustPlatform {
    rustc = pkgs.rust-bin.stable.latest.default;
    cargo = pkgs.rust-bin.stable.latest.default;
    stdenv = stdenv_old;
  };
  fs =  (pkgs.buildPackages.callPackage ./freeswitch { });
in
rustPlatform.buildRustPackage rec {  
  pname = "freeswitch_rs";
  version = "0.1";
  nativeBuildInputs = with pkgs; [ 
    fs
    rustPlatform.bindgenHook
  ] ++ lib.optionals stdenv.isDarwin [
  ];

  NIX_CFLAGS_COMPILE="-isystem ${fs.out}/include/freeswitch";

  cargoLock.lockFile = ./Cargo.lock;
  src = pkgs.lib.cleanSource ./.;
}
