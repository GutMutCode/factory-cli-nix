{
  description = "Factory AI CLI (droid) for NixOS and Nix users";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # Overlay for adding factory-cli package to nixpkgs
      overlays.default = import ./overlay.nix;

      # NixOS module
      nixosModules.default = import ./module.nix;

      # home-manager module
      homeManagerModules.default = import ./module.nix;

      # Packages for each system
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
            config.allowUnfree = true;
          };
        in
        {
          factory-cli = pkgs.factory-cli;
          default = pkgs.factory-cli;
        }
      );

      # Apps (for nix run)
      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.factory-cli}/bin/droid";
        };
      });

      # Development shell
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [ self.packages.${system}.factory-cli ];
            shellHook = ''
              echo "Factory CLI development environment"
              echo "Run 'droid' to start"
            '';
          };
        }
      );
    };
}
