" autoload/germantutor.vim - lessons, launcher, progress, timer and display.
" Legacy Vimscript on purpose: one code base for Vim >= 8.2 and Neovim >= 0.9.
scriptencoding utf-8

let s:cpo_save = &cpo
set cpo&vim

let s:root = expand('<sfile>:p:h:h')

function! germantutor#Root() abort
  return s:root
endfunction

function! s:Error(msg) abort
  echohl ErrorMsg
  echomsg 'GermanTutor: ' . a:msg
  echohl None
endfunction

" Lessons ------------------------------------------------------------------

" All lessons, sorted by chapter and number.
" Each item: {'id': '1.2', 'chapter': 1, 'number': 2, 'file': ..., 'title': ...}
function! germantutor#Lessons() abort
  let lessons = []
  for file in glob(s:root . '/lessons/*.txt', 1, 1)
    let m = matchlist(fnamemodify(file, ':t'), '^\(\d\+\)-\(\d\+\)-')
    if empty(m)
      continue
    endif
    let lesson = {'chapter': str2nr(m[1]), 'number': str2nr(m[2]), 'file': file}
    let lesson.id = lesson.chapter . '.' . lesson.number
    let lesson.title = s:ReadTitle(file)
    call add(lessons, lesson)
  endfor
  return sort(lessons, function('s:CompareLessons'))
endfunction

function! s:CompareLessons(a, b) abort
  if a:a.chapter != a:b.chapter
    return a:a.chapter - a:b.chapter
  endif
  return a:a.number - a:b.number
endfunction

function! s:ReadTitle(file) abort
  for line in readfile(a:file, '', 8)
    let title = matchstr(line, '^\s*Lektion \d\+\.\d\+:\s*\zs.\{-}\ze\s*$')
    if title !=# ''
      return title
    endif
  endfor
  return fnamemodify(a:file, ':t:r')
endfunction

function! germantutor#Lesson(id) abort
  for lesson in germantutor#Lessons()
    if lesson.id ==# a:id
      return lesson
    endif
  endfor
  return {}
endfunction

" The lesson after a:id, or {} after the last one.
function! germantutor#Next(id) abort
  let lessons = germantutor#Lessons()
  for i in range(len(lessons) - 1)
    if lessons[i].id ==# a:id
      return lessons[i + 1]
    endif
  endfor
  return {}
endfunction

" Turns the argument of :GermanTutor into {'lesson': {...}, 'line': n}.
" Accepts '' (resume), '1.2', '01-2', 'next', 'weiter' or part of a file
" name such as 'genitiv'. Returns {} when nothing matches.
function! germantutor#Find(arg) abort
  let arg = substitute(a:arg, '^\s*\(.\{-}\)\s*$', '\1', '')
  let lessons = germantutor#Lessons()
  if empty(lessons)
    return {}
  endif
  if arg ==# ''
    return s:Resume(lessons)
  endif
  if arg ==? 'next' || arg ==? 'weiter'
    let current = exists('b:germantutor') ? b:germantutor.id
          \ : get(get(germantutor#LoadProgress(), 'last', {}), 'lesson', '')
    let next = current ==# '' ? lessons[0] : germantutor#Next(current)
    return empty(next) ? {} : {'lesson': next, 'line': 0}
  endif
  let m = matchlist(arg, '^0*\(\d\+\)[.-]0*\(\d\+\)$')
  if !empty(m)
    let lesson = germantutor#Lesson(str2nr(m[1]) . '.' . str2nr(m[2]))
    return empty(lesson) ? {} : {'lesson': lesson, 'line': 0}
  endif
  for lesson in lessons
    if stridx(tolower(fnamemodify(lesson.file, ':t')), tolower(arg)) >= 0
      return {'lesson': lesson, 'line': 0}
    endif
  endfor
  return {}
endfunction

" Where to go on a plain :GermanTutor: the last lesson at the last line, or
" the next lesson when the last one is complete.
function! s:Resume(lessons) abort
  let progress = germantutor#LoadProgress()
  let last = get(progress, 'last', {})
  let lesson = germantutor#Lesson(get(last, 'lesson', ''))
  if empty(lesson)
    return {'lesson': a:lessons[0], 'line': 0}
  endif
  let entry = get(get(progress, 'lessons', {}), lesson.id, {})
  let total = get(entry, 'total', 0)
  if total > 0 && len(get(entry, 'solved', [])) >= total
    let next = germantutor#Next(lesson.id)
    if !empty(next)
      return {'lesson': next, 'line': 0}
    endif
  endif
  return {'lesson': lesson, 'line': get(last, 'line', 0)}
endfunction

function! germantutor#Complete(lead, cmdline, pos) abort
  let ids = map(germantutor#Lessons(), 'v:val.id') + ['next']
  return filter(ids, 'stridx(v:val, a:lead) == 0')
endfunction

" Starting a lesson ----------------------------------------------------------

function! germantutor#Start(arg) abort
  if !has('nvim') && &encoding !=# 'utf-8'
    call s:Error("Bitte zuerst 'set encoding=utf-8' (in your vimrc).")
    return
  endif
  let target = germantutor#Find(a:arg)
  if empty(target)
    call s:Error('Diese Lektion gibt es nicht: "' . a:arg
          \ . '". :GermanTutorProgress zeigt alle Lektionen.')
    return
  endif
  let lesson = target.lesson
  if get(g:, 'germantutor_launcher', 0)
    call s:LauncherDefaults()
  endif

  " A fresh copy every time: the original lesson is never edited.
  let copy = tempname() . '-' . fnamemodify(lesson.file, ':t')
  call writefile(readfile(lesson.file), copy)

  if exists('b:germantutor')
    let cmd = 'edit!'
  elseif &modified || &buftype !=# ''
    let cmd = 'tabedit'
  else
    let cmd = 'edit'
  endif
  execute 'silent' cmd '++enc=utf-8' fnameescape(copy)

  let b:germantutor = {'id': lesson.id, 'file': lesson.file,
        \ 'title': lesson.title}
  call s:SetOptions()
  call germantutor#check#Attach(b:germantutor)

  if target.line > 1 && target.line <= line('$')
    execute target.line
    normal! zv
  endif
  call s:RememberPosition()
  call s:EnsureHelpTags()
  echo 'Lektion ' . lesson.id . ': ' . lesson.title
endfunction

" The shell launcher starts the editor without a vimrc. These settings make
" that bare editor friendly for a beginner.
function! s:LauncherDefaults() abort
  if get(s:, 'launcher_done', 0)
    return
  endif
  let s:launcher_done = 1
  set backspace=indent,eol,start showcmd ruler incsearch nojoinspaces
  syntax on
endfunction

function! s:SetOptions() abort
  if &l:fileencoding !=# 'utf-8'
    setlocal fileencoding=utf-8
  endif
  setlocal nobomb nomodeline noswapfile bufhidden=wipe textwidth=0 nospell
  setlocal filetype=germantutor
  setlocal foldmethod=marker foldmarker={{{,}}} foldlevel=0 foldenable
  setlocal foldtext=germantutor#FoldText()
  if exists('+signcolumn')
    setlocal signcolumn=yes
  endif
  let &l:statusline = ' %{germantutor#StatusTitle()}%=%{germantutor#StatusTimer()}'
        \ . '%{germantutor#StatusTally()}  %l/%L '
  if &laststatus < 2
    set laststatus=2
  endif
  setlocal nomodified

  augroup germantutor_position
    autocmd! * <buffer>
    autocmd BufLeave,BufWinLeave <buffer> call s:RememberPosition()
  augroup END
  augroup germantutor_leave
    autocmd!
    autocmd VimLeavePre * if exists('b:germantutor') | call s:RememberPosition() | endif
  augroup END
endfunction

" :help germantutor works even when the plugin was installed by copying.
function! s:EnsureHelpTags() abort
  let doc = s:root . '/doc'
  if isdirectory(doc) && !filereadable(doc . '/tags') && filewritable(doc) == 2
    silent! execute 'helptags' fnameescape(doc)
  endif
endfunction

" Display ------------------------------------------------------------------

function! germantutor#FoldText() abort
  let text = substitute(getline(v:foldstart), '\s*{{{\d*\s*$', '', '')
  return text . '  (zo)'
endfunction

function! germantutor#StatusTitle() abort
  if !exists('b:germantutor')
    return ''
  endif
  return 'Lektion ' . b:germantutor.id . ': ' . b:germantutor.title
endfunction

function! germantutor#Ascii() abort
  return get(g:, 'germantutor_ascii', 0) || &encoding !=# 'utf-8'
endfunction

function! germantutor#StatusTally() abort
  if !exists('b:germantutor') || !has_key(b:germantutor, 'blocks')
        \ || empty(b:germantutor.blocks)
    return ''
  endif
  let done = len(b:germantutor.solved) . '/' . len(b:germantutor.blocks)
  return done . (germantutor#Ascii() ? ' ok' : ' ✓')
endfunction

" Progress -----------------------------------------------------------------

" Neovim: stdpath('data'). Vim has no data directory of its own, so the
" progress lives next to the user's Vim files (~/.vim or ~/vimfiles).
function! germantutor#DataDir() abort
  if exists('g:germantutor_data_dir')
    return g:germantutor_data_dir
  endif
  if $GERMANTUTOR_DATA_DIR !=# ''
    return $GERMANTUTOR_DATA_DIR
  endif
  if has('nvim')
    return stdpath('data') . '/germantutor'
  endif
  if has('win32')
    return expand('~/vimfiles/germantutor')
  endif
  if !isdirectory(expand('~/.vim')) && isdirectory(expand('~/.config/vim'))
    return expand('~/.config/vim/germantutor')
  endif
  return expand('~/.vim/germantutor')
endfunction

function! germantutor#ProgressFile() abort
  return germantutor#DataDir() . '/progress.json'
endfunction

function! germantutor#LoadProgress() abort
  let file = germantutor#ProgressFile()
  if filereadable(file)
    try
      let data = json_decode(join(readfile(file), "\n"))
      if type(data) == type({})
        return data
      endif
    catch
    endtry
  endif
  return {'version': 1, 'lessons': {}}
endfunction

function! s:SaveProgress(data) abort
  try
    let dir = germantutor#DataDir()
    if !isdirectory(dir)
      call mkdir(dir, 'p')
    endif
    call writefile([json_encode(a:data)], germantutor#ProgressFile())
  catch
    call s:Error('Fortschritt nicht gespeichert: ' . v:exception)
  endtry
endfunction

" Adds the solved exercises (block numbers, 1-based) of a lesson to the
" saved progress. The file is re-read first so that two editors running at
" the same time do not overwrite each other.
function! germantutor#RecordSolved(id, solved, total) abort
  let data = germantutor#LoadProgress()
  let lessons = get(data, 'lessons', {})
  let entry = get(lessons, a:id, {})
  let before = get(entry, 'solved', [])
  let merged = uniq(sort(before + a:solved, 'n'))
  if merged ==# before && get(entry, 'total', -1) == a:total
    return 0
  endif
  let lessons[a:id] = {'solved': merged, 'total': a:total}
  let data.lessons = lessons
  call s:SaveProgress(data)
  return 1
endfunction

function! s:RememberPosition() abort
  if !exists('b:germantutor')
    return
  endif
  let data = germantutor#LoadProgress()
  let data.last = {'lesson': b:germantutor.id, 'line': line('.')}
  call s:SaveProgress(data)
endfunction

function! germantutor#ShowProgress() abort
  let data = germantutor#LoadProgress()
  let saved = get(data, 'lessons', {})
  let lines = ['VimGermanTutor: dein Fortschritt', '']
  for lesson in germantutor#Lessons()
    let total = len(germantutor#check#Parse(readfile(lesson.file)))
    let solved = len(get(get(saved, lesson.id, {}), 'solved', []))
    let mark = total > 0 && solved >= total ? '  fertig' : ''
    let done = solved > 0 ? solved . '/' . total : '-'
    call add(lines, printf('  %-5s %-44s %5s%s', lesson.id,
          \ strcharpart(lesson.title, 0, 44), done, mark))
  endfor
  let last = get(data, 'last', {})
  call add(lines, '')
  if !empty(last)
    call add(lines, printf('Zuletzt: Lektion %s, Zeile %d. :GermanTutor macht dort weiter.',
          \ last.lesson, last.line))
  endif
  call add(lines, 'Datei: ' . germantutor#ProgressFile())
  echo join(lines, "\n")
endfunction

" Timer for the writing practice ---------------------------------------------

let s:timer = -1
let s:timer_end = 0
let s:timer_warned = 0

function! germantutor#Timer(arg) abort
  if !has('timers')
    call s:Error('Dein Vim hat keine +timers. (No timer support.)')
    return
  endif
  let arg = substitute(a:arg, '\s', '', 'g')
  if arg ==? 'stop'
    call s:StopTimer()
    echo 'Timer gestoppt.'
  elseif arg ==# ''
    if s:timer < 0
      echo 'Kein Timer läuft. Start: :GermanTutorTimer 50  (Minuten)'
    else
      echo 'Noch ' . germantutor#StatusTimer()
    endif
  elseif arg =~# '^\d\+$' && str2nr(arg) > 0
    call s:StopTimer()
    let s:timer_end = localtime() + 60 * str2nr(arg)
    let s:timer_warned = 0
    let s:timer = timer_start(1000, function('s:TimerTick'), {'repeat': -1})
    echo 'Timer: ' . arg . ' Minuten. Viel Erfolg!'
  else
    call s:Error('Benutzung: :GermanTutorTimer 50  oder  :GermanTutorTimer stop')
  endif
endfunction

function! s:StopTimer() abort
  if s:timer >= 0
    call timer_stop(s:timer)
  endif
  let s:timer = -1
  redrawstatus!
endfunction

function! s:TimerTick(timer) abort
  let left = s:timer_end - localtime()
  if left <= 0
    call s:StopTimer()
    echohl WarningMsg
    echomsg 'Die Zeit ist um! Stift weg, Hände hoch. Zähle jetzt die Wörter: g Strg-g'
    echohl None
    return
  endif
  if left <= 300 && !s:timer_warned
    let s:timer_warned = 1
    echohl WarningMsg
    echomsg 'Noch 5 Minuten. Zeit für den Schluss und die Korrektur.'
    echohl None
  endif
  redrawstatus!
endfunction

function! germantutor#StatusTimer() abort
  if s:timer < 0
    return ''
  endif
  let left = max([0, s:timer_end - localtime()])
  return printf('Zeit %d:%02d  ', left / 60, left % 60)
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
