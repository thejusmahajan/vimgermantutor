" Syntax for VimGermanTutor lessons.
scriptencoding utf-8

if exists('b:current_syntax')
  finish
endif

syntax match germantutorRule      /^[=-]\{20,}$/
syntax match germantutorTitle     /^\s*Lektion \d\+\.\d\+:.*$/
syntax match germantutorVimLine   /^\s*Vim:.*$/
syntax match germantutorHeading   /^#\+ .*$/
syntax match germantutorStep      /^\s*\d\+\.\ze\s/
syntax match germantutorArrow     /^\s*--->/
syntax match germantutorAnswer    /^===>.*$/
syntax match germantutorAnswer    /^oder\%(\s.*\)\=$/
syntax match germantutorFold      /^\s*\%(Musterlösung\|Lösung\)\>.*{{{\d*\s*$/
syntax match germantutorFold      /^\s*}}}\d*\s*$/
syntax match germantutorFold      /^.*{{{\d*\s*$/
syntax match germantutorKey       /`[^` ]\%([^`]*[^` ]\)\=`/
syntax match germantutorNote      /^\s*\%(Merke\|Tipp\|Achtung\|Hinweis\):/
syntax match germantutorWeiter    /^\s*Weiter:.*$/

highlight default link germantutorRule    Comment
highlight default link germantutorTitle   Title
highlight default link germantutorVimLine Comment
highlight default link germantutorHeading Statement
highlight default link germantutorStep    Number
highlight default link germantutorArrow   Special
highlight default link germantutorAnswer  String
highlight default link germantutorFold    Comment
highlight default link germantutorKey     Identifier
highlight default link germantutorNote    Todo
highlight default link germantutorWeiter  Title

let b:current_syntax = 'germantutor'
