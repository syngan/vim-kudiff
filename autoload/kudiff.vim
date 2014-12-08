scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:diff = {}
let s:now = []

function! s:knormal(s) " {{{
  execute 'keepjumps' 'silent' 'normal!' a:s
endfunction " }}}

function! s:print_error(msg) " {{{
  echohl ErrorMsg
  try
    for m in split(a:msg, "\n")
      echomsg m
    endfor
  finally
    echohl None
  endtry
endfunction " }}}

function! kudiff#get() " {{{
  return s:diff
endfunction " }}}

function! kudiff#clear() " {{{
  let s:diff = {}
  let s:now = []
endfunction " }}}

function! kudiff#save(id) range " {{{
  let s = getline(a:firstline, a:lastline)
  let s:diff[a:id] = {
        \ 'first': a:firstline,
        \ 'last': a:lastline,
        \ 'bufnr': bufnr('%'),
        \ 'str': s,
        \ 'lineno': line('$')
        \}
endfunction " }}}

function! kudiff#update() " {{{
  " 元ファイルが更新されていないか確認する 
  if s:now == []
    call s:print_error('KuDiff: KuDiffDo has not been executed')
    return -1
  endif
  for n in s:now
    let d = s:diff[n]
    let lines = getbufline(d.bufnr, d.first, d.last)
    if lines != d.str
      call s:print_error('KuDiff: original buffere is updated.')
      return -1
    endif
  endfor

  " 実行. 後ろから.
  for i in (s:diff[s:now[0]].first < s:diff[s:now[1]].last ? [1,0] : [0,1])
    let n = s:now[i]
    let d = s:diff[n]
    let lines = getbufline(d.kubufnr, 1, '$')
    execute printf(':buffer %d', d.bufnr)
    execute printf(':%d,%ddelete _', d.first, d.last)
    let regbak = [getreg('"'), getregtype('"')]
    try
      call setreg('"', lines, 'V')
      call s:knormal(printf('%dGP', d.first))
    finally
      call setreg('"', regbak[0], regbak[1])
    endtry
  endfor

  return 0
endfunction " }}}

function! kudiff#do(d1, d2) " {{{
  for x in [[a:d1, 1], [a:d2, 2]]
    if !has_key(s:diff, x[0])
      if x[0] == x[1]
        call s:print_error(printf('KuDiff: KuDiff%d has not been executed', x[0]))
      else
        call s:print_error(printf('KuDiff: %s has not been saved', string(x[0])))
      endif
      return -1
    endif
  endfor
  if s:diff[a:d1].bufnr != s:diff[a:d2].bufnr
    call s:print_error('KuDiff: :vimdiff should be used')
    return
  endif
  " ku に重複があるときは未対応
  if s:diff[a:d1].first <= s:diff[a:d2].last &&
  \  s:diff[a:d2].first <= s:diff[a:d1].last ||
  \  s:diff[a:d1].first >= s:diff[a:d2].last &&
  \  s:diff[a:d2].first >= s:diff[a:d1].last
    call s:print_error('KuDiff: overlap')
    return -1
  endif

  if s:now != []
    call s:print_error('KuDiff: executing: call kudiff#clear()')
    return -1
  endif

  let s:now = [a:d1, a:d2]
  for i in range(2)
    let d = s:now[i]
    if i == 0
      tabnew
    else
      leftabove vnew
    endif

    call setline(1, s:diff[d]["str"])
    diffthis
    let s:diff[d].kubufnr = bufnr('%')
    setlocal noswapfile bufhidden=hide
    let b:kudiff_id = d
    setlocal nomodified
  endfor

  return 0
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
