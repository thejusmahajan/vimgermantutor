" test/recipes.vim - the keys each lesson teaches, typed for real.
"
" Every recipe starts with the cursor at column 1 of the first ---> line of
" exercise 'block' (1-based) in 'lesson', with all folds open. The keys are
" fed as if typed. Afterwards the exercise must be solved. '<confirm>' in
" the keys stands for the answers to a :s///c prompt, given in 'confirm'.
scriptencoding utf-8

let g:germantutor_recipes = [
      \ {'lesson': '1.1', 'block': 1, 'keys': "f/xxxx"},
      \ {'lesson': '1.1', 'block': 2, 'keys': "/einen\\/\<CR>xxxxxx"},
      \ {'lesson': '1.1', 'block': 6, 'keys': "/die\\/\<CR>xxxx"},
      \ {'lesson': '1.1', 'block': 8, 'keys': "f/xxx"},
      \ {'lesson': '1.2', 'block': 1, 'keys': "fWider \<Esc>"},
      \ {'lesson': '1.2', 'block': 4, 'keys': "/Vermieter\\>/e\<CR>as\<Esc>"},
      \ {'lesson': '1.2', 'block': 6, 'keys': "fmxis\<Esc>fnas\<Esc>"},
      \ {'lesson': '1.2', 'block': 7, 'keys': "A des Parks.\<Esc>"},
      \ ]
