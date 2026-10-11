#!/usr/bin/env bash
#
# Install script for dotfiles managed with GNU Stow.
#
# Usage:
#   ./install.sh              # install plugins and stow every package
#   ./install.sh nvim tmux    # only stow the listed packages
#
# Safe to re-run: existing clones are skipped and stow restows in place.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
CATPPUCCIN_TMUX_VERSION="v2.1.2"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

# Clone a git repo unless the destination already exists.
clone() {
	local url=$1 dest=$2
	shift 2
	if [ -d "$dest" ]; then
		echo "    already present: ${dest/#"$HOME"/\~}"
	else
		git -c advice.detachedHead=false clone --depth=1 "$@" "$url" "$dest"
	fi
}

check_deps() {
	local missing=()
	for cmd in git stow curl; do
		command -v "$cmd" >/dev/null || missing+=("$cmd")
	done
	if [ ${#missing[@]} -gt 0 ]; then
		echo "Missing required commands: ${missing[*]}" >&2
		echo "On Arch: sudo pacman -S ${missing[*]}" >&2
		exit 1
	fi
}

install_zsh_plugins() {
	info "Oh My Zsh"
	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		# KEEP_ZSHRC stops the installer from replacing our .zshrc
		ZSH="$HOME/.oh-my-zsh" RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
			"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	else
		echo "    already present: ~/.oh-my-zsh"
	fi

	local custom="$HOME/.oh-my-zsh/custom"
	info "Zsh theme and plugins"
	clone https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k"
	clone https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
	clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom/plugins/zsh-syntax-highlighting"
}

install_tmux_plugins() {
	info "Tmux plugins"
	clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
	clone https://github.com/catppuccin/tmux.git "$HOME/.config/tmux/plugins/catppuccin/tmux" \
		--branch "$CATPPUCCIN_TMUX_VERSION"
}

stow_packages() {
	local packages=("$@")
	if [ ${#packages[@]} -eq 0 ]; then
		# Every top-level directory is a stow package
		for dir in "$DOTFILES_DIR"/*/; do
			packages+=("$(basename "$dir")")
		done
	fi

	info "Stowing: ${packages[*]}"
	mkdir -p "$HOME/.config"
	local failed=()
	for pkg in "${packages[@]}"; do
		if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
			warn "no such package: $pkg"
			failed+=("$pkg")
		elif ! stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg"; then
			failed+=("$pkg")
		fi
	done

	if [ ${#failed[@]} -gt 0 ]; then
		warn "could not stow: ${failed[*]}"
		echo "A real file probably exists where a symlink should go. Back it up or remove it," >&2
		echo "or run 'stow --adopt <package>' to pull it into the repo (then review with git diff)." >&2
		return 1
	fi
}

main() {
	check_deps
	# Stow first so the Oh My Zsh installer sees our .zshrc and keeps it
	stow_packages "$@"
	install_zsh_plugins
	install_tmux_plugins

	# Install plugins listed in .tmux.conf (tmux-sensible, ...)
	if command -v tmux >/dev/null && [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
		info "Installing tmux plugins via TPM"
		"$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null || warn "TPM install failed; press prefix + I inside tmux"
	fi

	info "Done. Open a new shell; Neovim installs its plugins on first launch."
}

main "$@"
