" ~/.vimrc — a compact, sensible setup.
set nocompatible
filetype plugin indent on
syntax enable

set number relativenumber
set tabstop=4 shiftwidth=4 expandtab
set ignorecase smartcase incsearch hlsearch
set splitright splitbelow
set undofile undodir=~/.vim/undo//

let mapleader = " "
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <silent> <Esc> :nohlsearch<CR>

" Strip trailing whitespace on save, keeping the cursor
function! s:StripTrailing() abort
  let l:save = winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(l:save)
endfunction
augroup trailing
  autocmd!
  autocmd BufWritePre *.swift,*.py,*.md call <SID>StripTrailing()
augroup END

if has("gui_running") | set guifont=JetBrains\ Mono:h13 | endif
