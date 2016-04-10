" Save/Load Macro {
if !exists('g:MacroManagerDir')
  let g:MacroManagerDir = $HOME.'/.nvim/macros'
endif

if !exists('g:MacroManagerLoaded')
  let g:MacroManagerLoaded = {}
endif

if !exists('g:MacroManagerLayout')
  let g:MacroManagerLayout = exists('g:fzf_layout') ? g:fzf_layout : { 'down': '~40%' }
endif

function! s:neovim_fix()
  if has('nvim')
    call feedkeys('A')
  endif
endfunction

function! MacroDirectorySink(lines)
  let [ dir; rest ] = a:lines
  call s:list_macros(dir)
  return s:neovim_fix()
endfunction

function! s:recover_list()
  if s:last_list_call == 'all'
    call s:list_all_macros()
  else
    call s:list_macros()
  endif
  return s:neovim_fix()
endfunction

function! ListMacrosSink(lines)
  if len(a:lines) < 2
    return
  endif

  let [ key, item; rest ] = a:lines

  let match_item = matchlist(item, '<\(\w*\)> \(.*\)')
  let [ ignore, ft, final_name; rest ] = len(match_item) > 2 ? match_item : [ 0, &ft, item, 0 ]

  let path = g:MacroManagerDir.'/'.ft
  let file = path.'/'.final_name
  "call input('ft: '.ft.' path: '.path.' item: '.item)

  if key == 'ctrl-h'
    call input("\nMacro Manager Help".
      \ "\nctrl-a - all".
      \ "\nctrl-d - delete".
      \ "\nctrl-e - edit".
      \ "\nctrl-f - make function".
      \ "\nctrl-u - change dir".
      \ "\n\nPress Enter to Continue")
    return s:recover_list()
  elseif key == 'ctrl-a'
    return s:list_all_macros()
  elseif key == 'ctrl-d'
    let response = input('Are you sure you want to delete '.final_name.'? Type [Y] to delete> ')
    if response == 'y' || response == 'Y'
      call system('rm '.file)
    endif
    return s:recover_list()
  elseif key == 'ctrl-e'
    exe "e ".file
  elseif key == 'ctrl-f'
    let data = join(readfile(file), "\n")
    let fileContent = "function! Macro_".final_name."()\n\texe \"normal! ".data."\"\nendfunction"
    let newPath = file.'.vim'
    call writefile(split(fileContent, "\n"), newPath)
    exe "e ".newPath
    return
  else key == 'ctrl-u'
    return s:macro_directory()

  let register = input('Register> ')
  if len(register) > 1
    return input('Macro can only be saved to a one char name')
  endif
  return s:load_macro(final_name, register, ft)

endfunction

function! s:get_all_macros_in_dir(dir, dir_ft)
  let func = a:dir_ft == &ft ? 'fnamemodify(v:val, ":t")' : '"<".a:dir_ft."> ".fnamemodify(v:val, ":t")'
  return map(split(globpath(a:dir, '*'), '\n'), func)
endfunction

function! s:get_macro_dirs()
  return filter(split(globpath(g:MacroManagerDir, '*'), '\n'), 'isdirectory(v:val)')
endfunction

function! s:fzf_base(prompt, source, sink, ...)

  let restOptions = exists('a:1') ? ' '.a:1 : ''

  return fzf#run(extend({
    \ 'source': a:source,
    \ 'sink*': function(a:sink),
    \ 'options': '--ansi --prompt="'.a:prompt.'> "'.
      \ ' --tiebreak=index'.restOptions,
    \ }, g:MacroManagerLayout))

endfunction

"all for now
function! s:list_loaded_macros()
  echo g:MacroManagerLoaded
endfunction

function! s:list_macros(...)
  let s:last_list_call = 'file'
  if exists('a:1')
    let dir = a:1
    let dir_ft = fnamemodify(dir, ':p:h:t')
  else
    let dir = g:MacroManagerDir.'/'.&ft
    let dir_ft = &ft
  endif
  let files = s:get_all_macros_in_dir(dir, dir_ft)
  return s:fzf_base('Macro', files, 'ListMacrosSink', '+m --expect=ctrl-a,ctrl-d,ctrl-e,ctrl-f,ctrl-h,ctrl-l,ctrl-u')
endfunction

function! s:list_all_macros()
  let s:last_list_call = 'all'
  let dirs = s:get_macro_dirs()
  let files = []
  for dir in dirs
    call extend(files, s:get_all_macros_in_dir(dir, fnamemodify(dir, ':p:h:t')))
  endfor
  return s:fzf_base('All Macros', files, 'ListMacrosSink', '+m --expect=ctrl-d,ctrl-e,ctrl-f,ctrl-l,ctrl-h')
endfunction

function! s:save_macro(name, file)
  let content = eval('@'.a:name)
  if !empty(content)
    let file_macro_dir = g:MacroManagerDir.'/'.&ft
    call system('mkdir -p '.file_macro_dir)
    call writefile(split(content, "\n"), file_macro_dir.'/'.a:file)
    let g:MacroManagerLoaded[a:name] = a:file
    echom len(content) . " bytes save to ". a:file
  endif
endfunction

function! s:load_macro(file, name, ...)
  let ft = exists('a:1') ? a:1 : &ft
  let file_path = g:MacroManagerDir.'/'.ft.'/'.a:file
  call input('file_path: '.file_path)
  if fnamemodify(a:file, ':e') == 'vim'
    exe "source ".file_path
    let function_name = 'Macro_'.fnamemodify(a:file, ':r')
    call setreg(a:name, ':call '.function_name."()\n", 'c')
    call input("Function ".function_name." loaded to @". a:name."\nPress Enter to continue")
  else
    let data = join(readfile(file_path), "\n")
    call setreg(a:name, data, 'c')
    let g:MacroManagerLoaded[a:name] = a:file
    echom "Macro loaded to @". a:name
  endif
endfunction

function! s:macro_directory()
  let dirs = s:get_macro_dirs()
  return s:fzf_base('Change Macro Dir', dirs, 'MacroDirectorySink')
endfunction

command! -nargs=* SaveMacro call <SID>save_macro(<f-args>)
command! -nargs=* LoadMacro call <SID>load_macro(<f-args>)
command! -nargs=* ListMacros call <SID>list_macros(<f-args>)
command! -nargs=* ListAllMacros call <SID>list_all_macros(<f-args>)
command! -nargs=* ListLoadedMacros call <SID>list_loaded_macros(<f-args>)
" }

