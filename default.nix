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
} ''
  mkdir "$out"
  cc -Wall "$source" "$filesProtoObj" -shared -fPIC -o "$out/preload.so"
  # Tests
  LD_PRELOAD="$out/preload.so" python3 -c ${lib.escapeShellArg ''
    """
    >>> import socket
    >>> socket.getprotobyname("tcp")
    6
    >>> socket.getprotobyname("udp")
    17
    >>> socket.getprotobyname("icmp")
    1
    >>> socket.getprotobyname("xxx")
    Traceback (most recent call last):
      ...
    OSError: protocol not found
    >>>
    """
    import doctest
    raise SystemExit(0 if doctest.testmod()[0] == 0 else 1)
  ''}
''
