{
  description = "Generic flake that I was far too lazy to change the description for.";

  inputs = {
    # The nixos-unstable branch of the NixOS/nixpkgs repository on GitHub.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
  in
  {
    packages.x86_64-linux = {
      default = self.packages.x86_64-linux.rp_cli;
      rp_cli = pkgs.callPackage ./package.nix {};
      rp_apparmor = pkgs.callPackage ./package.nix { useAppArmor = true; };
      # rp_gtk2 = pkgs.callPackage ./package.nix { build_xfce_plugin = true; };
      rp_gtk3 = pkgs.callPackage ./package.nix { build_gtk3_plugin = true; useTracker = true; };
      rp_gtk4 = pkgs.callPackage ./package.nix { build_gtk4_plugin = true; };
      rp_kde6 = pkgs.kdePackages.callPackage ./package.nix { build_kf6_plugin = true; };
    };
  };
}
