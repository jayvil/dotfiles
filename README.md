# dotfiles

My Linux (Arch + Hyprland) config files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## How it works

Each top-level folder is a **stow package**. Inside a package, files are laid out
exactly as they should appear relative to `$HOME`. Stow then creates symlinks from
your home directory into this repo:

```
dotfiles/nvim/.config/nvim   →   ~/.config/nvim
dotfiles/zshrc/.zshrc        →   ~/.zshrc
```

Because everything is symlinked, **editing a config anywhere edits it here**.
There is no copy step. To save changes, just commit:

```sh
cd ~/dotfiles
git add -A
git commit -m "Describe the change"
git push
```

## Packages

| Package    | Links to                                  | What it is                              |
| ---------- | ----------------------------------------- | --------------------------------------- |
| `fish`     | `~/.config/fish`                          | Fish shell                              |
| `hypr`     | `~/.config/hypr`                          | Hyprland, hyprlock, hypridle, hyprpaper |
| `kitty`    | `~/.config/kitty`                         | Kitty terminal                          |
| `neofetch` | `~/.config/neofetch`                      | Neofetch                                |
| `nvim`     | `~/.config/nvim`                          | Neovim (kickstart-based, lazy.nvim)     |
| `rofi`     | `~/.config/rofi`                          | Rofi launcher                           |
| `tmux`     | `~/.tmux.conf`                            | Tmux (Catppuccin theme, TPM)            |
| `vimrc`    | `~/.vimrc`                                | Vim                                     |
| `walker`   | `~/.config/walker`                        | Walker launcher                         |
| `waybar`   | `~/.config/waybar`                        | Waybar                                  |
| `waypaper` | `~/.config/waypaper`                      | Waypaper wallpaper picker               |
| `zshrc`    | `~/.zshrc`, `~/.p10k.zsh`                 | Zsh (Oh My Zsh + Powerlevel10k)         |

## Setting up a new machine

1. Install the essentials (Arch shown):

   ```sh
   sudo pacman -S git stow curl zsh tmux neovim
   ```

2. Clone and run the installer:

   ```sh
   git clone https://github.com/jayvil/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```

   The installer:
   - stows every package into `$HOME`
   - installs Oh My Zsh (keeping this repo's `.zshrc`), Powerlevel10k,
     zsh-autosuggestions and zsh-syntax-highlighting
   - installs TPM and the Catppuccin tmux theme (pinned to `v2.1.2`, in
     `~/.config/tmux/plugins/`), then the TPM plugins from `.tmux.conf`

   It is safe to re-run: anything already installed is skipped.

3. Open a new terminal. Neovim installs its plugins on first launch.

To install only some packages, list them: `./install.sh nvim tmux zshrc`.

### Optional tools the configs use

- **zsh:** `fzf`, `bat`, `colorls` (`gem install colorls`), `neofetch`
- **Hyprland:** `waybar`, `swaync`, `swww`, `waypaper`, `walker`, `hyprlock`,
  `hypridle`, `hyprshot`, `hyprpicker`, `kitty`, `brightnessctl`, `playerctl`
- **Neovim:** a C compiler, `ripgrep`, `fd`, and a [Nerd Font](https://www.nerdfonts.com/).
  LSP servers are installed automatically by Mason.

## Per-machine settings

The tracked configs are generic. Anything specific to one computer goes in
these files, which are **not** committed:

| File                            | Use it for                                              |
| ------------------------------- | ------------------------------------------------------- |
| `~/.zshrc.local`                | Extra `PATH` entries, env vars, secrets, local aliases  |
| `~/.config/hypr/local.conf`     | Monitor layout and scaling, extra binds (created empty by `install.sh`) |
| `~/.config/hypr/lockscreen.jpg` | Lock screen image; copy or symlink one here (solid color if missing) |

Example `~/.config/hypr/local.conf` for a HiDPI laptop with an external screen:

```
monitor=eDP-1,preferred,auto,1.875
monitor=DP-7,preferred,auto-left,auto
```

Run `hyprctl monitors` to find your monitor names.

## Common tasks

**Add a new config** (example: ghostty):

```sh
cd ~/dotfiles
mkdir -p ghostty/.config
mv ~/.config/ghostty ghostty/.config/
stow ghostty          # links ~/.config/ghostty back into place
git add ghostty && git commit -m "Add ghostty config"
```

For a file that lives directly in `$HOME` (like `~/.gitconfig`), mirror that
instead: `mkdir git && mv ~/.gitconfig git/ && stow git`.

**Remove a package's links** (the files stay in the repo): `stow -D <package>`

**Re-link after moving/renaming files in a package:** `stow -R <package>`

**Preview what stow would do:** `stow -n -v <package>`

## Troubleshooting

**`cannot stow ... over existing target`** means a real file already exists where
stow wants to put a symlink (common on a fresh machine, or when an app replaced
the link with a regular file). Either:

- move the existing file out of the way and re-run `stow <package>`, or
- run `stow --adopt <package>` to move the existing file *into* the repo, then
  check `git diff` and `git restore` anything you don't want to keep.

**A config change isn't showing up in git:** check that the path is actually a
symlink into this repo with `ls -l ~/.config/<name>`. If it isn't, the app has
overwritten the link; fix it with `stow --adopt <package>` as above.
