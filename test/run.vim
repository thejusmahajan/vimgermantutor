" test/run.vim - headless tests for VimGermanTutor.
"
"   vim -Nu NONE -i NONE --cmd "set encoding=utf-8" -es -S test/run.vim </dev/null
"   nvim --headless -u NONE -i NONE -S test/run.vim
"
" The results are written to test/results.log (or $GERMANTUTOR_TEST_LOG).
" Vim exits with 0 when every test passed and with 1 otherwise.
set nocompatible
scriptencoding utf-8

let s:root = fnamemodify(expand('<sfile>:p:h'), ':h')
let &runtimepath = escape(s:root, ',') . ',' . &runtimepath
syntax on
runtime plugin/germantutor.vim
execute 'source' fnameescape(s:root . '/test/recipes.vim')

let s:data = fnamemodify(tempname(), ':p') . '-data'
let g:germantutor_data_dir = s:data
let s:log = []
let s:failures = 0
let s:messages = []

function! s:Fail(msg) abort
  let s:failures += 1
  call add(s:messages, a:msg)
endfunction

function! s:Check(cond, msg) abort
  if !a:cond
    call s:Fail(a:msg)
  endif
endfunction

function! s:Equal(got, want, msg) abort
  if type(a:got) != type(a:want) || a:got !=# a:want
    call s:Fail(a:msg . ': got ' . string(a:got) . ', want ' . string(a:want))
  endif
endfunction

function! s:LessonLines(lesson) abort
  return readfile(a:lesson.file)
endfunction

" Lines of a lesson in which exercise block a:i (0-based) is replaced by the
" given answer lines. The range from the first ---> line to the line before
" the fold also covers continuation lines that a J would join.
function! s:WithAnswers(lines, block, answers) abort
  let first = a:block.lnums[0] - 1
  let last = a:block.fold - 2
  let new = map(copy(a:answers), '"---> " . v:val')
  return (first > 0 ? a:lines[: first - 1] : []) + new + a:lines[last + 1 :]
endfunction

function! s:AllFiles() abort
  let files = []
  for pattern in ['lessons/*.txt', 'plugin/*.vim', 'autoload/*.vim',
        \ 'autoload/*/*.vim', 'syntax/*.vim', 'doc/*.txt', 'test/*.vim',
        \ 'bin/*', '*.md', 'LICENSE']
    let files += glob(s:root . '/' . pattern, 1, 1)
  endfor
  return files
endfunction

" ---------------------------------------------------------------- tests --

function! s:Test_LessonsExist() abort
  let lessons = germantutor#Lessons()
  call s:Check(len(lessons) >= 2, 'at least two lessons')
  let ids = map(copy(lessons), 'v:val.id')
  call s:Equal(len(uniq(sort(copy(ids)))), len(ids), 'lesson ids are unique')
  call s:Equal(ids[0], '1.1', 'first lesson')
  let chapter = 0
  let number = 0
  for lesson in lessons
    if lesson.chapter != chapter
      call s:Equal(lesson.chapter, chapter + 1, 'chapters without gaps at ' . lesson.id)
      let chapter = lesson.chapter
      let number = 0
    endif
    call s:Equal(lesson.number, number + 1, 'lessons without gaps at ' . lesson.id)
    let number = lesson.number
    call s:Check(lesson.title !~# '\.txt$', 'lesson ' . lesson.id . ' has a title line')
  endfor
endfunction

function! s:Test_FilesClean() abort
  for file in s:AllFiles()
    let name = fnamemodify(file, ':.')
    let first = get(readfile(file, 'b', 1), 0, '')
    call s:Check(first !~# "^\xef\xbb\xbf", name . ' has no BOM')
  endfor
  let months = 'Januar\|Februar\|März\|April\|Mai\|Juni\|Juli\|August\|'
        \ . 'September\|Oktober\|November\|Dezember'
  let days = 'Montag\|Dienstag\|Mittwoch\|Donnerstag\|Freitag\|Samstag\|Sonntag'
  for lesson in germantutor#Lessons()
    let lnum = 0
    for line in s:LessonLines(lesson)
      let lnum += 1
      let where = lesson.id . ':' . lnum
      call s:Check(line !~# '\t', where . ' has no tab')
      call s:Check(line !~# '\s$', where . ' has no trailing space')
      call s:Check(strdisplaywidth(line) <= 76, where . ' is at most 76 columns wide')
      call s:Check(line !~# '\<\%(19\|20\)\d\d\>', where . ' has no year (timestamp?)')
      call s:Check(line !~# '\d\.\s*\%(' . months . '\)', where . ' has no date')
      call s:Check(line !~# '\%(' . days . '\)\a*,\s*\%(der\|den\)\s\+\d',
            \ where . ' has no dated weekday')
      call s:Check(line !~# '\<lektion-\d', where . ' has no old file pointer')
    endfor
  endfor
endfunction

function! s:Test_LessonStructure() abort
  let lessons = germantutor#Lessons()
  for i in range(len(lessons))
    let lesson = lessons[i]
    let lines = s:LessonLines(lesson)
    let id = lesson.id
    call s:Check(lines[0] =~# '^=\{20,}$', id . ' starts with a rule')
    call s:Equal(matchstr(lines[1], 'Lektion \zs\d\+\.\d\+\ze:'), id, id . ' title number')
    call s:Check(lines[2] =~# '^\s*Vim:', id . ' names its Vim commands on line 3')

    " Folds: balanced, not nested. ---> only outside folds, ===> only inside.
    let depth = 0
    let arrows = 0
    let lnum = 0
    for line in lines
      let lnum += 1
      if line =~# '{{{\d*\s*$'
        call s:Equal(depth, 0, id . ':' . lnum . ' fold is not nested')
        let depth += 1
      elseif line =~# '^\s*}}}'
        call s:Equal(depth, 1, id . ':' . lnum . ' fold end matches a start')
        let depth -= 1
      elseif line =~# '^\s*--->'
        call s:Equal(depth, 0, id . ':' . lnum . ' ---> outside a fold')
        let arrows += 1
      elseif line =~# '^===>\|^oder\%(\s\|$\)'
        call s:Equal(depth, 1, id . ':' . lnum . ' answer inside a fold')
      endif
    endfor
    call s:Equal(depth, 0, id . ' closes every fold')

    " Every ---> line belongs to an exercise with an answer fold right
    " below it (continuation lines for J may come in between).
    let blocks = germantutor#check#Parse(lines)
    let in_blocks = 0
    for block in blocks
      let where = id . ':' . block.fold
      let in_blocks += len(block.lnums)
      call s:Check(len(block.lnums) >= 1, where . ' answer fold follows ---> lines')
      call s:Check(len(block.answers) >= 1, where . ' answer fold has ===> lines')
      if empty(block.lnums)
        continue
      endif
      for k in range(1, len(block.lnums) - 1)
        call s:Equal(block.lnums[k], block.lnums[k - 1] + 1,
              \ where . ' ---> lines of one exercise are adjacent')
      endfor
      for lnum in range(block.lnums[-1] + 1, block.fold - 1)
        call s:Check(lines[lnum - 1] =~# '^\s\+\S', where . ' only indented'
              \ . ' continuation lines between ---> and the fold (line ' . lnum . ')')
      endfor
    endfor
    call s:Equal(in_blocks, arrows, id . ' every ---> line has an answer fold')
    call s:Check(len(blocks) >= 6 && len(blocks) <= 10,
          \ id . ' has 6 to 10 exercises (has ' . len(blocks) . ')')

    " Pointers: every :GermanTutor X.Y exists; the Weiter line names the next
    " lesson, and only the last lesson has none.
    let weiter = ''
    for line in lines
      for ref in s:Matches(line, ':GermanTutor \zs\d\+\.\d\+')
        call s:Check(!empty(germantutor#Lesson(ref)), id . ' points to lesson ' . ref)
      endfor
      if line =~# '^\s*Weiter:'
        let weiter = matchstr(line, '^\s*Weiter:\s*:GermanTutor \zs\d\+\.\d\+\ze\s*$')
        call s:Check(weiter !=# '', id . ' Weiter line has the form'
              \ . ' "Weiter:  :GermanTutor X.Y"')
      endif
    endfor
    if i + 1 < len(lessons)
      call s:Equal(weiter, lessons[i + 1].id, id . ' Weiter points to the next lesson')
    else
      call s:Equal(weiter, '', id . ' is the last lesson and has no Weiter line')
    endif
  endfor
endfunction

function! s:Matches(text, pattern) abort
  let found = []
  let start = 0
  while 1
    let m = matchstrpos(a:text, a:pattern, start)
    if m[1] < 0
      return found
    endif
    call add(found, m[0])
    let start = m[2]
  endwhile
endfunction

function! s:Test_AnswersPass() abort
  for lesson in germantutor#Lessons()
    let lines = s:LessonLines(lesson)
    let blocks = germantutor#check#Parse(lines)
    for i in range(len(blocks))
      let block = blocks[i]
      let where = lesson.id . ':' . block.fold
      " The main answers solve the exercise.
      let main = map(copy(block.answers), 'v:val[0]')
      let result = germantutor#check#Evaluate(blocks, s:WithAnswers(lines, block, main))
      call s:Check(index(result.solved, i + 1) >= 0, where . ' main answers pass')
      " So does every alternative, in its own line.
      for k in range(len(block.answers))
        for alt in block.answers[k][1:]
          let answers = copy(main)
          let answers[k] = alt
          let result = germantutor#check#Evaluate(blocks,
                \ s:WithAnswers(lines, block, answers))
          call s:Check(index(result.solved, i + 1) >= 0,
                \ where . ' alternative passes: ' . alt)
        endfor
      endfor
    endfor
  endfor
endfunction

function! s:Test_OriginalsFail() abort
  for lesson in germantutor#Lessons()
    let lines = s:LessonLines(lesson)
    let blocks = germantutor#check#Parse(lines)
    let result = germantutor#check#Evaluate(blocks, lines)
    call s:Equal(result.marks, {}, lesson.id . ' untouched lesson has no marks')
    call s:Equal(result.solved, [], lesson.id . ' untouched lesson has nothing solved')
    for block in blocks
      let where = lesson.id . ':' . block.fold
      " Edited by one space (normalised away): still untouched.
      let edited = copy(lines)
      let edited[block.lnums[0] - 1] .= ' '
      let result = germantutor#check#Evaluate(blocks, edited)
      call s:Equal(result.marks, {}, where . ' a trailing space is no edit')
      " The original text is not an accepted answer.
      let main = map(copy(block.answers), 'v:val[0]')
      call s:Check(block.lines !=# main, where . ' original block is not the answer')
      if len(block.lines) == len(block.answers)
        for k in range(len(block.lines))
          call s:Check(index(block.answers[k], block.lines[k]) < 0,
                \ where . ' original line ' . (k + 1) . ' fails the checker')
        endfor
      endif
    endfor
  endfor
endfunction

function! s:Test_Normalize() abort
  let N = function('germantutor#check#Normalize')
  call s:Equal(N("--->   Er  kommt\t heute. \r"), 'Er kommt heute.', 'spaces and \r')
  call s:Equal(N('===> Sie sagt: „Ja.“'), 'Sie sagt: "Ja."', 'German quotes')
  call s:Equal(N('oder Geht’s?'), "Geht's?", 'apostrophe')
  call s:Equal(N("---> a b"), 'a b', 'no-break space')
  call s:Equal(N('---> Oder wir bleiben.'), 'Oder wir bleiben.', 'capital Oder stays')
  call s:Equal(N('---> oder wir bleiben.'), 'oder wir bleiben.', 'oder after the arrow stays')
endfunction

function! s:Test_CrlfTolerated() abort
  for lesson in germantutor#Lessons()
    let lines = s:LessonLines(lesson)
    let crlf = map(copy(lines), 'v:val . "\r"')
    let blocks = germantutor#check#Parse(lines)
    call s:Equal(germantutor#check#Parse(crlf), blocks, lesson.id . ' parses with CRLF')
    let block = blocks[0]
    let main = map(copy(block.answers), 'v:val[0]')
    let solved = map(s:WithAnswers(lines, block, main), 'v:val . "\r"')
    call s:Check(index(germantutor#check#Evaluate(blocks, solved).solved, 1) >= 0,
          \ lesson.id . ' answers with CRLF pass')
  endfor
endfunction

function! s:Test_LauncherCopy() abort
  let lesson = germantutor#Lesson('1.1')
  let original = readfile(lesson.file)
  GermanTutor 1.1
  call s:Check(exists('b:germantutor'), 'tutor buffer is marked')
  let copy = expand('%:p')
  call s:Check(fnamemodify(copy, ':p') !=# fnamemodify(lesson.file, ':p'),
        \ 'buffer is a copy, not the lesson')
  call s:Check(stridx(copy, fnamemodify(tempname(), ':p:h')) == 0,
        \ 'copy lives in the temp directory: ' . copy)
  call s:Equal(getline(1, '$'), original, 'copy has the lesson text')
  call s:Equal(&l:fileencoding, 'utf-8', 'fileencoding')
  call s:Equal(&l:foldmethod, 'marker', 'foldmethod')
  call s:Equal(&l:filetype, 'germantutor', 'filetype')
  call s:Equal(&l:modeline, 0, 'no modelines')
  call s:Equal(&l:modified, 0, 'fresh copy is not modified')
  let fold = germantutor#check#Parse(original)[0].fold
  call s:Check(foldclosed(fold) > 0, 'answer folds start closed')
  call s:Equal(foldtextresult(fold), '     Lösung  (zo)', 'closed fold text')
  call setline(1, 'kaputt')
  silent write
  call s:Equal(readfile(lesson.file), original, 'original untouched after :w')
  call s:Equal(readfile(copy)[0], 'kaputt', 'the copy was written')
  " Starting another lesson from a changed tutor buffer replaces it.
  call setline(2, 'noch mehr kaputt')
  GermanTutor 1.2
  call s:Equal(b:germantutor.id, '1.2', 'second lesson opened')
  call s:Check(!bufexists(copy), 'old copy was wiped')
  call s:Equal(readfile(lesson.file), original, 'original still untouched')
endfunction

function! s:Test_Syntax() abort
  GermanTutor 1.1
  call s:Equal(&syntax, 'germantutor', 'syntax is set')
  let lnum = search('^--->', 'w')
  call s:Check(lnum > 0, 'found an arrow')
  call s:Equal(synIDattr(synID(lnum, 1, 1), 'name'), 'germantutorArrow', 'arrow highlight')
endfunction

function! s:Signs() abort
  let placed = sign_getplaced(bufnr('%'), {'group': 'germantutor'})[0].signs
  let signs = {}
  for sign in placed
    let signs[sign.lnum] = sign.name
  endfor
  return signs
endfunction

function! s:Test_SignsAndTally() abort
  unlet! g:germantutor_ascii
  GermanTutor 1.1
  let blocks = b:germantutor.blocks
  let lnum = blocks[0].lnums[0]
  let original = getline(lnum)
  call s:Equal(s:Signs(), {}, 'no signs on a fresh copy')
  call s:Equal(germantutor#StatusTally(), '0/' . len(blocks) . ' ✓', 'tally at start')
  call setline(lnum, '---> ' . blocks[0].answers[0][0])
  call germantutor#check#Update(1)
  call s:Equal(s:Signs(), {lnum: 'GermanTutorOk'}, 'right answer gets ✓')
  call s:Equal(germantutor#StatusTally(), '1/' . len(blocks) . ' ✓', 'tally after one')
  call setline(lnum, '---> Mira fährt mit den Zug nach Leipzig.')
  call germantutor#check#Update(1)
  call s:Equal(s:Signs(), {lnum: 'GermanTutorBad'}, 'wrong answer gets ✗')
  call setline(lnum, original)
  call germantutor#check#Update(1)
  call s:Equal(s:Signs(), {}, 'back to the original: no sign')
  call s:Equal(trim(sign_getdefined('GermanTutorOk')[0].text), '✓', 'glyph sign')

  let g:germantutor_ascii = 1
  GermanTutor 1.1
  call s:Equal(trim(sign_getdefined('GermanTutorOk')[0].text), 'ok', 'ASCII sign')
  call s:Equal(germantutor#StatusTally(), '0/' . len(blocks) . ' ok', 'ASCII tally')
  unlet g:germantutor_ascii
endfunction

function! s:Test_MissingArrow() abort
  GermanTutor 1.1
  let block = b:germantutor.blocks[0]
  call setline(block.lnums[0], 'Mira fährt mit dem Zug nach Leipzig.')
  let result = germantutor#check#Evaluate(b:germantutor.blocks, getline(1, '$'))
  call s:Equal(result.missing, [block.fold], 'a lost ---> line is reported')
endfunction

function! s:Test_ProgressAndResume() abort
  call delete(s:data, 'rf')
  GermanTutor 1.1
  let blocks = b:germantutor.blocks
  call setline(blocks[1].lnums[0], '---> ' . blocks[1].answers[0][0])
  call germantutor#check#Update(1)
  let saved = germantutor#LoadProgress()
  call s:Equal(saved.lessons['1.1'].solved, [2], 'solved exercise is saved')
  call s:Equal(saved.lessons['1.1'].total, len(blocks), 'total is saved')
  call cursor(blocks[3].lnums[0], 1)
  doautocmd BufLeave
  call s:Equal(germantutor#LoadProgress().last,
        \ {'lesson': '1.1', 'line': blocks[3].lnums[0]}, 'position is saved')

  enew!
  GermanTutor
  call s:Equal(b:germantutor.id, '1.1', 'resume opens the last lesson')
  call s:Equal(line('.'), blocks[3].lnums[0], 'resume goes to the last line')

  " Progress only grows: a fresh copy does not forget solved exercises.
  call setline(blocks[0].lnums[0], '---> ' . blocks[0].answers[0][0])
  call germantutor#check#Update(1)
  call s:Equal(germantutor#LoadProgress().lessons['1.1'].solved, [1, 2], 'union')

  " A complete lesson resumes with the next one.
  call germantutor#RecordSolved('1.1', range(1, len(blocks)), len(blocks))
  enew!
  GermanTutor
  call s:Equal(b:germantutor.id, '1.2', 'complete lesson resumes with the next')

  redir => output
  silent GermanTutorProgress
  redir END
  call s:Check(output =~# '1\.1 .*' . len(blocks) . '/' . len(blocks) . '  fertig',
        \ ':GermanTutorProgress lists lesson 1.1 as done')
  call s:Check(output =~# 'progress\.json', ':GermanTutorProgress names the file')
endfunction

function! s:Test_Find() abort
  call s:Equal(germantutor#Find('01-2').lesson.id, '1.2', '01-2')
  call s:Equal(germantutor#Find(' 1-2 ').lesson.id, '1.2', '1-2')
  call s:Equal(germantutor#Find('genitiv').lesson.id, '1.2', 'by name')
  call s:Equal(germantutor#Find('99.9'), {}, 'unknown lesson')
  call s:Check(index(germantutor#Complete('1.', '', 0), '1.1') >= 0, 'completion')
  GermanTutor 1.1
  call s:Equal(germantutor#Find('next').lesson.id, '1.2', 'next')
  GermanTutor 99.9
  call s:Equal(b:germantutor.id, '1.1', 'unknown lesson leaves the buffer alone')
endfunction

function! s:Test_Timer() abort
  if !has('timers')
    return
  endif
  call s:Equal(germantutor#StatusTimer(), '', 'no timer')
  GermanTutorTimer 2
  call s:Check(germantutor#StatusTimer() =~# '^Zeit [12]:\d\d', 'timer runs')
  GermanTutorTimer stop
  call s:Equal(germantutor#StatusTimer(), '', 'timer stopped')
endfunction

" Every recipe in test/recipes.vim types the keys a lesson teaches and must
" end with an accepted answer. This proves that the steps really work.
function! s:Test_Recipes() abort
  let ex_mode = mode(1) ==# 'ce' || mode(1) ==# 'cv'
  for recipe in g:germantutor_recipes
    let where = recipe.lesson . ' exercise ' . recipe.block
    execute 'GermanTutor' recipe.lesson
    normal! zR
    let block = b:germantutor.blocks[recipe.block - 1]
    call cursor(block.lnums[0], 1)
    let keys = recipe.keys
    if has_key(recipe, 'confirm')
      let answers = ex_mode ? join(split(recipe.confirm, '\zs'), "\<CR>") . "\<CR>"
            \ : recipe.confirm
      let keys = substitute(keys, '<confirm>', answers, '')
    endif
    call feedkeys(keys, 'xt')
    call germantutor#check#Update(1)
    if index(b:germantutor.solved, recipe.block) < 0
      call s:Fail(where . ' recipe ' . string(recipe.keys) . ' gave '
            \ . string(getline(block.lnums[0], block.fold - 1)))
    endif
  endfor
endfunction

" ----------------------------------------------------------------- main --

let s:tests = ['LessonsExist', 'FilesClean', 'LessonStructure', 'AnswersPass',
      \ 'OriginalsFail', 'Normalize', 'CrlfTolerated', 'LauncherCopy', 'Syntax',
      \ 'SignsAndTally', 'MissingArrow', 'ProgressAndResume', 'Find', 'Timer',
      \ 'Recipes']

let s:editor = has('nvim') ? 'Neovim ' . matchstr(execute('version'), 'NVIM v\zs[^\n]*')
      \ : 'Vim ' . v:version / 100 . '.' . v:version % 100
      \ . (exists('v:versionlong') ? ' (' . v:versionlong . ')' : '')
call add(s:log, 'VimGermanTutor tests in ' . s:editor . (has('win32') ? ' on Windows' : ''))
for s:name in s:tests
  let s:messages = []
  try
    call call(function('s:Test_' . s:name), [])
  catch
    call s:Fail('exception: ' . v:exception . ' at ' . v:throwpoint)
  endtry
  call add(s:log, (empty(s:messages) ? 'ok     ' : 'not ok ') . s:name)
  " Keep the log readable: at most ten failures per test.
  call extend(s:log, map(s:messages[: 9], '"    FAIL: " . v:val'))
  if len(s:messages) > 10
    call add(s:log, '    ... and ' . (len(s:messages) - 10) . ' more')
  endif
endfor
call add(s:log, '')
call add(s:log, s:failures ? s:failures . ' check(s) failed.' : 'All tests passed.')
let s:logfile = $GERMANTUTOR_TEST_LOG !=# '' ? $GERMANTUTOR_TEST_LOG
      \ : s:root . '/test/results.log'
call writefile(s:log, s:logfile)
call delete(s:data, 'rf')
if s:failures
  cquit!
endif
qall!
