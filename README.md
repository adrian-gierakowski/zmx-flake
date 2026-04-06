# zmx-flake

Nix flake for [zmx](https://github.com/neurosnap/zmx).

This repo builds zmx from source with [zig2nix](https://github.com/Cloudef/zig2nix). It exists because zmx is not in nixpkgs yet due to a [Zig compiler bug](https://codeberg.org/ziglang/zig/issues/30191).

## Packages

- `zmx` — default package, pinned to the latest upstream tagged release
- `zmx-main` — package built from upstream `main`

Use `zmx` unless you specifically want unreleased changes.

## Install

Add the flake input:

```nix
inputs.zmx-flake.url = "github:thrawny/zmx-flake";
```

Then use one of these packages:

### NixOS

```nix
environment.systemPackages = [
  zmx-flake.packages.${pkgs.system}.zmx
];
```

### Home Manager

```nix
home.packages = [
  zmx-flake.packages.${pkgs.system}.zmx
];
```

To use upstream `main` instead, replace `zmx` with `zmx-main`.

## Cache

The binary cache is enabled by default by the provided NixOS module.

If you want to opt out:

```nix
{
  zmx-flake.cache.enable = false;
}
```

## Supported platforms

- `x86_64-linux`
- `aarch64-linux`
