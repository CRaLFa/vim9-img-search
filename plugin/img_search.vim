if !has('vim9script')
    echoerr 'Vim >= 9 is required'
    finish
endif

vim9script

if exists('g:loaded_img_search')
    finish
endif
g:loaded_img_search = true

import autoload 'img_search.vim' as is

nnoremap <silent> <C-i> <ScriptCmd>is.SearchImage('normal')<CR>
xnoremap <silent> <C-i> <ScriptCmd>is.SearchImage('visual')<CR>
nnoremap <silent> <C-j> <ScriptCmd>is.ClearImage()<CR>
