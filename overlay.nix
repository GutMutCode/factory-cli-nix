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
  version = "0.22.10";
  baseUrl = "https://downloads.factory.ai";

  droidSha256 = {
    "x86_64-linux" = "f69700823f9db38098c88910484405113d9c43e77f23e1d6525939480476c8b9";
    "aarch64-linux" = "421524c577c03c92675da400542482e5ec1f10329846709254e0774c90a599dd";
    "x86_64-darwin" = "22cadae1e0e1207a804c7be98ceeb5c711eef77e77b9bc711ce222ae31b4cd5f";
    "aarch64-darwin" = "aac50c2ac36a94c71e661dc2590fe4d3b7844055c7925ec1ea092709f77bd256";
  };

  droidSRI = {
    "x86_64-linux" = "sha256-9pcAgj+ds4CYyIkQSEQFE+WcQ+d/I+HWUlk5SAX2yLk=";
    "aarch64-linux" = "sha256-QhSkxXfAPJJnWaAAVCSCXsH0EDKYRnCSVOB3TJClmd0=";
    "x86_64-darwin" = "sha256-IsraHg4ZIHqATHvpjOu1xxHu9353ubxxHOIirjG0zV8=";
    "aarch64-darwin" = "sha256-qsUMKsNalMceZhwVMpo93bRAgPMtsRZZqH1fuHX3S1Y=";
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
