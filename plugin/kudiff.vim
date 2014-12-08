

if exists('g:loaded_kudiff')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 -range KuDiffSave1 :<line1>,<line2>call kudiff#save(1)
command! -nargs=0 -range KuDiffSave2 :<line1>,<line2>call kudiff#save(2)
command! -nargs=0 KuDiffShow         :call kudiff#show(1, 2)
command! -nargs=0 KuDiffDo           :call kudiff#do_replace()
command! -nargs=0 KuDiffClear        :call kudiff#clear()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_kudiff = 1


" vim:set et ts=2 sts=2 sw=2 tw=0:
