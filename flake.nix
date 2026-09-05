{
  description = "kenny's NixOS system: niri + noctalia, gaming-ready, dark synthwave";

  nixConfig = {
    extra-substituters = [ "https://nyx-cache.chaotic.cx/" ];
    extra-trusted-public-keys = [
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    qylock = {
      url = "github:Darkkal44/qylock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # pinned old rev: 0.8.2 broke dropdown/context-menu rendering under niri
    # (xwayland-satellite#491, #468) -- unpin once upstream fixes it
    nixpkgs-xwayland-satellite-0-8-1.url = "github:NixOS/nixpkgs/cc60bc3b0c247c161f70ea3a96039ccee5b6bd68";
  };

  outputs = { self, nixpkgs, home-manager, noctalia, chaotic, helium-flake, qylock, stylix, ... }@inputs:
    {
      nixosConfigurations.eeepy = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          noctalia.nixosModules.default
          chaotic.nixosModules.default
          helium-flake.nixosModules.default
          qylock.nixosModules.default
          stylix.nixosModules.stylix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.kenny = import ./home.nix;
          }
        ];
      };
    };
}
