" autoload/germantutor/check.vim - marks every ---> line with ✓ or ✗.
"
" A lesson is a list of exercise blocks. A block is the run of lines that
" start with ---> followed by a closed fold whose first line is "Lösung {{{".
" Inside that fold, each line starting with ===> is the expected text of one
" ---> line (in order), and each following line starting with "oder" is
" another accepted answer for the same line. All other fold lines are
" explanations. The answers are always read from the original lesson file,
" so editing the copy (or the opened fold) cannot change them.
scriptencoding utf-8

let s:cpo_save = &cpo
set cpo&vim

let s:arrow = '\C^\s*--->'
let s:answer_fold = '\C^\s*Lösung\>[^{]*{{{\d*\s*$'
let s:any_fold = '{{{\d*\s*$'
let s:fold_end = '^\s*}}}\d*\s*$'

" Normalised text of an exercise or answer line: no marker, one space
" between words, no trailing \r, and one kind of quote and apostrophe.
function! germantutor#check#Normalize(line) abort
  let s = substitute(a:line, '\r$', '', '')
  let s = substitute(s, '\C^\s*\%(--->\|===>\|oder\%(\s\|$\)\)', '', '')
  let s = substitute(s, '[„“”‟«»]', '"', 'g')
  let s = substitute(s, '[‚‘’‛´`]', "'", 'g')
  let s = substitute(s, '[–—]', '-', 'g')
  let s = substitute(s, '…', '...', 'g')
  let s = substitute(s, '\%(\s\|\%u00a0\|\%u202f\)\+', ' ', 'g')
  return substitute(s, '^ \| $', '', 'g')
endfunction

" Parses the lines of an original lesson.
" Returns a list of blocks: {'fold': lnum, 'lnums': [...], 'lines': [...],
" 'answers': [[accepted, ...], ...]} where 'lines' and 'answers' hold
" normalised text.
function! germantutor#check#Parse(lines) abort
  let blocks = []
  let pending = []
  let block = {}
  let in_fold = 0
  let lnum = 0
  for raw in a:lines
    let lnum += 1
    let line = substitute(raw, '\r$', '', '')
    if in_fold
      if line =~# s:fold_end
        let in_fold = 0
        if !empty(block)
          call add(blocks, block)
          let block = {}
        endif
      elseif !empty(block) && line =~# '^===>'
        call add(block.answers, [germantutor#check#Normalize(line)])
      elseif !empty(block) && line =~# '^oder\%(\s\|$\)' && !empty(block.answers)
        call add(block.answers[-1], germantutor#check#Normalize(line))
      endif
    elseif line =~# s:answer_fold
      let in_fold = 1
      let block = {'fold': lnum, 'answers': [],
            \ 'lnums': map(copy(pending), 'v:val[0]'),
            \ 'lines': map(copy(pending), 'v:val[1]')}
      let pending = []
    elseif line =~# s:any_fold
      let in_fold = 1
    elseif line =~# s:arrow
      call add(pending, [lnum, germantutor#check#Normalize(line)])
    endif
  endfor
  return blocks
endfunction

" Finds the exercise lines of the edited copy: for every answer fold, the
" ---> lines between the previous answer fold and this one.
function! s:Scan(lines) abort
  let groups = []
  let pending = []
  let lnum = 0
  for raw in a:lines
    let lnum += 1
    let line = substitute(raw, '\r$', '', '')
    if line =~# s:answer_fold
      call add(groups, {'fold': lnum, 'items': pending})
      let pending = []
    elseif line =~# s:arrow
      call add(pending, [lnum, germantutor#check#Normalize(line)])
    endif
  endfor
  return groups
endfunction

" Compares the lines of the copy with the parsed lesson.
" Returns {'marks': {lnum: 'ok'|'bad'}, 'solved': [block numbers, 1-based],
" 'missing': [fold lnums of blocks that lost a ---> line]}.
" A block that still matches the original exactly is untouched: no marks.
function! germantutor#check#Evaluate(blocks, lines) abort
  let result = {'marks': {}, 'solved': [], 'missing': []}
  let groups = s:Scan(a:lines)
  for i in range(min([len(groups), len(a:blocks)]))
    let block = a:blocks[i]
    let items = groups[i].items
    let texts = map(copy(items), 'v:val[1]')
    if texts ==# block.lines
      continue
    endif
    let all_ok = len(items) == len(block.answers)
    for k in range(len(items))
      let ok = k < len(block.answers) && index(block.answers[k], texts[k]) >= 0
      let result.marks[items[k][0]] = ok ? 'ok' : 'bad'
      let all_ok = all_ok && ok
    endfor
    if all_ok
      call add(result.solved, i + 1)
    elseif len(items) < len(block.lines)
      call add(result.missing, groups[i].fold)
    endif
  endfor
  return result
endfunction

" Live checking -------------------------------------------------------------

function! s:DefineSigns() abort
  let ascii = germantutor#Ascii()
  call sign_define('GermanTutorOk', {'text': ascii ? 'ok' : '✓',
        \ 'texthl': 'GermanTutorOk'})
  call sign_define('GermanTutorBad', {'text': ascii ? 'x' : '✗',
        \ 'texthl': 'GermanTutorBad'})
endfunction

function! germantutor#check#Highlights() abort
  highlight default GermanTutorOk term=bold cterm=bold ctermfg=Green gui=bold guifg=#1a7f37
  highlight default GermanTutorBad term=bold cterm=bold ctermfg=Red gui=bold guifg=#cf222e
endfunction

" Called by :GermanTutor right after the copy is opened.
function! germantutor#check#Attach(state) abort
  let a:state.blocks = germantutor#check#Parse(readfile(a:state.file))
  let a:state.solved = []
  let a:state.marks = {}
  let a:state.announced = []
  let a:state.warned = []
  let a:state.recorded = []
  call germantutor#check#Highlights()
  call s:DefineSigns()
  augroup germantutor_check
    autocmd! * <buffer>
    autocmd TextChanged,InsertLeave <buffer> call germantutor#check#Update(1)
    autocmd TextChangedI <buffer> call germantutor#check#Update(0)
  augroup END
  augroup germantutor_colors
    autocmd!
    autocmd ColorScheme * call germantutor#check#Highlights()
  augroup END
  call germantutor#check#Update(0)
endfunction

" Re-checks the copy. With a:announce, also prints praise or hints.
function! germantutor#check#Update(announce) abort
  if !exists('b:germantutor') || !has_key(b:germantutor, 'blocks')
    return
  endif
  let state = b:germantutor
  let result = germantutor#check#Evaluate(state.blocks, getline(1, '$'))
  call s:PlaceSigns(state, result.marks)
  let state.solved = result.solved
  if !empty(filter(copy(result.solved), 'index(state.recorded, v:val) < 0'))
    call germantutor#RecordSolved(state.id, result.solved, len(state.blocks))
    let state.recorded = uniq(sort(state.recorded + result.solved, 'n'))
  endif
  if a:announce
    call s:Announce(state, result)
  endif
endfunction

function! s:PlaceSigns(state, marks) abort
  if a:marks ==# a:state.marks
    return
  endif
  let buf = bufnr('%')
  call sign_unplace('germantutor', {'buffer': buf})
  let id = 0
  for lnum in sort(map(keys(a:marks), 'str2nr(v:val)'), 'n')
    let id += 1
    let name = a:marks[lnum] ==# 'ok' ? 'GermanTutorOk' : 'GermanTutorBad'
    call sign_place(id, 'germantutor', name, buf, {'lnum': lnum})
  endfor
  let a:state.marks = a:marks
endfunction

" Short messages after the learner leaves Insert mode: praise for a newly
" solved exercise, a hint when a ---> line went missing.
function! s:Announce(state, result) abort
  let total = len(a:state.blocks)
  let new = filter(copy(a:result.solved), 'index(a:state.announced, v:val) < 0')
  let a:state.announced = copy(a:result.solved)
  let missing = filter(copy(a:result.missing), 'index(a:state.warned, v:val) < 0')
  let a:state.warned = copy(a:result.missing)
  if !empty(missing)
    echohl WarningMsg
    echo 'Über der Lösung in Zeile ' . missing[0] . ' fehlt eine Zeile mit --->.'
          \ . ' Mit u machst du die Änderung rückgängig.'
    echohl None
  elseif !empty(new)
    let done = len(a:result.solved)
    if done == total
      let next = germantutor#Next(a:state.id)
      echohl MoreMsg
      echo 'Super! Alle ' . total . ' Übungen richtig.'
            \ . (empty(next) ? ' Du hast den ganzen Kurs geschafft!'
            \ : ' Weiter: :GermanTutor ' . next.id)
      echohl None
    else
      echohl MoreMsg
      echo 'Richtig! ' . done . ' von ' . total . ' Übungen geschafft.'
      echohl None
    endif
  endif
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
