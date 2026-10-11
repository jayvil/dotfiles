#!/usr/bin/env bash
#
# Install script for dotfiles managed with GNU Stow.
#
# Usage:
#   ./install.sh              # install plugins and stow every package
#   ./install.sh nvim tmux    # only stow the listed packages
#
# Existing configs that would be replaced are moved to ~/.dotfiles-backup/,
# and everything this script does is recorded there so ./uninstall.sh can
# put the machine back the way it was.
#
# Safe to re-run: existing clones are skipped and stow restows in place.

set -euo pipefail
shopt -s dotglob nullglob

DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)"
BACKUP_DIR="$HOME/.dotfiles-backup"
MANIFEST="$BACKUP_DIR/manifest"
CATPPUCCIN_TMUX_VERSION="v2.1.2"

# Directories shared with other programs. Stow links the configs *inside*
# them, so conflicts are checked one level down (~/.config/nvim, not ~/.config).
CONTAINERS=(.config .local .local/share .local/bin)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

# Append "<action>\t<path relative to $HOME>" to the manifest (once).
record() {
	mkdir -p "$BACKUP_DIR"
	local line
	line=$(printf '%s\t%s' "$1" "$2")
	grep -qxF "$line" "$MANIFEST" 2>/dev/null || echo "$line" >>"$MANIFEST"
}

# Call these *before* creating something, so uninstall removes only what did
# not exist before.
#
# mark_mkdir: directory $1 and any missing parents. Uninstall removes them
# only if empty, since the user may have put their own files there since.
mark_mkdir() {
	local p=$1 missing=()
	while [ "$p" != "$HOME" ] && [ "$p" != "/" ]; do
		[ -e "$p" ] || [ -L "$p" ] || missing=("$p" "${missing[@]}")
		p=$(dirname "$p")
	done
	for p in "${missing[@]}"; do record mkdir "${p#"$HOME"/}"; done
}

# mark_created: $1 is wholly ours (a clone, Oh My Zsh); uninstall deletes it.
mark_created() {
	mark_mkdir "$(dirname "$1")"
	record created "${1#"$HOME"/}"
}

# Clone a git repo unless the destination already exists.
clone() {
	local url=$1 dest=$2
	shift 2
	if [ -d "$dest" ]; then
		echo "    already present: ${dest/#"$HOME"/\~}"
	else
		mark_created "$dest"
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

is_container() {
	local c
	for c in "${CONTAINERS[@]}"; do [ "$1" = "$c" ] && return 0; done
	return 1
}

# True if $1 is already managed by this repo: a symlink into it, or a
# directory stow unfolded that holds nothing but symlinks into it.
is_ours() {
	local t=$1 f found=0
	if [ -L "$t" ]; then
		case "$(readlink -f "$t")" in "$DOTFILES_DIR"/*) return 0 ;; esac
		return 1
	fi
	[ -d "$t" ] || return 1
	while IFS= read -r -d '' f; do
		found=1
		if [ -L "$f" ]; then
			case "$(readlink -f "$f")" in "$DOTFILES_DIR"/*) continue ;; esac
		fi
		return 1
	done < <(find "$t" ! -type d -print0)
	[ "$found" = 1 ]
}

# List the paths (relative to $HOME) that package $1 takes over.
package_targets() {
	local pkg_dir="$DOTFILES_DIR/$1" rel=${2:-} entry name
	for entry in "$pkg_dir/${rel:+$rel/}"*; do
		name=${rel:+$rel/}$(basename "$entry")
		if [ -d "$entry" ] && [ ! -L "$entry" ] && is_container "$name"; then
			package_targets "$1" "$name"
		else
			echo "$name"
		fi
	done
}

# Move anything in the way of package $1 into the backup directory.
backup_conflicts() {
	local pkg=$1 rel target dest
	while IFS= read -r rel; do
		target="$HOME/$rel"
		{ [ -e "$target" ] || [ -L "$target" ]; } || continue
		is_ours "$target" && continue

		dest="$BACKUP_DIR/files/$rel"
		if [ -e "$dest" ] || [ -L "$dest" ]; then
			warn "$pkg: ~/$rel is in the way, but a backup of it already exists at ${dest/#"$HOME"/\~}"
			return 1
		fi
		mkdir -p "$(dirname "$dest")"
		mv "$target" "$dest"
		record backup "$rel"
		echo "    backed up ~/$rel"
	done < <(package_targets "$pkg")
}

stow_packages() {
	local packages=("$@") dir
	if [ ${#packages[@]} -eq 0 ]; then
		# Every top-level directory is a stow package
		for dir in "$DOTFILES_DIR"/*/; do
			packages+=("$(basename "$dir")")
		done
	fi

	info "Stowing: ${packages[*]}"
	mark_mkdir "$HOME/.config"
	mkdir -p "$HOME/.config"
	local failed=() pkg
	for pkg in "${packages[@]}"; do
		if [ ! -d "$DOTFILES_DIR/$pkg" ]; then
			warn "no such package: $pkg"
			failed+=("$pkg")
		elif ! backup_conflicts "$pkg"; then
			failed+=("$pkg")
		elif stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg"; then
			record stowed "$pkg"
		else
			failed+=("$pkg")
		fi
	done

	if [ ${#failed[@]} -gt 0 ]; then
		warn "could not stow: ${failed[*]}"
		return 1
	fi
}

# Create the untracked per-machine files the configs expect.
create_local_files() {
	info "Per-machine files"
	if [ -d "$HOME/.config/hypr" ] && [ ! -e "$HOME/.config/hypr/local.conf" ]; then
		printf '%s\n' "# Machine-specific Hyprland settings (monitors, scaling, ...)." \
			"# Sourced at the end of hyprland.conf; not tracked in git." \
			"# Example: monitor=eDP-1,preferred,auto,1.5" >"$HOME/.config/hypr/local.conf"
		echo "    created ~/.config/hypr/local.conf"
	fi
	local waypaper="$HOME/.config/waypaper"
	if [ -f "$waypaper/config.ini.example" ] && [ ! -e "$waypaper/config.ini" ]; then
		cp "$waypaper/config.ini.example" "$waypaper/config.ini"
		echo "    created ~/.config/waypaper/config.ini"
	fi
}

install_zsh_plugins() {
	info "Oh My Zsh"
	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		mark_created "$HOME/.oh-my-zsh"
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

	# Install plugins listed in .tmux.conf (tmux-sensible, ...)
	if command -v tmux >/dev/null && [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
		info "Installing tmux plugins via TPM"
		local before plugin
		before=$(ls "$HOME/.tmux/plugins")
		"$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null || warn "TPM install failed; press prefix + I inside tmux"
		for plugin in "$HOME"/.tmux/plugins/*; do
			grep -qxF "$(basename "$plugin")" <<<"$before" || record created ".tmux/plugins/$(basename "$plugin")"
		done
	fi
}

main() {
	check_deps
	# Remember the login shell from the first install so uninstall can suggest restoring it
	if ! { [ -f "$MANIFEST" ] && grep -q '^shell' "$MANIFEST"; }; then
		record shell "$(getent passwd "$(id -un)" | cut -d: -f7)"
	fi
	# Stow first so the Oh My Zsh installer sees our .zshrc and keeps it
	stow_packages "$@"
	create_local_files
	install_zsh_plugins
	install_tmux_plugins

	info "Done. Open a new shell; Neovim installs its plugins on first launch."
	if [ -f "$MANIFEST" ] && grep -q '^backup' "$MANIFEST"; then
		echo "Your previous configs are in ~/.dotfiles-backup; ./uninstall.sh restores them."
	fi
}

main "$@"
