# nix-ld-sandbox - replace impure thoughts^Wactions

The Nix sandbox doesn't provide `/etc/protocols`, which means that
`getprotobyname()` calls would fail because that path is hard-coded.

This project provides a shared library that can be loaded via `LD_PRELOAD`
that replaces that call. This library should be usable in other environments.

## LICENSE

MIT - 2018 aszlig and contributors

