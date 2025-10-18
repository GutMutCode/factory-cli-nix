{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.factory-cli;
in
{
  options.services.factory-cli = {
    enable = mkEnableOption "Factory AI CLI (droid)";

    package = mkOption {
      type = types.package;
      default = pkgs.factory-cli;
      defaultText = literalExpression "pkgs.factory-cli";
      description = "Factory CLI package to use";
    };
  };

  config = mkIf cfg.enable {
    # Install package
    home.packages = [ cfg.package ];

    # Unfree package allowance is handled automatically by the overlay
    # Users need to set nixpkgs.config.allowUnfree = true; or use allowedUnfreePackages
  };
}
