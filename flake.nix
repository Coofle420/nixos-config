{
  description = "kenny's NixOS system: niri + noctalia, gaming-ready, dark synthwave";

  # Chaotic-Nyx's binary cache (for the cachyos kernel). This has to be
  # declared here, not just via chaotic.nixosModules.default's nix.settings,
  # because the *first* build (before you've ever switched to a generation
  # that registers that substituter) can't see it otherwise -- Nix reads
  # nixConfig up front and asks the user/`--accept-flake-config` to trust it.
  # Without this, the first build silently falls back to compiling things
  # like the kernel and rustc from source instead of fetching them.
  nixConfig = {
    extra-substituters = [ "https://nyx-cache.chaotic.cx/" ];
    extra-trusted-public-keys = [
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };

  inputs = {
    # nixos-unstable: rolling, hydra-tested channel (per kenny's request).
    # Every other input below follows this SAME nixpkgs, so niri, mesa,
    # the cachyos kernel overlay, home-manager and noctalia all build
    # against one consistent package set -- avoiding the version-skew
    # ("mesa out of sync with niri") problem niri's wiki warns about,
    # which mainly bites setups that pull in multiple disconnected
    # nixpkgs pins.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      # Sharing nixpkgs avoids building/downloading a second copy.
      # Trade-off: opts out of noctalia's own binary cache (cachix),
      # so the first noctalia build compiles from source. See the
      # generated skill for how to flip this later if desired.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Helium: privacy-focused Chromium fork (imputnet). Not in nixpkgs;
    # this community flake repackages the upstream .deb and provides a
    # `programs.helium` NixOS module (extra flags + Chrome-policy support).
    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CachyOS kernel (BORE scheduler + gaming-oriented patches), consumed
    # via Chaotic-Nyx's overlay + binary cache -- this is a third-party
    # (not NixOS-official) but well-established community cache. Its
    # nixosModules.default wires up both the package overlay and the
    # substituter/trusted key needed to fetch prebuilt kernels instead
    # of compiling one locally (which otherwise takes a long time).
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
