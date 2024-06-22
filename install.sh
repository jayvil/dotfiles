#! /bin/bash

# Install script for coder dotfiles

create_symlinks() {
        # Get the current scripts directory
        script_dir=$(dirname "$(readlink -f "$0")")

	# Get list of dot files in directory
	files=$(find -maxdepth 1 -type f -name ".*")

	# Create symbolic links to each file in the home directory
	for file in $files; do
		name=$(basename $file)
		echo "Creating symlink to $name in home directory"
		rm -rf ~/$name
		ln -s $script_dir/$name ~/$name
	done

	if [ ! -d ~/.config/nvim ]
	then
		mkdir -p ~/.config/
		ln -s $script_dir/nvim ~/.config/
	fi
}
create_symlinks




