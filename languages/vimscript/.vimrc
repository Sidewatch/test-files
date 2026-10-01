" ── Comments ───────────────────────────────────────────────
" ~/.vimrc — a complete Vim script showcase for a warehouse editing setup.
" TODO: split into plugin files. FIXME: neovim differences.
"" Double-quote comment
set nocompatible             " trailing comment after a command
scriptencoding utf-8

" ── Options ────────────────────────────────────────────────
filetype plugin indent on
syntax enable
set number relativenumber
set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
set ignorecase smartcase incsearch hlsearch
set splitright splitbelow
set undofile undodir=~/.vim/undo//
set listchars=tab:»·,trail:·,nbsp:␣
set wildignore+=*.o,*.pyc,node_modules/**
set statusline=%f\ %m%r%=%l/%L\ %p%%
set guifont=JetBrains\ Mono:h13
set background=dark
set nowrap noswapfile nobackup
set updatetime=250 timeoutlen=500
set mouse=a clipboard=unnamed
set foldmethod=indent foldlevel=99
set viminfo='100,<50,s10,h
set path+=**
set nolist! number? hlsearch&
set t_Co=256

" ── Variables and scoping ──────────────────────────────────
let mapleader = " "
let maplocalleader = ","
let g:warehouse_name = 'Acme Warehouse'
let g:reorder_point = 25
let g:ratio = 0.75
let g:sci = 1.5e-3
let g:hex = 0xFF
let g:octal = 0o755
let g:binary = 0b1010
let g:negative = -42
let s:script_var = "script local"
let b:buffer_var = 1
let w:window_var = 2
let t:tab_var = 3
let l:local_var = 4
let v:errmsg = ''
let $EDITOR = 'vim'
let &tabstop = 4
let &l:shiftwidth = 2
let @a = 'register contents'
let @/ = 'search'
let g:list = [1, 2, 3, 'four', [5, 6]]
let g:dict = {'sku': 'WGT-100', 'qty': 12, 'nested': {'a': 1}}
let g:lit_dict = #{sku: 'WGT-100', qty: 12}
let g:blob = 0z0123.ABCD
let g:nothing = v:null
let g:yes = v:true
let g:no = v:false
let [a, b] = [1, 2]
let [x; rest] = [1, 2, 3]
let g:str_single = 'it''s single quoted'
let g:str_double = "double \"quoted\" with \t tab, \n newline, é, \x41, \<Esc>, \<C-w>, \e"
let g:str_interp = $"item {g:warehouse_name} has {len(g:list)} entries"
let g:heredoc =<< trim END
  heredoc line one
  heredoc line two with "quotes"
END
const s:LIMIT = 100
unlet g:no
lockvar g:reorder_point

" ── Operators ──────────────────────────────────────────────
let n = 1 + 2 - 3 * 4 / 5 % 6
let n += 1 | let n -= 1 | let n *= 2 | let n /= 2 | let n %= 7 | let s = 'a' . 'b' | let s .= 'c' | let s ..= 'd'
let s = 'a' .. 'b'
let t = n > 1 ? 'big' : 'small'
let e = n ?? 'default'
let c = n == 1 || n != 2 && n < 3 || n > 4 || n <= 5 || n >= 6
let c = 'abc' =~ 'b' || 'abc' !~ 'x' || 'a' ==# 'A' || 'a' ==? 'A' || 'a' ># 'b' || 'a' <? 'b'
let c = 'a' is 'a' || 'a' isnot 'b' || 'a' =~# 'a' || 'a' !~? 'b'
let c = !n
let c = -n
let c = list[0] . dict.sku . dict['qty'] . list[1:2] . list[-1]

" ── Mappings ───────────────────────────────────────────────
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <silent> <Esc> :nohlsearch<CR>
inoremap jk <Esc>
vnoremap < <gv
vnoremap > >gv
xnoremap <leader>y "+y
onoremap in( :<C-u>normal! f(vi(<CR>
cnoremap <C-a> <Home>
tnoremap <Esc> <C-\><C-n>
nmap <buffer> <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
nnoremap <nowait> <unique> <script> <silent> <S-F5> :call Reload()<CR>
nnoremap <C-h> <C-w>h
nnoremap <A-j> :m .+1<CR>==
nnoremap <D-s> :w<CR>
nnoremap <F5> :make<CR>
nnoremap <leader>f :Files<space><CR>
inoremap <C-Space> <C-x><C-o>
nnoremap <Plug>(warehouse-run) :call warehouse#Run()<CR>
noremap <leader>r <Cmd>echo "hi"<CR>
map <ScriptCmd>x y
unmap <leader>z
iabbrev teh the
cabbrev W w
command! -nargs=* -complete=file -bang -range=% Stock call s:Stock(<f-args>)
command! -bar -bang Wipe :%bwipeout<bang>
command! -nargs=1 -complete=customlist,s:Complete Item echo <q-args>

" ── Functions ──────────────────────────────────────────────
function! s:StripTrailing() abort
  let l:save = winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(l:save)
endfunction

function! Describe(sku, qty, ...) abort range dict closure
  if a:0 > 0
    return a:sku . ': ' . a:qty . ' (' . a:1 . ')'
  endif
  return printf('%s: %d left', a:sku, a:qty)
endfunction

function! s:Complete(ArgLead, CmdLine, CursorPos) abort
  return filter(['WGT-100', 'GDG-200', 'GZM-300'], 'v:val =~ "^" . a:ArgLead')
endfunction

function! s:Stock(...) abort
  let l:total = 0
  for l:item in g:list
    if type(l:item) == v:t_number
      let l:total += l:item
    elseif type(l:item) == v:t_string
      continue
    else
      break
    endif
  endfor
  let l:i = 0
  while l:i < 3
    let l:i += 1
    if l:i == 2 | continue | endif
  endwhile
  for [l:key, l:val] in items(g:dict)
    echo l:key . '=' . string(l:val)
  endfor
  try
    throw 'stock-error'
  catch /^stock-/
    echohl ErrorMsg | echomsg 'caught: ' . v:exception | echohl None
  catch /.*/
    echoerr v:exception
  finally
    echo 'done'
  endtry
  return l:total
endfunction

def Add(a: number, b: number = 1): number
  var sum: number = a + b
  return sum
enddef

def g:Typed(items: list<string>, opts: dict<any> = {}): string
  return join(items, ', ')
enddef

" ── Lambdas, builtins, expression registers ────────────────
let F = {x -> x * 2}
let G = {a, b -> a + b}
let mapped = map(copy(g:list), {_, v -> v})
let H = function('Describe', ['WGT-100'])
let S = funcref('s:StripTrailing')
let result = call('Describe', ['GDG-200', 40])
let words = split('a b c', ' ')
let joined = join(words, ',')
let up = toupper('abc') . tolower('ABC') . substitute('a-b', '-', '+', 'g') . matchstr('abc', 'b') . strlen('abc')
let exists_ = exists('g:warehouse_name') && has('nvim') && has('gui_running') && executable('git') && filereadable(expand('~/.vimrc'))
let cwd = getcwd() . expand('%:p:h') . fnamemodify('file.txt', ':t:r') . system('echo hi') . line('.') . col('.')
let now = strftime('%Y-%m-%d %H:%M') . localtime()
echo "evaluating: " . eval('1 + 2')
execute 'normal! gg=G'
execute "set tabstop=" . 4
normal! zz
normal gg
redir => output | silent! ls | redir END
silent! write
silent execute '!echo hi'
echo has_key(g:dict, 'sku') ? 'yes' : 'no'

" ── Autocommands ───────────────────────────────────────────
augroup trailing
  autocmd!
  autocmd BufWritePre *.swift,*.py,*.md call <SID>StripTrailing()
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
  autocmd FileType python,ruby setlocal shiftwidth=2 tabstop=2
  autocmd FileType markdown setlocal spell wrap | nnoremap <buffer> <leader>p :!open %<CR>
  autocmd BufNewFile,BufRead *.stock setfiletype stock
  autocmd VimEnter * ++once echo 'ready'
  autocmd User WarehouseLoaded nested echo 'loaded'
  autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  autocmd CursorHold,CursorHoldI * checktime
augroup END

" ── Conditionals, filetypes, plugins ───────────────────────
if has('gui_running') | set guifont=JetBrains\ Mono:h13 | endif
if has('nvim')
  set termguicolors
elseif has('win32') || has('win64')
  set shell=cmd.exe
else
  set shell=/bin/zsh
endif
if !isdirectory(expand('~/.vim/undo'))
  call mkdir(expand('~/.vim/undo'), 'p', 0700)
endif

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
call plug#end()

colorscheme desert
highlight Normal ctermbg=NONE guibg=NONE
highlight link StockWarning WarningMsg
highlight! StockError ctermfg=Red guifg=#ff0000 cterm=bold gui=bold,underline
hi Comment cterm=italic
sign define stock text=!! texthl=Error
match ErrorMsg /\s\+$/
syntax match StockSku /\<[A-Z]\{3}-\d\+\>/ contained containedin=ALL
syntax keyword StockKeyword reorder restock
syntax region StockString start=/"/ skip=/\\"/ end=/"/ oneline
syntax cluster StockAll contains=StockSku,StockKeyword
let g:loaded_warehouse = 1

" ── Line continuation, comments and special syntax ─────────
let g:long_list = [
      \ 'first',
      \ 'second',
      \ ]
let g:long_dict = {
      \ 'a': 1,
      \ 'b': 2,
      "\ a comment inside a continued block
      \ }
let g:long_expr = 1
      \ + 2
      \ + 3
command! -nargs=? Long
      \ call s:Stock(<f-args>)

" ── More echo, messages and display commands ───────────────
echo 'plain echo' "with comment"
echon 'no newline'
echomsg 'message ' . g:warehouse_name
echoerr 'error message'
echohl WarningMsg | echo 'highlighted' | echohl None
echoconsole 'console'
echowindow 'popup message'
echo printf('%-10s|%5d|%05.1f|%x|%o|%b|%e|%c|%%', 'sku', 42, 3.14, 255, 8, 5, 1.5, 65)
echo "multiple" 'args' 1 2.5 [1, 2] {'a': 1}
call confirm('Really?', "&Yes\n&No", 2)
call input('Prompt: ', 'default', 'file')
sleep 100m
redraw!
redrawstatus
messages
registers
marks
jumps
changes
undolist
ls!
buffers
scriptnames
version
history search
digraphs
let v = inputlist(['Select:', '1. one', '2. two'])

" ── Windows, tabs, buffers, quickfix ───────────────────────
split | vsplit | new | vnew | tabnew | tabclose | only | close
wincmd h | wincmd j | wincmd k | wincmd l | wincmd w | wincmd p | wincmd =
resize +5 | vertical resize 30
buffer 1 | bnext | bprevious | bfirst | blast | bdelete | bwipeout
tabnext | tabprevious | tabfirst | tablast | tabmove 0
edit! % | enew | write | wall | update | saveas | quit! | qall! | wq | xit
cd %:p:h | lcd %:p:h | tcd %:p:h | pwd
copen | cclose | cnext | cprevious | cfirst | clast | lopen | lclose
vimgrep /pattern/gj **/*.swift | grep -r TODO . | make | cexpr system('ls')
arglocal | argadd file | args *.md | argdo %s/a/b/ge | windo set nonumber | bufdo update | tabdo set cursorline
mksession! Session.vim | mkview | loadview | oldfiles
mark a | delmarks a | k
normal! gg
fold | foldopen | foldclose | %foldopen!
1,10fold
let @+ = @"
yank | put | delete | undo | redo | later 10s | earlier 1f

" ── Ex ranges, substitute flags and patterns ───────────────
%s/\<teh\>/the/ge
'<,'>s/\v(\w+)\s+(\w+)/\2 \1/g
1,$s#/old/path#/new/path#gc
.,+3s/^/# /
g/^\s*$/d
v/\S/d
g!/pattern/normal! Atext
global/TODO/p
5,10>
5,10<
.,$j
/pattern/;+2d
?pattern?,.m0
:*s/a/b/
:@a
:&&
:~
silent! %s/\s\+$//e
keeppatterns %s/foo/bar/ge
keepjumps normal! G
keepmarks keepalt edit other
lockmarks silent write
noautocmd write
let pat = '\v^(foo|bar)\d{2,}$' | let pat2 = '\c\<word\>' | let pat3 = '\%(group\)\@<=x\_.*'
let pat4 = '[[:alpha:][:digit:]]\+' . '\%[ab]' . '\{-1,}' . '~' . '\zsstart\zeend'

" ── Settings: every form ───────────────────────────────────
set autoindent smartindent cindent
set noexpandtab expandtab!
set invnumber
set tw=80 wm=0 fo+=t fo-=o
set tags=./tags;,tags
set dictionary+=/usr/share/dict/words
set wildmode=longest:full,full wildmenu
set completeopt=menu,menuone,noselect
set shortmess+=c
set signcolumn=yes cmdheight=2
set scrolloff=8 sidescrolloff=8
set cursorline colorcolumn=80,120
set laststatus=2 showcmd ruler
set lazyredraw ttyfast
set backspace=indent,eol,start
set encoding=utf-8 fileencoding=utf-8 fileformats=unix,dos
set spelllang=en_gb spell
set whichwrap+=<,>,h,l
set matchpairs+=<:>
set keywordprg=man
set formatprg=prettier\ --stdin-filepath\ %
set errorformat=%f:%l:%c:\ %m
set makeprg=swift\ build
set grepprg=rg\ --vimgrep
setlocal spell
setglobal nowrap
set cpo&vim
set all&
set termguicolors t_ut=
set <F13>=^[[1;2P

" ── Events, patterns and nested autocommands ───────────────
augroup warehouse
  autocmd!
  autocmd BufEnter,BufLeave,BufWinEnter,BufWinLeave,BufReadPre,BufWritePost,BufDelete *.vim echo 'buffer event'
  autocmd FileType * setlocal formatoptions-=cro
  autocmd InsertEnter * set norelativenumber
  autocmd InsertLeave * set relativenumber
  autocmd CmdlineEnter,CmdlineLeave : echo 'cmdline'
  autocmd ColorScheme * highlight Normal guibg=NONE
  autocmd WinEnter,WinLeave,TabEnter,TabLeave * redraw
  autocmd QuickFixCmdPost [^l]* cwindow
  autocmd VimLeavePre,VimResized,FocusGained,FocusLost,ShellCmdPost * checktime
  autocmd SourcePre,SourcePost *.vim echo 'sourcing'
  autocmd FileReadCmd,FileWriteCmd,BufReadCmd,BufWriteCmd remote://* call s:Remote()
  autocmd TermOpen,TermClose,TermEnter,TermLeave * setlocal nonumber
  autocmd OptionSet number echo 'number changed'
  autocmd User CustomEvent doautocmd <nomodeline> BufRead
augroup END
doautoall BufRead
doautocmd User CustomEvent

" ── Vim9 script definitions (legacy-script compatible) ─────
def Vim9Func(name: string, count: number = 1, ...rest: list<any>): list<string>
  var result: list<string> = []
  for i in range(count)
    add(result, $'{name}-{i}')
  endfor
  const limit = 3
  final mutable = [1]
  if len(result) > limit | return [] | endif
  return result
enddef

def g:Exported(): void
  echo 'exported'
enddef

" ── Special keys and key notation ──────────────────────────
nnoremap <Up> <Down>
nnoremap <Left> <Right>
nnoremap <Home> <End>
nnoremap <PageUp> <PageDown>
nnoremap <Insert> <Del>
nnoremap <BS> <Tab>
nnoremap <CR> <NL>
nnoremap <Space> <Bar>
nnoremap <lt> <gt>
nnoremap <C-S-Left> <M-Right>
nnoremap <S-F1> <C-F12>
nnoremap <kPlus> <kMinus>
nnoremap <k0> <kEnter>
nnoremap <LeftMouse> <2-LeftMouse>
nnoremap <ScrollWheelUp> <C-ScrollWheelDown>
nnoremap <Nop> <Ignore>
nnoremap <SID>helper :call <SID>StripTrailing()<CR>
nnoremap <leader>a :echo "<cword> <cWORD> <cfile> <sfile> <afile> <abuf> <amatch> <slnum> <sflnum>"<CR>
nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <expr> <silent> k (v:count > 5 ? "m'" . v:count : '') . 'k'
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
nnoremap <script> <silent> <buffer> <nowait> <unique> <special> ,x :echo 'x'<CR>

" ── Version-guarded features and builtin functions ─────────
if v:version >= 900 && has('patch-9.0.1000')
  let g:modern = v:true
endif
if exists('+termguicolors') && exists(':terminal') && exists('*strftime') && exists('##TextYankPost')
  let g:features = 1
endif
let funcs = abs(-1) . acos(1) . add([], 1) . and(1, 3) . append(0, 'x') . argc() . argv(0) . asin(1) . atan(1) . bufnr('%')
let funcs = byte2line(1) . ceil(1.5) . changenr() . char2nr('a') . cindent('.') . col('.') . complete_add('x') . copy([]) . cos(1) . count([1], 1)
let funcs = cursor(1, 1) . deepcopy({}) . did_filetype() . empty([]) . escape('a', 'a') . exp(1) . expand('%') . extend([], []) . feedkeys('x') . filter([], 1)
let funcs = float2nr(1.5) . floor(1.5) . fnameescape('a') . foldlevel('.') . get([], 0) . getbufline(1, 1) . getline('.') . getpos('.') . getreg('a') . glob('*')
let funcs = has_key({}, 'a') . histadd('cmd', 'x') . hlID('Normal') . indent('.') . index([], 1) . insert([], 1) . invert(1) . isdirectory('.') . items({}) . len([])
let funcs = line2byte(1) . log(1) . map([], 1) . match('a', 'a') . matchadd('Error', 'x') . max([1]) . min([1]) . mode() . nr2char(65) . or(1, 2)
let funcs = pow(2, 3) . range(3) . readfile('f') . remove([], 0) . repeat('a', 2) . resolve('.') . reverse([]) . round(1.5) . search('x') . setline(1, 'x')
let funcs = shellescape('x') . sin(1) . sort([]) . sqrt(4) . str2nr('1') . stridx('a', 'a') . strpart('abc', 1) . strwidth('x') . tr('a', 'a', 'b') . trunc(1.5)
let funcs = type(1) . uniq([]) . values({}) . virtcol('.') . visualmode() . win_getid() . winnr() . writefile([], 'f') . xor(1, 2) . json_encode({}) . json_decode('{}')
let funcs = timer_start(100, {-> 0}) . job_start(['ls']) . ch_open('localhost:80') . term_start('zsh') . popup_create('x', {}) . prop_add(1, 1, {'type': 't'}) . matchaddpos('Error', [[1]])
let funcs = nvim_get_current_buf() . luaeval('1 + 1') . getenv('HOME') . setenv('X', 'y') . trim(' x ') . slice([1, 2], 1) . flatten([[1]]) . reduce([1], {a, b -> a + b}) . bufload(1)

" ── Embedded scripting and misc ────────────────────────────
lua << EOF
local sku = "WGT-100"
print(sku)
EOF
python3 << EOF
print("hello from python")
EOF
python3 import vim
let g:ruby = 1
runtime! plugin/**/*.vim
source ~/.vimrc.local
finish
" vim: set ft=vim sw=2 ts=2 et:
