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
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-flatpak,
    ...
  } @ inputs: {
    nixosConfigurations.paolumu = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./nixos/configuration.nix
        home-manager.nixosModules.home-manager
        {
          # home-manager modules shared across all users
          home-manager.sharedModules = [
            nix-flatpak.homeManagerModules.nix-flatpak
          ];
        }
      ];
    };
  };
}
