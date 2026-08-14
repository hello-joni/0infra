{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative Flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Git hooks and linters
    git-hooks.url = "github:cachix/git-hooks.nix";

    # Zephyr RTOS source and Nix packaging
    zephyr.url = "github:zephyrproject-rtos/zephyr/v4.4.0";
    zephyr.flake = false;
    zephyr-nix.url = "github:hello-joni/zephyr-nix";
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";
    zephyr-nix.inputs.zephyr.follows = "zephyr";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-flatpak,
      git-hooks,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      hooks = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          nixfmt.enable = true;
          statix.enable = true;
          # Lint shell scripts in home-manager/scripts/
          shellcheck = {
            enable = true;
            files = "^home-manager/scripts/.*\\.sh$";
          };
        };
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = hooks.enabledPackages;
        inherit (hooks) shellHook;
      };

      nixosConfigurations.paolumu = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            # home-manager modules shared across all users
            home-manager.sharedModules = [
              nix-flatpak.homeManagerModules.nix-flatpak
            ];
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
}
