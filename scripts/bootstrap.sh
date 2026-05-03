#!/bin/bash
# Mac Setup Bootstrap Script
# Run this on a fresh Mac to restore your development environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Starting Mac setup..."

# 1. Install Homebrew if not present
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "==> Homebrew already installed"
fi

# 2. Install Nix if not present
if ! command -v nix &>/dev/null && [ ! -f /nix/var/nix/profiles/default/bin/nix ]; then
  echo "==> Installing Nix (Determinate Systems)..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  # Source nix for this session
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
else
  echo "==> Nix already installed"
  # Source nix for this session if not already in PATH
  if ! command -v nix &>/dev/null; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi
fi

# 3. Install Nix packages
echo "==> Installing Nix packages..."
NIX_BIN=/nix/var/nix/profiles/default/bin/nix
while IFS= read -r pkg || [[ -n "$pkg" ]]; do
  [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
  echo "    Installing $pkg..."
  "$NIX_BIN" profile install "nixpkgs#$pkg" 2>&1 | grep -v "^warning:"
done < "$ROOT_DIR/nix/packages.txt"

# 4. Install brew packages (GUI/Mac-specific only)
echo "==> Installing brew packages..."
brew bundle install --file="$ROOT_DIR/brew/Brewfile"

# 5. Install Oh My Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 6. Copy zsh config
echo "==> Setting up zsh config..."
cp "$ROOT_DIR/zsh/.zshrc" "$HOME/.zshrc"
cp "$ROOT_DIR/zsh/.all_aliases" "$HOME/.all_aliases"

# 7. Set up iTerm2 Dev profile
echo "==> Setting up iTerm2 Dev profile..."
python3 "$ROOT_DIR/iterm2/setup_dev_profile.py"

# 8. Import Rectangle config
echo "==> Importing Rectangle config..."
defaults import com.knollsoft.Rectangle "$ROOT_DIR/rectangle/RectangleConfig.json"

# 9. Install Node.js LTS via fnm
echo "==> Installing Node.js LTS..."
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
if command -v fnm &>/dev/null; then
  eval "$(fnm env --shell bash)"
  fnm install --lts
  fnm default lts-latest
  echo "    Node $(node --version) installed"
else
  echo "    WARNING: fnm not found — skipping Node install"
fi

# 10. Set up spear_development symlink and web projects folder
echo "==> Setting up spear_development symlink..."
if [ -d "/Volumes/spear_development" ]; then
  ln -sf "/Volumes/spear_development" "$HOME/spear_development"
  mkdir -p "/Volumes/spear_development/web"
  echo "    Symlink created, web/ folder ready"
elif [ -d "/Volumes/spear/logs/work/sbalan/development" ]; then
  ln -sf "/Volumes/spear/logs/work/sbalan/development" "$HOME/spear_development"
  mkdir -p "/Volumes/spear/logs/work/sbalan/development/web"
  echo "    Symlink created (via spear volume), web/ folder ready"
else
  echo "    WARNING: No spear volume mounted — skipping symlink"
fi

echo ""
echo "==> Done! Next steps:"
echo "    1. Import Keychron profile: keychron/HEProfile-Default-*.json via launcher.keychron.com"
echo "    2. Restart iTerm2 to apply Dev profile"
echo "    3. Open a new terminal — zsh config and Node will be active"
echo "    4. Create a React app: cd ~/spear_development/web && npm create vite@latest"
