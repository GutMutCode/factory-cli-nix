final: prev:
let
  stdenv = prev.stdenv;
  lib = prev.lib;
  arch =
    if stdenv.hostPlatform.isAarch64 then "arm64"
    else if stdenv.hostPlatform.isx86_64 then "x64"
    else throw "Unsupported architecture for factory-cli";
  platform =
    if stdenv.hostPlatform.isLinux then "linux"
    else if stdenv.hostPlatform.isDarwin then "darwin"
    else throw "Unsupported OS for factory-cli";
  systemKey = stdenv.hostPlatform.system;
  version = "0.22.14";
  baseUrl = "https://downloads.factory.ai";

  droidSha256 = {
    "x86_64-linux" = "ed4c442f39ceaa54b644d6482434ffcc287b22437718f936a8daccd4d7faad02";
    "aarch64-linux" = "a15ddd276776622823b6cc3f4524370841324c43aacafbdab5051ae4243a9a84";
    "x86_64-darwin" = "6edeeac8486fdbacd3aec53cefcbb262f2b740133a227be4527e049bcef88e0d";
    "aarch64-darwin" = "f6928329f2b75d79a23271981d1c9ae7437913a7ad924bfb74fc194b4a19501d";
  };

  droidSRI = {
    "x86_64-linux" = "sha256-7UxELznOqlS2RNZIJMT/wqh7IkN3Gfk2qNrOTV+q0Cc=";
    "aarch64-linux" = "sha256-oV3dJ2e2YoIjbMg/RSQ3CEE6TEOqyvxatQUa5CQ5qoQ=";
    "x86_64-darwin" = "sha256-bt7q2Ehn260zrsU478usYvK3QRPoin5FJfBJvO+K4A0=";
    "aarch64-darwin" = "sha256-9pKDnytdfSYoMnGYRyrnpENpTWet+SL7dPwZS0oZUB0=";
  };

  droidSrc = prev.fetchurl (
    { url = "${baseUrl}/factory-cli/releases/${version}/${platform}/${arch}/droid"; }
    // (if droidSRI ? ${systemKey}
    then { hash = droidSRI.${systemKey}; }
    else { sha256 = droidSha256.${systemKey}; })
  );
in
{
  factory-cli = prev.stdenv.mkDerivation {
    pname = "factory-cli";
    inherit version;

    srcs = [ droidSrc ];
    sourceRoot = ".";

    nativeBuildInputs = [ prev.makeWrapper ];

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontCheck = true;
    dontStrip = true;

    installPhase = lib.optionalString stdenv.isLinux ''
      runHook preInstall
      install -Dm755 ${droidSrc} "$out/libexec/factory-cli/droid-unwrapped"
      mkdir -p "$out/bin"

      # Use steam-run FHS environment to run the binary
      makeWrapper ${prev.steam-run}/bin/steam-run "$out/bin/droid" \
        --add-flags "$out/libexec/factory-cli/droid-unwrapped" \
        --prefix PATH : ${lib.makeBinPath [ prev.ripgrep ]}

      runHook postInstall
    '' + lib.optionalString stdenv.isDarwin ''
      runHook preInstall
      install -Dm755 ${droidSrc} "$out/bin/droid"
      runHook postInstall
    '';

    meta = {
      description = "Command-line interface for Factory AI";
      homepage = "https://factory.ai/";
      license = lib.licenses.unfree;
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  };
}
