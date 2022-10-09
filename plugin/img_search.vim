if !has('vim9script')
    echoerr 'Vim >= 9 is required'
    finish
endif

vim9script noclear
scriptencoding utf-8

if exists('g:loaded_img_search')
    finish
endif
g:loaded_img_search = true

import autoload 'img_search.vim' as is

nnoremap <silent> <Esc>i <ScriptCmd>is.SearchImage('normal')<CR>
nnoremap <silent> <Esc>b <ScriptCmd>is.ShowPrevImage()<CR>
nnoremap <silent> <Esc>n <ScriptCmd>is.ShowNextImage()<CR>
nnoremap <silent> <Esc>j <ScriptCmd>is.ClearImage()<CR>

xnoremap <silent> <Esc>i <ScriptCmd>is.SearchImage('visual')<CR>
