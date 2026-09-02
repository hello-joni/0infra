{
  description = "NixOS configurations";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative Flatpak management (client)
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Digilent WaveForms and Adept Runtime (Analog Discovery 2, client)
    waveforms.url = "github:liff/waveforms-flake";
    waveforms.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware profiles for various devices (client)
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative disk partitioning (server)
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

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
      waveforms,
      nixos-hardware,
      disko,
      zephyr-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Shared module list for every machine. A machine is defined by what is
      # included: its machine dir plus any extra modules.
      mkNixos =
        machine: extraModules:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            # Machine-specific config: system config, hardware config, and
            # home-manager import list.
            ./machines/${machine}/default.nix

            # Home Manager as a NixOS module
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                inherit inputs;
                machine = machine;
              };
            }
          ] ++ extraModules;
        };
    in
    {
      devShells.${system}.default = pkgs.mkShell { };

      nixosConfigurations.paolumu = mkNixos "paolumu" [
        waveforms.nixosModules.default
      ];
      nixosConfigurations.gajau = mkNixos "gajau" [
        nixos-hardware.nixosModules.chuwi-minibook-x
      ];
      nixosConfigurations.vespoid = mkNixos "vespoid" [
        disko.nixosModules.disko
      ];
    };
}
