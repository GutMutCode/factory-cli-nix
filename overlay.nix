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
  version = "0.22.9";
  baseUrl = "https://downloads.factory.ai";

  droidSha256 = {
    "x86_64-linux" = "b3286057d28b8b8c7677eb3e0f2cd595a047a3da1f2fa40f9bf813e80f91c240";
    "aarch64-linux" = "a3c7ef08d4782fbc250a0a2710d68e6c1bab59c5b958f2a9d5c2a6880f31500c";
    "x86_64-darwin" = "0a37253775a5c4fd4744004d7cfaca359e4e48a4115cdd33ead5567651fa25f3";
    "aarch64-darwin" = "c5b2f008c09710637cc835e11eff7d0179ef4526169ec7ca459d02875b2a4a61";
  };

  droidSRI = {
    "x86_64-linux" = "sha256-syhgV9KLi4x2d+s+DyzVlaBHo9ofL6QPm/gT6A+RwkA=";
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
