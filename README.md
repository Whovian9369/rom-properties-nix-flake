# Whovian's `rom-properties` nix flake
I was self-packaging [`rom-properties`](https://github.com/GerbilSoft/rom-properties) for myself, and a friend asked me to please put in a GitHub Repo. 
You should be able to build this by running `nix build github:Whovian9369/rom-properties-nix-flake`. That will then give you a binary called `rpcli` that you can use to find information about various game roms.

There are also alternate versions available and exposed by this flake for use with various Desktop Environments, including but not limited to:

- KDE 6.x
  - `rp_kde6` can be built by using `nix build github:Whovian9369/rom-properties-nix-flake#rp_kde6`

- Cinnamon, GNOME, MATE (1.18+), XFCE, and Unity (GTK 3)
  - Currently unavailable.
  - `rp_gtk3` can be built by using `nix build github:Whovian9369/rom-properties-nix-flake#rp_gtk3`
- XFCE, and GNOME 43 (GTK 3)
  - Currently unavailable.
  - `rp_gtk4` can be built by using `nix build github:Whovian9369/rom-properties-nix-flake#rp_gtk4`
- KDE 4.x
  - Currently unavailable.
  - `rp_kde4` can be built by using `nix build github:Whovian9369/rom-properties-nix-flake#rp_kde4`
- KDE 5.x
  - Currently unavailable.
  - `rp_kde5` can be built by using `nix build github:Whovian9369/rom-properties-nix-flake#rp_kde5`

[`rom-properties`](https://github.com/GerbilSoft/rom-properties) is licensed under the GNU General Public License, Version 2.

Notes:
- I have not been able to test this on a system that isn't `x86_64-linux`, so I have it hardcoded in the flake. 
