" VimGermanTutor - vimtutor for German, from B1 to Goethe-Zertifikat B2.
" Commands:  :GermanTutor [lesson]   :GermanTutorProgress   :GermanTutorTimer
" See :help germantutor.  License: MIT.

if exists('g:loaded_germantutor')
  finish
endif
if has('nvim') ? !has('nvim-0.9') : v:version < 802
  echomsg 'VimGermanTutor braucht Vim 8.2 oder Neovim 0.9 (or newer).'
  finish
endif
let g:loaded_germantutor = 1

let s:cpo_save = &cpo
set cpo&vim

command! -nargs=? -bar -complete=customlist,germantutor#Complete GermanTutor
      \ call germantutor#Start(<q-args>)
command! -nargs=0 -bar GermanTutorProgress call germantutor#ShowProgress()
command! -nargs=? -bar GermanTutorTimer call germantutor#Timer(<q-args>)

let &cpo = s:cpo_save
unlet s:cpo_save
