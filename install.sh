#!/usr/bin/env bash
# vim-ide bootstrap: install Neovim (if missing) and link the config.
# Usage: bash install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

echo "==> vim-ide install"

if ! command -v nvim >/dev/null 2>&1; then
  echo "==> Neovim not found; installing"
  case "$(uname -s)" in
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        candidate="$(apt-cache policy neovim 2>/dev/null | awk '/Candidate:/{print $2}')"
        if [ -n "$candidate" ] && [ "$candidate" != "(none)" ] \
          && [ "$(printf '%s\n0.10' "$candidate" | sort -V | tail -1)" = "$candidate" ]; then
          echo "==> installing neovim $candidate via apt (needs sudo)"
          sudo apt-get update
          sudo apt-get install -y neovim
        else
          echo "==> apt neovim is older than 0.10; installing latest tarball into ~/.local"
          curl -fsSL -o /tmp/nvim.tar.gz \
            https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
          tar -xzf /tmp/nvim.tar.gz -C /tmp
          mkdir -p "$HOME/.local"
          cp -r /tmp/nvim-linux-x86_64/* "$HOME/.local/"
          rm -rf /tmp/nvim.tar.gz /tmp/nvim-linux-x86_64
        fi
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y neovim
      else
        echo "!! No supported package manager; install Neovim 0.10+ manually" >&2
        exit 1
      fi
      ;;
    Darwin)
      command -v brew >/dev/null 2>&1 || { echo "!! Install Homebrew first" >&2; exit 1; }
      brew install neovim
      ;;
    *)
      echo "!! Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "==> ripgrep not found; installing latest release into ~/.local/bin"
  version="$(gh api repos/BurntSushi/ripgrep/releases/latest --jq .tag_name 2>/dev/null || echo 15.2.0)"
  curl -fsSL -o /tmp/rg.tar.gz \
    "https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-x86_64-unknown-linux-musl.tar.gz"
  tar -xzf /tmp/rg.tar.gz -C /tmp
  mkdir -p "$HOME/.local/bin"
  cp "/tmp/ripgrep-${version}-x86_64-unknown-linux-musl/rg" "$HOME/.local/bin/rg"
  rm -rf /tmp/rg.tar.gz "/tmp/ripgrep-${version}-x86_64-unknown-linux-musl"
fi

mkdir -p "$CONFIG_DIR"
for entry in "$REPO_DIR"/config/* "$REPO_DIR"/prompts; do
  name="$(basename "$entry")"
  if [ -e "$CONFIG_DIR/$name" ] && [ ! -L "$CONFIG_DIR/$name" ]; then
    echo "!! $CONFIG_DIR/$name exists and is not a symlink; skipping (remove it first)" >&2
    continue
  fi
  ln -sfn "$entry" "$CONFIG_DIR/$name"
  echo "==> linked $entry -> $CONFIG_DIR/$name"
done

OPENCODE_CMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/commands"
mkdir -p "$OPENCODE_CMD_DIR"
sed "s|{{CHEATSHEET_PATH}}|$REPO_DIR/cheatsheet.md|g" \
  "$REPO_DIR/commands/cheatsheet.md" > "$OPENCODE_CMD_DIR/cheatsheet.md"
echo "==> installed opencode command /cheatsheet -> $OPENCODE_CMD_DIR/cheatsheet.md"

echo "==> done. Launch with: nvim"
echo "    cheatsheet:  $REPO_DIR/cheatsheet.md"
echo "    /cheatsheet: opencode slash command (restart opencode to pick it up)"
