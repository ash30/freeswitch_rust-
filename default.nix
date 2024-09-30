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
      ref = "refs/heads/nixos-18.09";
      rev = "6a3f5bcb061e1822f50e299f5616a0731636e4e7";
  }) { });

    libc_old = pkgs_old.glibc.overrideAttrs (p:{
       pname = "glibc";
    });

    stdenv_old = (pkgs.overrideCC pkgs.stdenv (pkgs.wrapCCWith {
	  cc = pkgs_old.gcc-unwrapped;
	  bintools = pkgs.wrapBintoolsWith {
	    bintools = pkgs.binutils-unwrapped;
	    libc = libc_old;
	    };
    }));

  pkgs2 = import <nixpkgs> { 
    overlays = [ (import (fetchTarball "https://github.com/oxalica/rust-overlay/archive/2e7ccf572ce0f0547d4cf4426de4482936882d0e.tar.gz")) ];
    config.replaceStdenv = { pkgs, ... }: stdenv_old;
  };

  rustbin = pkgs2.rust-bin.stable.latest.default.override {
	targets = [ "x86_64-unknown-linux-gnu" ];
  };

  rustPlatform = pkgs.makeRustPlatform {
    rustc = rustbin;
    cargo = rustbin;
    stdenv = stdenv_old;
  };
  #fs =  (pkgs.buildPackages.callPackage ./freeswitch { });
in
rustPlatform.buildRustPackage rec {  
  pname = "freeswitch_rs";
  version = "0.1";
  nativeBuildInputs = with pkgs; [ 
    #fs
    rustPlatform.bindgenHook
  ] ++ lib.optionals stdenv.isDarwin [
  ];

  #NIX_CFLAGS_COMPILE="-isystem ${fs.out}/include/freeswitch";

  cargoLock.lockFile = ./Cargo.lock;
  src = pkgs.lib.cleanSource ./.;
}
