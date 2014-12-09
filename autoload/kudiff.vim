scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! s:fname(i, bufopen) " {{{
  let d = s:diff[s:now[a:i]]
  if a:bufopen
    execute printf(':buffer %d', d.kubufnr)
  endif

  " from the specification of KuDiff,
  " bufname of save1 is always different from that of save2
  let fname = printf('[KD%d: %d,%d,%s]', a:i+1, d.first, d.last, bufname(d.bufnr))
  if bufname(fname) != ""
    :f `=fname`
  endif
  if a:bufopen
    setlocal nomodified
    diffthis
  endif
endfunction " }}}

function! s:knormal(s) " {{{
  execute 'keepjumps' 'silent' 'normal!' a:s
endfunction " }}}

function! s:print_error(msg) " {{{
  echohl ErrorMsg
  echomsg 'KuDiff: ' . a:msg
  echohl None
endfunction " }}}

function! s:exit() abort " {{{
  " @TODO Even if a buffer is splitted after :KuDiffShow,
  " all the buffers will be closed.

  only!
  call kudiff#clear()
endfunction " }}}

function! kudiff#get() " {{{
  return [s:diff, s:now]
endfunction " }}}

function! kudiff#clear() " {{{
  let s:diff = {}
  let s:now = []
endfunction " }}}

function! kudiff#save(id, force) range " {{{
  if !a:force && s:now != []
    call s:print_error('executing: call kudiff#clear()')
    return -1
  endif

  let s = getline(a:firstline, a:lastline)
  let s:diff[a:id] = {
        \ 'first': a:firstline,
        \ 'last': a:lastline,
        \ 'bufnr': bufnr('%'),
        \ 'str': s,
        \ 'lineno': line('$')
        \}
  return 0
endfunction " }}}

function! s:do_rep_chk() " {{{
  if s:now == []
    call s:print_error(':KuDiffShow has not been executed')
    return 0
  endif

  " check whether original buffer is updated
  for n in s:now
    let d = s:diff[n]
    if !bufexists(d.bufnr)
      call s:print_error('original buffer does not exist.')
      return 0
    endif
    let lines = getbufline(d.bufnr, d.first, d.last)
    if lines != d.str
      if n is 1 || n is 2
        call s:print_error(printf('original buffer is updated. Select range and do :KuDiffSave%d!', n))
      else
        call s:print_error(printf('original buffer is updated. Call kudiff#save(%s, 1)', string(n)))
      endif
      return 0
    endif
  endfor

  return 1
endfunction " }}}

function! kudiff#do_replace() " {{{

  if !s:do_rep_chk()
    return -1
  endif

  " 実行. 後ろから.
  " ここでエラーがでたらもうしらんよ.
  let regbak = [getreg('"'), getregtype('"')]
  let posbak = getpos('.')
  tabnew
  let closed = 0
  try
    let ids = (s:diff[s:now[0]].first < s:diff[s:now[1]].last ? [1,0] : [0,1])
    for i in range(2)
      let n = s:now[ids[i]]
      let d = s:diff[n]
      if !bufexists(d.kubufnr)
        let closed += 1
        continue
      endif
      let lines = getbufline(d.kubufnr, 1, '$')
      execute printf(':buffer %d', d.bufnr)
      execute printf(':%d,%ddelete _', d.first, d.last)
      call setreg('"', lines, 'V')
      if d.first < line('$')
        call s:knormal(printf('%dGP', d.first))
      else
        call s:knormal(printf('%dGp', d.first))
      endif

      " update
      let df = d.first + len(lines) - 1 - d.last
      let d.last = d.first + len(lines) - 1
      let d.str = lines
      if i == 1 && s:diff[s:now[0]].bufnr == s:diff[s:now[1]].bufnr
        let s:diff[s:now[ids[0]]].first += df
        let s:diff[s:now[ids[0]]].last += df
      endif
    endfor

    diffoff!
    for i in range(2)
      call s:fname(i, 1)
    endfor

    " avoid to call kudiff#clear from 'autocmd QuitPre'
    let n = s:now[0]
    let d = s:diff[n]
    execute printf(':buffer %d', d.bufnr)
  finally
    if closed < 2
      diffo!
    endif

    call setreg('"', regbak[0], regbak[1])
    :quit
    call setpos('.', posbak)
  endtry

  return 0
endfunction " }}}

function! s:show_chk(d1, d2) " {{{
  for x in [[a:d1, 1], [a:d2, 2]]
    if !has_key(s:diff, x[0])
      if x[0] == x[1]
        call s:print_error(printf('KuDiffSave%d has not been executed', x[0]))
      else
        call s:print_error(printf('%s has not been saved', string(x[0])))
      endif
      return 0
    endif
  endfor

  " ku に重複があるときは未対応
  if s:diff[a:d1].bufnr == s:diff[a:d2].bufnr && (
  \  s:diff[a:d1].first <= s:diff[a:d2].last &&
  \  s:diff[a:d2].first <= s:diff[a:d1].last ||
  \  s:diff[a:d1].first >= s:diff[a:d2].last &&
  \  s:diff[a:d2].first >= s:diff[a:d1].last)
    call s:print_error('overlap')
    return 0
  endif

  if s:now != []
    call s:print_error('executing: KuDiffClear')
    return 0
  endif

  return 1
endfunction " }}}

function! kudiff#show(d1, d2) " {{{

  if !s:show_chk(a:d1, a:d2)
    return []
  endif

  let s:now = [a:d1, a:d2]
  for i in range(2)
    let d = s:now[i]
    if i == 0
      tabnew
    else
      leftabove vnew
    endif
    call s:fname(i, 0)

    call setline(1, s:diff[d]["str"])
    diffthis
    let s:diff[d].kubufnr = bufnr('%')
    setlocal noswapfile bufhidden=delete
    autocmd BufWriteCmd <buffer> nested call kudiff#do_replace()
    autocmd QuitPre <buffer> call s:exit()
    let b:kudiff_id = d
    setlocal nomodified
  endfor

  return map(copy(s:now), 's:diff[v:val].kubufnr')
endfunction " }}}

call kudiff#clear()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
