#!/bin/bash
# Mac Setup Bootstrap Script
# Run this on a fresh Mac to restore your development environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Checklist tracking
declare -A STATUS
STEPS=(
  "env_file"
  "homebrew"
  "nix"
  "nix_packages"
  "brew_packages"
  "oh_my_zsh"
  "zsh_config"
  "iterm2"
  "rectangle"
  "node"
  "claude_code"
  "spear_symlink"
  "podman_setup"
)
LABELS=(
  "Env file (.env)"
  "Homebrew"
  "Nix"
  "Nix packages"
  "Brew packages"
  "Oh My Zsh"
  "Zsh config"
  "iTerm2 Dev profile"
  "Rectangle config"
  "Node.js LTS (fnm)"
  "Claude Code CLI"
  "Spear symlink"
  "Podman C++ dev env"
)

mark() { STATUS[$1]=$2; }  # pass step key and "ok", "skip", or "fail"

print_summary() {
  echo ""
  echo "╔══════════════════════════════════════╗"
  echo "║         Mac Setup — Summary          ║"
  echo "╠══════════════════════════════════════╣"
  local i=0
  for key in "${STEPS[@]}"; do
    local label="${LABELS[$i]}"
    local s="${STATUS[$key]:-unknown}"
    if   [ "$s" = "ok"   ]; then icon="✅"
    elif [ "$s" = "skip" ]; then icon="⚠️ "
    elif [ "$s" = "fail" ]; then icon="❌"
    else                         icon="❓"
    fi
    printf "║  %s  %-30s ║\n" "$icon" "$label"
    (( i++ ))
  done
  echo "╚══════════════════════════════════════╝"
  echo ""
  echo "Manual steps still required:"
  echo "  • Import Keychron profile via launcher.keychron.com"
  echo "  • Restart iTerm2 to apply Dev profile"
  echo "  • Open a new terminal for all PATH changes to take effect"
}

# On exit (including errors), always print the summary
trap print_summary EXIT

echo ""
echo "==> Starting Mac setup..."
echo ""

# ── 1. Env file ──────────────────────────────────────────────────────────────
if [ -f "$ROOT_DIR/.env" ]; then
  set -a; source "$ROOT_DIR/.env"; set +a
  mark env_file ok
else
  echo "WARNING: No .env file found. Copy .env.example to .env and fill in your values."
  echo "         Some steps (spear symlink) will be skipped."
  mark env_file skip
fi

# ── 2. Homebrew ───────────────────────────────────────────────────────────────
echo "==> [2/12] Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
mark homebrew ok
echo "    brew $(brew --version | head -1)"

# ── 3. Nix ────────────────────────────────────────────────────────────────────
echo "==> [3/12] Nix..."
if ! command -v nix &>/dev/null && [ ! -f /nix/var/nix/profiles/default/bin/nix ]; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
else
  if ! command -v nix &>/dev/null; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi
fi
mark nix ok
echo "    nix $(/nix/var/nix/profiles/default/bin/nix --version)"

# ── 4. Nix packages ───────────────────────────────────────────────────────────
echo "==> [4/12] Nix packages..."
NIX_BIN=/nix/var/nix/profiles/default/bin/nix
failed_pkgs=()
while IFS= read -r pkg || [[ -n "$pkg" ]]; do
  [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
  echo "    Installing $pkg..."
  if ! "$NIX_BIN" profile install "nixpkgs#$pkg" 2>&1 | grep -v "^warning:"; then
    failed_pkgs+=("$pkg")
  fi
done < "$ROOT_DIR/nix/packages.txt"
if [ ${#failed_pkgs[@]} -eq 0 ]; then
  mark nix_packages ok
else
  echo "    WARNING: Failed to install: ${failed_pkgs[*]}"
  mark nix_packages skip
fi

# ── 5. Brew packages ──────────────────────────────────────────────────────────
echo "==> [5/12] Brew packages..."
if brew bundle install --file="$ROOT_DIR/brew/Brewfile"; then
  mark brew_packages ok
else
  mark brew_packages fail
fi

# ── 6. Oh My Zsh ─────────────────────────────────────────────────────────────
echo "==> [6/12] Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
mark oh_my_zsh ok

# ── 7. Zsh config ─────────────────────────────────────────────────────────────
echo "==> [7/12] Zsh config..."
cp "$ROOT_DIR/zsh/.zshrc" "$HOME/.zshrc"
cp "$ROOT_DIR/zsh/.all_aliases" "$HOME/.all_aliases"
mark zsh_config ok

# ── 8. iTerm2 Dev profile ─────────────────────────────────────────────────────
echo "==> [8/12] iTerm2 Dev profile..."
if python3 "$ROOT_DIR/iterm2/setup_dev_profile.py"; then
  mark iterm2 ok
else
  mark iterm2 fail
fi

# ── 9. Rectangle config ───────────────────────────────────────────────────────
echo "==> [9/12] Rectangle config..."
if defaults import com.knollsoft.Rectangle "$ROOT_DIR/rectangle/RectangleConfig.json"; then
  mark rectangle ok
else
  mark rectangle fail
fi

# ── 10. Node.js LTS via fnm ───────────────────────────────────────────────────
echo "==> [10/12] Node.js LTS..."
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
if command -v fnm &>/dev/null; then
  eval "$(fnm env --shell bash)"
  fnm install --lts
  fnm default lts-latest
  mark node ok
  echo "    Node $(node --version)"
else
  echo "    WARNING: fnm not found — skipping Node install"
  mark node fail
fi

# ── 11. Claude Code CLI ───────────────────────────────────────────────────────
echo "==> [11/12] Claude Code CLI..."
if command -v npm &>/dev/null; then
  npm install -g @anthropic-ai/claude-code
  mark claude_code ok
  echo "    $(claude --version 2>/dev/null || echo 'claude installed')"
else
  echo "    WARNING: npm not found — skipping Claude Code install"
  mark claude_code fail
fi

# ── 12. Spear symlink ─────────────────────────────────────────────────────────
echo "==> [12/13] Spear symlink..."
if [ -d "/Volumes/spear_development" ]; then
  ln -sf "/Volumes/spear_development" "$HOME/spear_development"
  mkdir -p "/Volumes/spear_development/web"
  mark spear_symlink ok
  echo "    Symlink created, web/ folder ready"
elif [ -n "$SPEAR_USER" ] && [ -d "/Volumes/spear/logs/work/$SPEAR_USER/development" ]; then
  ln -sf "/Volumes/spear/logs/work/$SPEAR_USER/development" "$HOME/spear_development"
  mkdir -p "/Volumes/spear/logs/work/$SPEAR_USER/development/web"
  mark spear_symlink ok
  echo "    Symlink created (via spear volume), web/ folder ready"
else
  echo "    WARNING: No spear volume mounted — skipping symlink"
  mark spear_symlink skip
fi

# ── 13. Podman C++ dev environment ────────────────────────────────────────────
echo "==> [13/13] Podman C++ dev environment..."
if [ -d "/Volumes/spear_development" ]; then
  if bash "$ROOT_DIR/podman/setup.sh"; then
    mark podman_setup ok
  else
    mark podman_setup fail
  fi
else
  echo "    WARNING: spear_development SSD not mounted — skipping Podman setup"
  echo "    Run podman/setup.sh manually once the SSD is attached."
  mark podman_setup skip
fi
