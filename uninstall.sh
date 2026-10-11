#!/usr/bin/env bash
#
# Undo ./install.sh using the record it keeps in ~/.dotfiles-backup/manifest:
#   1. remove the symlinks for every package install.sh stowed
#   2. move the configs it backed up back into place
#   3. delete what it downloaded (Oh My Zsh, zsh/tmux plugins) and remove
#      directories it created if they are empty
#
# Usage:
#   ./uninstall.sh        # asks for confirmation
#   ./uninstall.sh -y     # no prompt

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd -P)"
BACKUP_DIR="$HOME/.dotfiles-backup"
MANIFEST="$BACKUP_DIR/manifest"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

# Print manifest entries of one kind, deduplicated, in recorded order.
entries() { awk -F'\t' -v k="$1" '$1 == k && !seen[$2]++ { print $2 }' "$MANIFEST"; }

# Refuse anything that would escape $HOME or name $HOME itself.
safe_rel() {
	case "$1" in "" | /* | . | .. | ../* | */../* | */..) return 1 ;; esac
}

if [ ! -f "$MANIFEST" ]; then
	echo "No install record found at ${MANIFEST/#"$HOME"/\~}; nothing to undo." >&2
	echo "(Only installs done with this version of install.sh can be reverted.)" >&2
	exit 1
fi

original_shell=$(entries shell | head -n1)

if [ "${1:-}" != "-y" ]; then
	echo "This will:"
	echo "  - unlink: $(entries stowed | tr '\n' ' ')"
	echo "  - restore $(entries backup | wc -l) backed-up config(s) from ~/.dotfiles-backup"
	echo "  - delete $(entries created | wc -l) item(s) the installer downloaded"
	read -rp "Continue? [y/N] " answer
	[[ $answer =~ ^[Yy]$ ]] || exit 0
fi

info "Removing symlinks"
while IFS= read -r pkg; do
	if [ -d "$DOTFILES_DIR/$pkg" ]; then
		stow --dir="$DOTFILES_DIR" --target="$HOME" --delete "$pkg"
		echo "    unlinked $pkg"
	else
		warn "package $pkg no longer exists in the repo; remove its links by hand"
	fi
done < <(entries stowed)

info "Restoring your original configs"
failed=0
while IFS= read -r rel; do
	safe_rel "$rel" || { warn "skipping suspicious path: $rel"; continue; }
	src="$BACKUP_DIR/files/$rel" dest="$HOME/$rel"
	if [ ! -e "$src" ] && [ ! -L "$src" ]; then
		warn "backup of ~/$rel is missing; skipped"
	elif [ -e "$dest" ] || [ -L "$dest" ]; then
		# shellcheck disable=SC2088 # "~" is only displayed
		warn "~/$rel exists again, so the backup was left in ${src/#"$HOME"/\~}"
		failed=1
	else
		mkdir -p "$(dirname "$dest")"
		mv "$src" "$dest"
		echo "    restored ~/$rel"
	fi
done < <(entries backup)

info "Removing what the installer added"
# Newest first, so contents go before the directories that hold them
tac "$MANIFEST" | while IFS=$'\t' read -r kind rel; do
	safe_rel "$rel" || continue
	target="$HOME/$rel"
	case "$kind" in
	created)
		if [ -e "$target" ] || [ -L "$target" ]; then
			rm -rf "$target"
			echo "    deleted ~/$rel"
		fi
		;;
	mkdir)
		if [ -d "$target" ] && rmdir "$target" 2>/dev/null; then
			echo "    removed empty ~/$rel"
		fi
		;;
	esac
done

if [ "$failed" = 0 ]; then
	rm -rf "$BACKUP_DIR"
	info "Done. Your machine is back to how it was before install.sh."
else
	mv "$MANIFEST" "$MANIFEST.done"
	info "Done, except for the backups listed above (still in ~/.dotfiles-backup)."
fi
current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
if [ -n "$original_shell" ] && [ "$original_shell" != "$current_shell" ]; then
	echo "Your login shell was $original_shell before installing. To switch back: chsh -s $original_shell"
fi
