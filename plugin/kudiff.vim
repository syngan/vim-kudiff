

if exists('g:loaded_kudiff')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 -range KuDiff1 :<line1>,<line2>call kudiff#save(1)
command! -nargs=0 -range KuDiff2 :<line1>,<line2>call kudiff#save(2)
command! -nargs=0 KuDiffDo       :call kudiff#do(1, 2)
command! -nargs=0 KuDiffUpdate   :call kudiff#update()
command! -nargs=0 KuDiffClear    :call kudiff#clear()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_kudiff = 1


" vim:set et ts=2 sts=2 sw=2 tw=0:
