{ pkgs ? import <nixpkgs> { 
    overlays = [ 
       # https://github.com/oxalica/rust-overlay/commit/0bf05d8534406776a0fbc9ed8d4ef5bd925b056a
       # Why does this break?
      (import (fetchTarball "https://github.com/oxalica/rust-overlay/archive/2e7ccf572ce0f0547d4cf4426de4482936882d0e.tar.gz"))
    ];

    config.replaceStdenv = { pkgs }: pkgs.stdenv.override {
      cc = pkgs.overrideCC pkgs.wrapCCWith {
        cc = pkgs.gcc8.cc;
        bintools = pkgs.wrapBintoolsWith {
          bintools = pkgs.binutils-unwrapped;
          libc = (import (builtins.fetchTarball { url = "https://github.com/nixos/nixpkgs/archive/6ed8a76ac64c88df0df3f01b536498983ad5ad23.tar.gz"; sha256 = "0ymc0g3adrnil4fbrirlhbpjlgpl77zrjbsfjs445ms3z3p7mb1d"; }) {}).glibc;
        };
      };
    };
  } 
}:
let
  glibc_2_18 = (import (builtins.fetchGit {
      name = "glibc_2_18";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/nixpkgs-unstable";
      rev = "ab6453c483e406b07c63503bca5038838c187ecf";
  }) { }).glibc;

  stdenv_old = pkgs.stdenv.override { 
	cc = pkgs.overrideCC pkgs.stdenv (pkgs.wrapCCWith {
	  cc = pkgs.gcc8.cc;
	  bintools = pkgs.wrapBintoolsWith {
	    bintools = pkgs.binutils-unwrapped;
	    libc = glibc_2_18;
	    };
	});
    };


  rustPlatform = pkgs.makeRustPlatform {
    rustc = pkgs.rust-bin.stable.latest.default;
    cargo = pkgs.rust-bin.stable.latest.default;
    stdenv =  stdenv_old;
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
