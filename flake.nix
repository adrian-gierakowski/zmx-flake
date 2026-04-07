{
  description = "Nix flake for zmx - session persistence for terminal processes";

  inputs = {
    zig2nix.url = "github:adrian-gierakowski/zig2nix/add-flake-compat-and-overlay";
    zmx-src = {
      url = "github:neurosnap/zmx/v0.4.2";
      flake = false;
    };
    zmx-src-main = {
      url = "github:neurosnap/zmx";
      flake = false;
    };
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
  };

  outputs =
    {
      self,
      zig2nix,
      zmx-src,
      zmx-src-main,
      ...
    }:
    let
      inherit (zig2nix.inputs) flake-utils nixpkgs;

      mkZmx =
        pkgs: env: src:
        let
          unwrapped = env.package {
            inherit src;
            zigBuildFlags = [ "-Doptimize=ReleaseSafe" ];
            zigPreferMusl = pkgs.stdenv.hostPlatform.isLinux;
            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isDarwin (
              with pkgs.apple-sdk.frameworks;
              [
                CoreGraphics
                CoreVideo
                CoreText
                IOKit
                Cocoa
                AppKit
                QuartzCore
                Security
                CoreFoundation
                Metal
                MetalKit
              ]
            );
          };
        in
        pkgs.runCommand "zmx-${unwrapped.version}" { nativeBuildInputs = [ pkgs.installShellFiles ]; }
          ''
            mkdir -p $out/bin
            ln -s ${unwrapped}/bin/zmx $out/bin/zmx

            echo '#compdef zmx' > _zmx
            $out/bin/zmx completions zsh >> _zmx
            installShellCompletion --zsh _zmx

            $out/bin/zmx completions bash > zmx.bash
            installShellCompletion --bash zmx.bash

            $out/bin/zmx completions fish > zmx.fish
            installShellCompletion --fish zmx.fish
          '';

      cacheModule =
        { config, lib, ... }:
        {
          options.zmx-flake.cache.enable = lib.mkEnableOption "the zmx binary cache" // {
            default = true;
          };
          config = lib.mkIf config.zmx-flake.cache.enable {
            nix.settings = {
              substituters = [ "https://zmx.cachix.org" ];
              trusted-public-keys = [ "zmx.cachix.org-1:9E7zdDiSiG9PnSl8RFHbZ3AW2NmIy/7SPK9rRwed7r4=" ];
            };
          };
        };
    in
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
            ];
          };
        in
        {
          packages = {
            inherit (pkgs) zmx zmx-main;
            default = pkgs.zmx;
          };

          apps.default = {
            type = "app";
            program = "${pkgs.zmx}/bin/zmx";
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              nixfmt
              statix
              just
            ];
          };

          formatter = pkgs.nixfmt;
        }
      )
    // {
      overlays.default =
        final: prev:
        let
          zmx2nix = zig2nix.overlays.default final prev;
          env = zmx2nix.zig-env {
            zig = zmx2nix.zigv."0_15_2";
          };
        in
        {
          zmx = mkZmx final env zmx-src;
          zmx-main = mkZmx final env zmx-src-main;
        };

      nixosModules.default = cacheModule;
      nixosModules.cache = cacheModule;
    };
}
