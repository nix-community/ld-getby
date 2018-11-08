# nix-ld-sandbox - replace impure thoughts^Wactions

The Nix sandbox doesn't provide `/etc/protocols`, which means that
`getprotobyname()` calls would fail because that path is hard-coded.

This project provides a shared library that can be loaded via `LD_PRELOAD`
that replaces that call. This library should be usable in other environments.

## Example usage

```diff
    runCommand "requirements.nix" {
-      nativeBuildInputs = [ pipenv2nix ];
-      # Haskell needs /etc/protocols at runtime :/
-      __noChroot = true;
+      nativeBuildInputs = [ pipenv2nix nix-ld-sandbox.hook cacert ];
 
       # pipenv2nix needs access to the network
       outputHash = pipenvSha256;
       outputHashAlgo = "sha256";
       outputHashMode = "flat";
     } ''
+      export SYSTEM_CERTIFICATE_PATH="${cacert}/etc/ssl/certs/ca-bundle.crt"
       pipenv2nix --path ${src} ${flags} > $out
     '';
```

## LICENSE

MIT - 2018 aszlig and contributors

