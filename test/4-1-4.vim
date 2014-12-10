scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:suite = themis#suite('4-1-4')
let s:assert = themis#helper('assert')

let s:debug = 1

function! s:suite.before()
  let s:lines = [
        \ "1234567890",
        \ "aaaaaaaaaaa",
        \ "bbbbbbbbbb",
        \ "cccccccccc",
        \ "dddddddddd",
        \ "eeeeeeeeee",
        \ "ffffffffff",
        \ "gggggggggg",
        \ "zzzzzzzzzzzzzzzz",
        \]
  let s:p1e = 3
  let s:pxs = 4
  let s:pxe = 4
  let s:p2s = 5
  lockvar s:lines
endfunction

function! s:suite.before_each()
  new
  call append(1, s:lines)
  1 delete _
  if s:debug
    call writefile(s:lines, "/tmp/hogeorg")
  endif
endfunction

function! s:suite.after_each()
  quit!
endfunction

function! s:prepare(idx)
  execute printf("1,%dKuDiffSave1", s:p1e+1)
  execute printf("%d,$KuDiffSave2", s:p2s+1)
  let s:bufs = kudiff#show(1, 2)
  call s:assert.not_equals(s:bufs, []) 

  if s:debug
    for i in range(2)
      while bufnr('%') != s:bufs[i]
        execute 'normal!' "\<C-w>w"
      endwhile
      call writefile(getline(1, line('$')), printf("/tmp/hoge%d", i))
    endfor
  endif

  while bufnr('%') != s:bufs[a:idx]
    execute 'normal!' "\<C-w>w"
  endwhile
endfunction

function! s:quit()
  while 1
    let n = bufnr('%')
    if n == s:bufs[0] || n == s:bufs[1]
      :quit
    else
      break
    endif
  endwhile

  if s:debug
    call writefile(getline(1, line('$')), '/tmp/hoge')
  endif
endfunction

function! s:check(list)
  call s:assert.equals(a:list, getline(1, line('$')))
  call s:assert.equals(len(a:list), line('$'))

  for i in range(len(a:list))
    call s:assert.equals(getline(i+1), a:list[i])
  endfor
endfunction

function! s:suite.topa0()
  call s:prepare(0)
  let str = "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"
  execute "normal!" "O" . str

  :w
  call s:quit()

  let list = [str] + s:lines
  call s:check(list)
endfunction

function! s:suite.topa1()
  call s:prepare(1)
  let str = "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"
  execute "normal!" "O" . str

  :w
  call s:quit()
  let list = s:lines[0 : s:p2s-1] + [str] + s:lines[s:p2s : ]
  call s:check(list)
endfunction


function! s:suite.bottoma0()
  call s:prepare(0)
  let str = "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"
  execute "normal!" "Go" . str

  :w
  call s:quit()
  let list = s:lines[0 : s:p1e] + [str] + s:lines[s:p1e+1 : ]
  call s:check(list)
endfunction

function! s:suite.bottoma1()
  call s:prepare(1)
  let str = "iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"
  execute "normal!" "Go" . str

  :w
  call s:quit()

  let list = s:lines + [str]
  call s:check(list)
endfunction

function! s:suite.vanish0()
  call s:prepare(0)

  :%delete _
  :w
  call s:quit()

  let list = [""] + s:lines[s:pxs :]
  call s:check(list)
endfunction

function! s:suite.vanish1()
  call s:prepare(1)

  :%delete _
  :w
  call s:quit()
  let list = s:lines[: s:pxe] + [""]
  call s:check(list)
endfunction

function! s:suite.topd0()
  call s:prepare(0)

  :1delete _
  :w
  call s:quit()

  call s:check(s:lines[1:])
endfunction

function! s:suite.topd1()
  call s:prepare(1)

  :1delete _
  :w
  call s:quit()

  let list = s:lines[: s:p2s-1] + s:lines[s:p2s+1 : ]
  call s:check(list)
endfunction

function! s:suite.midd0()
  call s:prepare(0)

  :2delete _
  :w
  call s:quit()

  let list = s:lines[0:0] + s:lines[2: ]
  call s:check(list)
endfunction

function! s:suite.midd1()
  call s:prepare(1)

  :2delete _
  :w
  call s:quit()

  let list = s:lines[: s:p2s] + s:lines[s:p2s+2: ]
  call s:check(list)
endfunction

function! s:suite.bottomd0()
  call s:prepare(0)

  :$delete _
  :w
  call s:quit()

  let list = s:lines[0 : s:p1e-1] + s:lines[s:p1e+1 : ]
  call s:check(list)
endfunction

function! s:suite.bottomd1()
  call s:prepare(1)

  :$delete _
  :w
  call s:quit()

  let list = s:lines[: -2]
  call s:check(list)
endfunction

call themis#func_alias({'test.kudiff.s:suit': s:suite})
call themis#func_alias({'test.kudiff.s:': s:})

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
