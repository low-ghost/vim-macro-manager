function! s:neovim_fix()
  if has('nvim')
    call feedkeys('A')
  endif
endfunction

function! s:directory_sink(lines)
  let [ dir; rest ] = a:lines
  call macro_manager#list(dir)
  return s:neovim_fix()
endfunction

function! s:recover_list()
  if s:last_list_call == 'all'
    call macro_manager#list_all()
  else
    call macro_manager#list()
  endif
  return s:neovim_fix()
endfunction

function! s:get_key(name)
  return 'ctrl-'.g:MacroManagerKeys[a:name]
endfunction

function! s:list_sink(lines)
  if len(a:lines) < 2
    return
  endif

  let [ key, item; rest ] = a:lines

  let match_item = matchlist(item, '<\(\w*\)> \(.*\)')
  let [ ignore, ft, final_name; rest ] = len(match_item) > 2 ? match_item : [ 0, &ft, item, 0 ]

  let path = g:MacroManagerDir.'/'.ft
  let file = path.'/'.final_name

  if key == s:get_key('help')
    call input("\nMacro Manager Help".
      \ "\n".s:get_key('all')." - all".
      \ "\n".s:get_key('delete')." - delete".
      \ "\n".s:get_key('edit')." - edit".
      \ "\n".s:get_key('makefunction')." - make function".
      \ "\n".s:get_key('changedir')." - change directory".
      \ "\n\nPress Enter to Continue")
    return s:recover_list()
  elseif key == s:get_key('all')
    return macro_manager#list_all()
  elseif key == s:get_key('delete')
    let response = input('Are you sure you want to delete '.final_name.'? Type [Y] to delete> ')
    if response == 'y' || response == 'Y'
      call system('rm '.file)
    endif
    return s:recover_list()
  elseif key == s:get_key('edit')
    exe "e ".file
    return
  elseif key == s:get_key('makefunction')
    let data = join(readfile(file), "\n")
    let fileContent = "function! Macro_".final_name."()\n\texe \"normal! ".data."\"\nendfunction"
    let newPath = file.'.vim'
    call writefile(split(fileContent, "\n"), newPath)
    exe "e ".newPath
    return
  elseif key == s:get_key('changedir')
    return macro_manager#list_directory()
  endif

  let register = input('Register> ')
  if len(register) > 1
    return input('Macro can only be saved to a one char name')
  endif
  return macro_manager#load(final_name, register, ft)

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
function! macro_manager#list_loaded()
  echo g:MacroManagerLoaded
endfunction

function! macro_manager#list(...)
  let s:last_list_call = 'file'
  if exists('a:1')
    let dir = a:1
    let dir_ft = fnamemodify(dir, ':p:h:t')
  else
    let dir = g:MacroManagerDir.'/'.&ft
    let dir_ft = &ft
  endif
  let files = s:get_all_macros_in_dir(dir, dir_ft)
  return s:fzf_base('Macro', files, 's:list_sink', '+m --expect=ctrl-a,ctrl-d,ctrl-e,ctrl-f,ctrl-h,ctrl-l,ctrl-u')
endfunction

function! macro_manager#list_all()
  let s:last_list_call = 'all'
  let dirs = s:get_macro_dirs()
  let files = []
  for dir in dirs
    call extend(files, s:get_all_macros_in_dir(dir, fnamemodify(dir, ':p:h:t')))
  endfor
  return s:fzf_base('All Macros', files, 's:list_sink', '+m --expect=ctrl-d,ctrl-e,ctrl-f,ctrl-l,ctrl-h')
endfunction

function! macro_manager#save(name, file)
  let content = eval('@'.a:name)
  if !empty(content)
    let file_macro_dir = g:MacroManagerDir.'/'.&ft
    call system('mkdir -p '.file_macro_dir)
    call writefile(split(content, "\n"), file_macro_dir.'/'.a:file)
    let g:MacroManagerLoaded[a:name] = a:file
    echom len(content) . " bytes save to ". a:file
  endif
endfunction

function! macro_manager#load(file, name, ...)
  let ft = exists('a:1') ? a:1 : &ft
  let file_path = g:MacroManagerDir.'/'.ft.'/'.a:file
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

function! macro_manager#list_directory()
  let dirs = s:get_macro_dirs()
  return s:fzf_base('Change Macro Dir', dirs, 's:directory_sink')
endfunction
