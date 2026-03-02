---
name: iterm-setup
description: Install and configure iTerm2 with Oh My Zsh, Powerlevel10k, and developer plugins
user-invocable: true
---

# iTerm2 Developer Setup

Install and configure a complete developer terminal setup with iTerm2, Oh My Zsh, Powerlevel10k theme, and essential plugins.

## What This Skill Installs

| Component | Description |
|-----------|-------------|
| iTerm2 | Modern terminal replacement for macOS |
| Oh My Zsh | ZSH framework with plugins and themes |
| Powerlevel10k | Fast, customizable prompt theme |
| MesloLG Nerd Font | Font with icons for Powerlevel10k |
| zsh-autosuggestions | Fish-like command suggestions |
| zsh-syntax-highlighting | Syntax highlighting for commands |

## Installation Steps

### 1. Check and Install Homebrew (if needed)
```bash
which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install iTerm2
```bash
brew install --cask iterm2
```

### 3. Install Oh My Zsh
```bash
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 4. Install Powerlevel10k Theme
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

### 5. Install ZSH Plugins
```bash
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### 6. Install Nerd Font
```bash
brew install --cask font-meslo-lg-nerd-font
```

### 7. Configure .zshrc
Update `~/.zshrc` with:
- Theme: `ZSH_THEME="powerlevel10k/powerlevel10k"`
- Plugins:
```bash
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  docker
  kubectl
  history
)
```

## Post-Installation (Manual Steps)

### Set Font in iTerm2
1. Open **iTerm2 > Settings** (`Cmd + ,`)
2. Go to **Profiles > Text**
3. Set font to **MesloLGM Nerd Font** at 13-14pt

### Configure Powerlevel10k
Run `p10k configure` in iTerm2 to customize your prompt.

### Enable Toolbelt (Session Sidebar)
- Press `Cmd + Shift + B` or **View > Show Toolbelt**
- Add Profiles, Jobs, Command History panels

### Save Window Arrangement
1. Set up your preferred split pane layout
2. **Window > Save Window Arrangement** (`Cmd + Shift + S`)
3. **Settings > General > Startup** → "Open Default Window Arrangement"

## Essential Shortcuts

| Action | Shortcut |
|--------|----------|
| Split vertically | `Cmd + D` |
| Split horizontally | `Cmd + Shift + D` |
| Navigate panes | `Cmd + Opt + Arrow` |
| Maximize pane | `Cmd + Shift + Enter` |
| New tab | `Cmd + T` |
| Show toolbelt | `Cmd + Shift + B` |
| Save arrangement | `Cmd + Shift + S` |

## Execution Notes

When running this skill:
1. Skip components that are already installed
2. Back up existing `.zshrc` before modifying
3. Remind user of manual post-installation steps
4. Open iTerm2 at the end if installation is successful
