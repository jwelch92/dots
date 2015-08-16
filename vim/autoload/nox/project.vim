" autoload/nox/project.vim - Query project metadata from multiple sources
" Maintainer: Noah Frederick
"
" Common keys to query:
" - title
" - author
" - email
" - license
" - copyright
" - github
"
" These strategies are used in order:
" - Projectionist
" - TODO: Composer
" - TODO: Bower
" - TODO: Ruby Gems
" - Git
" - Use a placeholder

let s:strategies = {}

function! s:strategies.projectionist(key)
  if empty(b:projectionist)
    return ""
  endif

  let key = "project_" . a:key

  return get(projectionist#query(key), 0, ["", ""])[1]
endfunction

function! s:strategies.git(key)
  if !executable("git")
    return ""
  endif

  let key = a:key
  let value = system("git config --get project." . key)[0:-2]

  if value == ""
    if key == "author"
      let key = "name"
    endif

    let value = system("git config --get user." . key)[0:-2]
  endif

  return value
endfunction

function! s:strategies.placeholder(key)
  return "[project-" . a:key . "]"
endfunction

function! s:try_all_strategies(key)
  for [name, Strat] in items(s:strategies)
    let value = call(Strat, [a:key], {})

    if value != ""
      return value
    endif
  endfor
endfunction

""
" Query current buffer's project metadata by key.
function! nox#project#get(key)
  let value = s:try_all_strategies(a:key)

  if value == "[project-copyright]"
    let value = join(["©", strftime("%Y"), s:try_all_strategies("author")])
  endif

  return value
endfunction

""
" Get current buffer's project's root directory.
function! nox#project#root()
  if !empty(b:projectionist)
    return projectionist#path()
  endif

  if !empty(b:git_dir)
    return fnamemodify(b:git_dir, ":h")
  endif

  return getcwd()
endfunction

" vim: fdm=marker:sw=2:sts=2:et
