# Dotfiles

My Hyprland + Neovim setup for Arch Linux and FreeBSD.

![Screenshot](screenshot.png)

## What's Included

| Config | Description |
|--------|-------------|
| **hyprland** | Wayland compositor with animations |
| **waybar** | Status bar |
| **wofi** | App launcher |
| **dunst** | Notifications |
| **kitty** | Terminal emulator |
| **ghostty** | Terminal emulator |
| **neovim** | LazyVim config with LSP, AI (avante.nvim) |
| **starship** | Shell prompt |
| **hyprlock** | Lock screen |
| **hyprpaper** | Wallpaper |
| **wlogout** | Logout menu |

## Installation

```bash
# Clone the repo
git clone https://github.com/sheridans/dotfiles.git
cd dotfiles

# Check what's missing
./setup.sh --check

# Install everything (also copies configs to ~/.config/)
./setup.sh

# Or just copy configs without installing packages
./setup.sh --deploy
```

## Requirements

- **Arch Linux** or **FreeBSD**
- Wayland-compatible GPU

The setup script handles all dependencies including:
- Hyprland ecosystem (hyprlock, hyprpaper, hyprshot, etc.)
- Development tools (neovim, rust, go, node, php, python)
- LSP servers via npm and Mason
- Fonts (JetBrains Mono Nerd, Iosevka Nerd, Font Awesome)

See [PLAN.md](PLAN.md) for the complete package list.

## Neovim Plugins

- **avante.nvim** - AI coding assistant (Claude, OpenAI, Gemini)
- **grug-far.nvim** - Search and replace
- LazyVim defaults (treesitter, telescope, lsp, etc.)

Requires `ANTHROPIC_API_KEY` env var for AI features.

## Post-Install

1. Open nvim and run `:Lazy sync`
2. Enable pipewire: `systemctl enable --user pipewire wireplumber`
3. Log out and select Hyprland session
4. Set your API keys for avante.nvim

## License

MIT
