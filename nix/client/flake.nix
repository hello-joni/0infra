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

    # Digilent WaveForms and Adept Runtime (Analog Discovery 2)
    waveforms.url = "github:liff/waveforms-flake";
    waveforms.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware profiles for various devices
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    # Git hooks and linters
    # TODO: Reintegrate later
    # git-hooks.url = "github:cachix/git-hooks.nix";

    # Zephyr RTOS source and Nix packaging
    # TODO: Uncomment here and in zephyr hm module
    # zephyr.url = "github:zephyrproject-rtos/zephyr/v4.4.0";
    # zephyr.flake = false;
    # zephyr-nix.url = "github:hello-joni/zephyr-nix";
    # zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";
    # zephyr-nix.inputs.zephyr.follows = "zephyr";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-flatpak,
      # git-hooks,
      waveforms,
      nixos-hardware,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # hooks = git-hooks.lib.${system}.run {
      #   src = ./.
      #   hooks = {
      #     nixfmt.enable = true;
      #     statix.enable = true;
      #     # Lint shell scripts in home-manager/scripts/
      #     shellcheck = {
      #       enable = true;
      #       files = "^home-manager/scripts/.*\\.sh$";
      #     };
      #   };
      # };
      # Shared module list for every machine. A machine is defined by what is
      # included: its machine dir plus any extra hardware modules.
      mkMachine =
        machine: extraModules:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs machine; };
          modules = [
            ./nixos/configuration.nix
            ./nixos/${machine}/default.nix
            waveforms.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              # home-manager modules shared across all users
              home-manager.sharedModules = [
                nix-flatpak.homeManagerModules.nix-flatpak
              ];
              home-manager.extraSpecialArgs = { inherit inputs machine; };
            }
          ] ++ extraModules;
        };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        # packages = hooks.enabledPackages;
        # inherit (hooks) shellHook;
      };

      nixosConfigurations.paolumu = mkMachine "paolumu" [ ];
      nixosConfigurations.gajau = mkMachine "gajau" [
        nixos-hardware.nixosModules.chuwi-minibook-x
      ];
    };
}
