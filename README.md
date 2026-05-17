# Mac Setup

Dotfiles and setup scripts for a new Mac (MacBook or Mac Mini).

## Structure

```
mac-setup/
├── brew/Brewfile              # Mac-specific/GUI tools (CLI tools managed by Nix)
├── iterm2/
│   └── setup_dev_profile.py  # iTerm2 Dev profile with key mappings
├── keychron/
│   └── HEProfile-*.json      # Keychron HE actuation profile
├── nix/
│   └── packages.txt          # Cross-platform dev tools (ripgrep, tmux, neovim, etc.)
├── podman/
│   ├── Dockerfile.cpp-dev    # Fedora-based C++ dev image (GCC 16, Clang 22, CMake, GDB)
│   └── setup.sh              # One-shot SSD + Podman machine + image setup
├── rectangle/
│   └── RectangleConfig.json  # Rectangle window manager shortcuts
├── scripts/
│   └── bootstrap.sh          # Main setup script
├── tools/
│   └── start-dev.sh          # Launch C++ dev container (copied to SSD by setup.sh)
├── vscode/
│   └── extensions.txt        # VS Code extensions reference list
└── zsh/
    ├── .zshrc                 # Zsh config (Oh My Zsh)
    └── .all_aliases           # Custom aliases
```

## Fresh Mac Setup

```bash
git clone git@github.com:sks-balan/mac-setup.git ~/projects/mac-setup
cd ~/projects/mac-setup
./scripts/bootstrap.sh
```

## Key Shortcuts

### Rectangle
| Shortcut | Action |
|----------|--------|
| Cmd+F1 | Maximize window |

### iTerm2 (Dev profile)
| Shortcut | Action |
|----------|--------|
| Option+Left/Right | Move word |
| Cmd+Left/Right | Beginning/end of line |
| Cmd+Backspace | Delete to start of line |
| Option+Backspace | Delete word |

### Keychron K2 HE
| Layer | Behaviour |
|-------|-----------|
| Layer 0 | F1-F12 as true function keys |
| Layer 1 (Fn) | Media keys + RGB + Bluetooth switching |

## Syncing to SSD

```bash
sync-mac-setup
```

## Nix Dev Tools

CLI tools (ripgrep, tmux, neovim, btop, ncdu, git) are managed by [Nix](https://github.com/DeterminateSystems/nix-installer) for cross-platform compatibility with the work Linux server.

```bash
# Install all packages
xargs -I{} /nix/var/nix/profiles/default/bin/nix profile install nixpkgs#{} < nix/packages.txt

# Install individual package
nix profile install nixpkgs#ripgrep
```

## C++ Dev Environment

The dev environment runs in a Fedora container via Podman, with all data (VM, images, code) on the `spear_development` SSD. The code directory inside the container mirrors the work path exactly:

- **Mac path**: `/Volumes/spear_development/logs/work/sbalan/development`
- **Container path**: `/logs/work/sbalan/development`

```bash
# First-time setup (SSD must be mounted)
./podman/setup.sh

# Daily use
/Volumes/spear_development/logs/work/sbalan/tools/start-dev.sh
```

Inside the container: GCC 16, Clang 22, GDB, LLDB, CMake, Ninja, clang-format, clang-tidy.

## Notes

- Keychron profile must be imported manually via launcher.keychron.com
- Restart iTerm2 to apply Dev profile
- Open a new terminal for all PATH changes to take effect
- VS Code extensions at work may need to be installed via internal Artifactory
- spear_development symlink requires /Volumes/spear to be mounted
- Nix installed via Determinate Systems installer (flakes enabled by default)
- Podman setup skipped by bootstrap.sh if SSD not mounted — run podman/setup.sh manually
