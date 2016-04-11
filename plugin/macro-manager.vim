if exists('g:loaded_macro_manager') || &cp
  finish
endif
let g:loaded_macro_manager = 1

if !exists('g:MacroManagerDir')
  let g:MacroManagerDir = $HOME.'/.nvim/macros'
endif

if !exists('g:MacroManagerLoaded')
  let g:MacroManagerLoaded = {}
endif

if !exists('g:MacroManagerLayout')
  let g:MacroManagerLayout = exists('g:fzf_layout') ? g:fzf_layout : { 'down': '~40%' }
endif

if !exists('g:MacroManagerKeys')
  let g:MacroManagerKeys = {}
endif
let g:MacroManagerKeys = extend({
  \ 'all': 'a',
  \ 'delete': 'd',
  \ 'edit': 'e',
  \ 'makefunction': 'f',
  \ 'help': 'h',
  \ 'changedir': 'u'
  \ }, copy(g:MacroManagerKeys))

command! -nargs=* MMSave       call macro_manager#save(<f-args>)
command! -nargs=* MMLoad       call macro_manager#load(<f-args>)
command! -nargs=* MMList       call macro_manager#list()
command! -nargs=* MMListAll    call macro_manager#list_all()
command! -nargs=* MMListLoaded call macro_manager#list_loaded()

"nnoremap <unique> <Plug>MMSave       :call macro_manager#save()<CR>
"nnoremap <unique> <Plug>MMLoad       :call macro_manager#load()<CR>
nnoremap <unique> <Plug>MMList       :call macro_manager#list()<CR>
nnoremap <unique> <Plug>MMListAll    :call macro_manager#list_all()<CR>
nnoremap <unique> <Plug>MMListLoaded :call macro_manager#list_loaded()<CR>
