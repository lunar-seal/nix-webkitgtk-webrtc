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
          buildInputs = old.buildInputs ++ [ final.alsa-lib final.libevent final.libopus final.libpulseaudio ];
          cmakeFlags = old.cmakeFlags ++ [
            "-DENABLE_MEDIA_STREAM=ON"
            "-DENABLE_WEB_RTC=ON"
            "-DUSE_VULKAN=OFF"
          ];
          postPatch = old.postPatch + ''
            test -d Source/ThirdParty/libwebrtc/Source
            substituteInPlace Source/ThirdParty/libwebrtc/Source/webrtc/modules/audio_device/linux/alsasymboltable_linux.cc \
              --replace-fail '"libasound.so.2"' '"${final.lib.getLib final.alsa-lib}/lib/libasound.so.2"'
            substituteInPlace Source/ThirdParty/libwebrtc/Source/webrtc/modules/audio_device/linux/pulseaudiosymboltable_linux.cc \
              --replace-fail '"libpulse.so.0"' '"${final.lib.getLib final.libpulseaudio}/lib/libpulse.so.0"'
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
