{
  description = "WebKitGTK 4.1 with LibWebRTC from an upstream GTK nightly";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    webkit = {
      url = "git+https://github.com/WebKit/WebKit.git?ref=refs/heads/main&shallow=1";
      flake = false;
    };
  };

  outputs = { nixpkgs, webkit, ... }:
    let
      overlay = final: prev: {
        webkitgtk_4_1 = (prev.webkitgtk_4_1.override {
          enableExperimental = true;
        }).overrideAttrs (old: {
          pname = "webkitgtk-webrtc";
          version = "0-unstable-${builtins.substring 0 8 webkit.lastModifiedDate}-${webkit.shortRev}";
          src = webkit;

          patches = [ (builtins.head old.patches) ];
          cmakeFlags = old.cmakeFlags ++ [
            "-DENABLE_MEDIA_STREAM=ON"
            "-DENABLE_WEB_RTC=ON"
            "-DUSE_VULKAN=OFF"
          ];
          postPatch = old.postPatch + ''
            test -d Source/ThirdParty/libwebrtc/Source
          '';

          meta = old.meta // {
            description = "WebKitGTK 4.1 with LibWebRTC enabled";
          };
        });
      };
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ overlay ];
      };
    in {
      overlays.default = overlay;
      packages.x86_64-linux.default = pkgs.webkitgtk_4_1;
    };
}
