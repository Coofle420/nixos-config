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
  };

  outputs = { self, nixpkgs, home-manager, noctalia, chaotic, helium-flake, ... }@inputs:
    {
      nixosConfigurations.eeepy = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          noctalia.nixosModules.default
          chaotic.nixosModules.default
          helium-flake.nixosModules.default

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
