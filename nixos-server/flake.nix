{
  description = "NixOS server configurations";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative disk partitioning
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      # Shared module list for every machine. A machine is defined by what is
      # included: its machine dir plus any extra hardware modules.
      mkMachine =
        machine: extraModules:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs machine; };
          modules = [
            ./nixos/configuration.nix
            ./nixos/${machine}/default.nix
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = { inherit inputs machine; };
            }
          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations.vespoid = mkMachine "vespoid" [ ];
    };
}
