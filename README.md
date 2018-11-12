# ld-getby - `/etc/protocols` for the nix sandbox

*STATUS*: deprecated! it turns out nixpkgs already includes libredirect which
is a more generic solution to this problem. And is also supported on Darwin
now.

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org) - [![Build Status](https://travis-ci.com/nix-community/ld-getby.svg?branch=master)](https://travis-ci.com/nix-community/ld-getby)

This project providers a `LD_PRELOAD` library that intercepts
`getprotobyname()` calls to load the protocols list from a different source
than `/etc/protocols`.

It has been written with Nix as a target but could potentially be used in
other places.

## Problem statement

In the Nix build sandbox, `/etc/protocols` is not available so any call to
`getprotobyname()` would fail with for example:

    does not exist (no such protocol name: tcp)

This especially happens with Haskell programs as the stdlib network tends to
make these calls (in case the definition of `tcp` would change...).

    ConnectionFailure Network.BSD.getProtocolByName: does not exist (no such protocol name: tcp)

Instead of patching the glibc to change that hard-coded location we provide a
library that intecepts that call using the `LD_PRELOAD` mechanism and sources
the protocols list from another location provided at compile time.

## Example Nix usage

```diff
    runCommand "requirements.nix" {
-      nativeBuildInputs = [ pipenv2nix ];
-      # Haskell needs /etc/protocols at runtime :/
-      __noChroot = true;
+      nativeBuildInputs = [ pipenv2nix ld-getby.hook cacert ];
 
       # pipenv2nix needs access to the network
       outputHash = pipenvSha256;
       outputHashAlgo = "sha256";
       outputHashMode = "flat";
     } ''
+      export SYSTEM_CERTIFICATE_PATH="${cacert}/etc/ssl/certs/ca-bundle.crt"
       pipenv2nix --path ${src} ${flags} > $out
     '';
```

## Future

This library could potentially be extended to the other getXXbyYY nss calls.

## LICENSE

MIT - 2018 aszlig and contributors
