colorscheme habamax
let mapleader=" "
nnoremap <Leader>pv :Ex<CR>

" Tell Vim to not behave like old Vi editor, change is ok
set nocompatible

" enable syntax and plugins for netrw
syntax enable
filetype plugin on

" -- FUZZY FILE SEARCH --
" search down into subfolders
" ** recursively search subdirectories
set path+=**
set wildmenu

" -- TAG JUMPING --
" Create the tags file (may need to install ctags first)
" The ! makes the ctags command run as a shell command
" Run ctags -R . in the root directory of the directories you care about to create a tagss file that lets you jump around files
" 	- Use ^o to jump to tag under cursor
"	- Use g^] for ambiguous tags
"	- Use ^i to jump back up the tag stack
command! MakeTags !ctags -R .
nnoremap <C-o> <C-]>
nnoremap <C-i> <C-t>

" -- AUTOCOMPLETE --
" The good stuff is documented in 'help: ins-completion'
"	- ^n for anything specified by the 'complete' option
"	- ^x^n for JUST this file
"	- ^x^f for filenames
"	- ^x^] for tags only
"	- Type something and use ^n and ^p to go back and forth in the suggestion list

" -- FILE BROWSING
runtime! autoload/netrw.vim
let g:netrw_banner=0 " disable banner
let g:netrw_browse_split=4 " open in prior window
let g:netrw_altv=1 " open splits to the right
let g:netrw_liststyle=3 " tree view
"let g:netrw_list_hide=netrw_gitignore#Hide()
"let g:netrw_list_hide.=',\(^\/\s\s\)\zs\.\S\+'
" :edit a folder to open in a file browser
" <CR>/v/t to open in an h-split/v-split/tab
" check 'help: netrw-browse-maps' for more mappings

" -- SNIPPETS --
" Read in a template file contests into the current file
nnoremap ,html :-1read $HOME/.vim/.skeleton.html<CR>3jwf>a

" -- COPY PASTE BETWEEN VIM BUFFERS --
" dependancy on xclip
vnoremap <C-c> :w !xclip -selection clipboard<CR><CR>
nnoremap <C-p> :r !xclip -selection clipboard -o<CR>

" Clear search highlighting after pressing escape
nnoremap <Esc> :nohl<CR><Esc>

" TODO: quickfix lists for vim

highlight CursorLine cterm=NONE     ctermbg=16   ctermfg=NONE guibg=darkgrey guifg=NONE
highlight DiffAdd    ctermfg=Green  ctermbg=NONE guifg=Green  guibg=NONE
highlight DiffChange ctermfg=Yellow ctermbg=NONE guifg=Yellow guibg=NONE
highlight DiffDelete ctermfg=Red    ctermbg=NONE guifg=Red    guibg=NONE
highlight DiffText   ctermfg=Blue   ctermbg=NONE guifg=Blue   guibg=NONE

set autoindent
set clipboard=unnamed
set cursorline
set expandtab
set hlsearch
set ignorecase
set incsearch
set list
set listchars=space:·
set mouse=a
set nowrap
set number
set relativenumber
set scrolloff=8
set shiftwidth=4
set showmatch
set signcolumn=yes
set smartcase
set smartindent
set smarttab
set softtabstop=4
set tabstop=4
set undofile
set wrap
