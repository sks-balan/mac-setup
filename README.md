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
├── rectangle/
│   └── RectangleConfig.json  # Rectangle window manager shortcuts
├── scripts/
│   └── bootstrap.sh          # Main setup script
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

## Notes

- Keychron profile must be imported manually via launcher.keychron.com
- VS Code extensions at work may need to be installed via internal Artifactory
- spear_development symlink requires /Volumes/spear to be mounted
- Nix installed via Determinate Systems installer (flakes enabled by default)
