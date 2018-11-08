{ pkgs ? import <nixpkgs> { config = {}; overlays = []; } }:
let
  inherit (pkgs)
    bison
    glibc
    iana-etc
    lib
    python3
    runCommandCC
    stdenv
    ;
in

runCommandCC "getprotobyname" {
  # This is the compiled object file for nss/nss_files/files-proto.c, which we
  # use to get the internal function _nss_files_getprotobyname_r().
  filesProtoObj = stdenv.mkDerivation {
    name = "nss-files-proto-${glibc.version}.o";
    inherit (glibc) src;

    nativeBuildInputs = [ bison ];

    postPatch = ''
      sed -i -e '/#define *DATAFILE/ {
        c #define DATAFILE "${iana-etc}/etc/protocols"
      }' nss/nss_files/files-XXX.c
    '';

    configurePhase = ''
      mkdir ../build
      cscript="$PWD/configure"
      (cd ../build && "$cscript" --prefix="$PWD")
    '';

    buildFlags = [ "-C" "../build" ];
    enableParallelBuilding = true;

    installPhase = "install -vD -m 0644 ../build/nss/files-proto.os \"$out\"";
  };

  source = ./preload.c;

  # Needed for tests as I wanted to use a different implementation than C to
  # verify whether it's working correctly.
  nativeBuildInputs = [ python3 ];

  outputs = ["out" "hook"];
} ''
  mkdir -p $out/lib $hook/nix-support

  cc -Wall "$source" "$filesProtoObj" -shared -fPIC -o "$out/lib/nix-ld-sandbox.so"

  cat <<SETUP_HOOK > "$hook/nix-support/setup-hook"
  export LD_PRELOAD=$out/lib/nix-ld-sandbox.so
  SETUP_HOOK

  # Run tests
  (
    source "$hook/nix-support/setup-hook"
    python3 ${./test.py}
  )
''
