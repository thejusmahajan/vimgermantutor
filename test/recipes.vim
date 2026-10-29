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
      \ {'lesson': '1.3', 'block': 1, 'keys': "/großen/e\<CR>rm"},
      \ {'lesson': '1.3', 'block': 8, 'keys': "/hohe\\>/e\<CR>an\<Esc>"},
      \ {'lesson': '1.4', 'block': 1, 'keys': "/die H\<CR>dw"},
      \ {'lesson': '1.4', 'block': 5, 'keys': "/mit dem Fuß\<CR>d3w"},
      \ {'lesson': '1.4', 'block': 6, 'keys': "/Der Zug abf\<CR>d$"},
      \ {'lesson': '1.4', 'block': 7, 'keys': "ddpjjddkkkp"},
      \ {'lesson': '1.6', 'block': 1, 'keys': "Jbr,wrdwdwhdawf.P"},
      \ {'lesson': '1.6', 'block': 2, 'keys': "Jbr,wdwider \<Esc>dawf.P"},
      \ {'lesson': '1.6', 'block': 3, 'keys': "/ heißt\<CR>dawf.P"},
      \ {'lesson': '2.1', 'block': 4, 'keys': "wcwWürden\<Esc>f.C geben?\<Esc>"},
      \ {'lesson': '2.1', 'block': 5, 'keys': "/habe\<CR>cwhätte\<Esc>/lerne\<CR>Cwürde ich jeden Tag Deutsch lernen.\<Esc>"},
      \ {'lesson': '2.2', 'block': 1, 'keys': "/füllt\<CR>cwwird\<Esc>wdw/\\<aus\\>\<CR>eagefüllt\<Esc>"},
      \ {'lesson': '2.2', 'block': 2, 'keys': "/prüft\<CR>cwwird\<Esc>wdwerr/\\.\<CR>i geprüft\<Esc>"},
      \ {'lesson': '3.1', 'block': 1, 'keys': "yypwcwdie\<Esc>Ain\<Esc>"},
      \ {'lesson': '3.1', 'block': 2, 'keys': "yypwcwdie\<Esc>wrÄAin\<Esc>"},
      \ {'lesson': '3.1', 'block': 9, 'keys': "/(Vorst\<CR>lyw0/Gespr\<CR>Pas\<Esc>lrgf(d$"},
      \ {'lesson': '3.5', 'block': 1, 'keys': "J0/ein\<CR>isowohl \<Esc>f.c3w als auch\<Esc>"},
      \ {'lesson': '3.5', 'block': 2, 'keys': "J0/Slow\<CR>inicht nur \<Esc>f.c3w, sondern\<Esc>"},
      \ {'lesson': '3.5', 'block': 3, 'keys': "w\<C-v>jIEntweder \<Esc>"},
      \ {'lesson': '3.5', 'block': 8, 'keys': "/ wird\<CR>dawbhhp"},
      \ {'lesson': '4.1', 'block': 1, 'keys': "/auf dem\<CR>veecim\<Esc>"},
      \ {'lesson': '4.1', 'block': 8, 'keys': "jjjVjdkkkP"},
      \ {'lesson': '4.2', 'block': 1, 'keys': "qa0wier \<Esc>$xjq5@a/er tu$\<CR>Ae\<Esc>"},
      \ {'lesson': '4.2', 'block': 2, 'keys': "f:r,llxcwsie\<Esc>wcwsei\<Esc>$x"},
      \ {'lesson': '4.2', 'block': 7, 'keys': "/bekommt/e\<CR>re"},
      \ {'lesson': '4.3', 'block': 1, 'keys': "/gestern\<CR>\"adw\"bdwbbdf,b\"aP\"bpbeae\<Esc>"},
      \ {'lesson': '4.4', 'block': 1, 'keys': "/lernen\<CR>~"},
      \ {'lesson': '4.4', 'block': 4, 'keys': "wdf,iWegen des Regens\<Esc>"},
      \ {'lesson': '4.4', 'block': 8, 'keys': "/Man darf\<CR>cisDas Rauchen im Büro ist verboten.\<Esc>"},
      \ {'lesson': '4.6', 'block': 1, 'keys': "/ ist\<CR>dawbhhp"},
      \ {'lesson': '4.6', 'block': 2, 'keys': "/ ist\<CR>dawf.P"},
      \ ]
