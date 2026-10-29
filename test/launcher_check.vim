" test/launcher_check.vim - sourced by the editor that bin/vimgermantutor
" (or bin\vimgermantutor.cmd) started. Writes "result=ok" and some facts to
" $GERMANTUTOR_TEST_OUT, then quits.
scriptencoding utf-8

let s:out = []
let s:ok = 1
function! s:Fact(name, value, want) abort
  call add(s:out, a:name . '=' . a:value)
  if a:value !=# a:want
    let s:ok = 0
    call add(s:out, '  expected ' . a:name . '=' . a:want)
  endif
endfunction

try
  call s:Fact('lesson', exists('b:germantutor') ? b:germantutor.id : 'none', '1.2')
  let s:file = b:germantutor.file
  let s:original = readfile(s:file)
  let s:copy = expand('%:p')
  call s:Fact('is_copy', fnamemodify(s:copy, ':p') !=# fnamemodify(s:file, ':p'), 1)
  call s:Fact('same_text', getline(1, '$') ==# s:original, 1)
  call s:Fact('foldmethod', &l:foldmethod, 'marker')
  call s:Fact('fileencoding', &l:fileencoding, 'utf-8')
  call s:Fact('syntax', &l:syntax, 'germantutor')
  call s:Fact('backspace', &backspace, 'indent,eol,start')
  call setline(1, 'Diese Zeile ist geändert.')
  silent write
  call s:Fact('copy_written', readfile(s:copy)[0], 'Diese Zeile ist geändert.')
  call s:Fact('original_untouched', readfile(s:file) ==# s:original, 1)
catch
  let s:ok = 0
  call add(s:out, 'exception=' . v:exception)
endtry
call add(s:out, 'editor=' . (has('nvim') ? 'nvim' : 'vim'))
call add(s:out, 'result=' . (s:ok ? 'ok' : 'failed'))
call writefile(s:out, $GERMANTUTOR_TEST_OUT)
qall!
