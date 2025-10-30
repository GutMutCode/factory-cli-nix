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
  version = "0.22.5";
  baseUrl = "https://downloads.factory.ai";

  droidSha256 = {
    "x86_64-linux" = "67994ca2bf0e65028dea70313e26ad0178a50e5a6b2fbe963e81df035cd2c878";
    "aarch64-linux" = "b989c6ab4ad611ab6878b4711b1f708607d2d7dd23a14daf316026bd650b52ec";
    "x86_64-darwin" = "f340e12099a10b9b58b858857724c75aaa3a09606758dc467f41d6cea227cb19";
    "aarch64-darwin" = "e287cb16f56f3805ce40ac7ae664497792032012938cdb325a051d12f66b53ef";
  };

  droidSRI = {
    "x86_64-linux" = "sha256-Z5lMor8OZQKN6nAxPiatAXilDlprL76WPoHfA1zSyHg=";
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
