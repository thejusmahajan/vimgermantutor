# VimGermanTutor

`vimtutor` for German. You learn German grammar for the Goethe-Zertifikat B2
and the editor Vim at the same time: every Vim command is practised on a German
sentence, and the command often *is* the grammar step (`e` + `r` fixes an
adjective ending, `daw` + `f.` + `P` moves the verb to the end of a
*weil*-clause).

> Work in progress: 23 lessons are done (the 14 original ones, ported, and the
> missing B2 grammar); the exam chapter and the review lessons follow.

## How it works

- One command opens a fresh copy of a lesson. You cannot break the original.
- The file is the playground: you move through it with the keys it has just
  taught you.
- Every exercise line starts with `--->`. Numbered steps above it say what to
  press.
- While you edit, the line gets a ✓ (right) or ✗ (not yet) in the sign column.
  An untouched line gets nothing. The status line shows the tally, e.g. `6/8 ✓`.
- The answer is hidden in a closed fold right below the exercise: try first,
  then open it with `zo`.

## Start

From a shell:

```sh
bin/vimgermantutor          # resume where you stopped
bin/vimgermantutor 1.2      # lesson 1.2
bin/vimgermantutor --vim    # use Vim even if Neovim is installed
```

On Windows: `bin\vimgermantutor.cmd` with the same arguments.

Inside Vim or Neovim (after installing the plugin): `:GermanTutor`,
`:GermanTutor 1.2`, `:GermanTutorProgress`.

## Requirements

Vim 8.2 or newer, or Neovim 0.9 or newer, on Linux, macOS or Windows.

## Licence

MIT, see [LICENSE](LICENSE).
