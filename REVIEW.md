# German points to check

Every exercise was written together with its accepted answers, and then every
German sentence was read again in a separate pass (case, endings, word order,
gender, prepositions, register, spelling). What was wrong was fixed. The points
below are the ones I am **not fully sure about**. Please have a teacher or a
native speaker look at them.

Line numbers refer to the files in `lessons/`.

| # | Lesson, line | Sentence | Doubt |
|---|---|---|---|
| 1 | 01-2, 144 | Herr Becker telefoniert die ganze Zeit während der Besichtigung. | Is this word order natural? More usual would be *Während der Besichtigung telefoniert …*, but the exercise needs the Genitiv group at the end of the line. |
| 2 | 01-3, 32 | Entweder der Artikel oder das Adjektiv zeigt Genus und Kasus. | A teaching simplification. It ignores the strong Genitiv (*wegen starken Regens*). Acceptable for B1 → B2? |
| 3 | 01-4, 114 and 03-1, 30 | `p` setzt sie UNTER der Zeile mit dem Cursor wieder ein. | Dativ after *einsetzen*. Should it be Akkusativ (*unter die Zeile*)? |
| 4 | 02-3, 56–60 | Wenn Mira früher gekommen wäre, wäre sie dran gewesen. | *dran sein* (= an der Reihe sein) is colloquial. Fine in a B2 course? |
| 5 | 02-4, 84 | Früher musste der Hof gekehrt werden und das Licht musste aus sein. | Natural? Comma before *und*? |
| 6 | 03-2, 79 | Mira wartet auf die Antwort. Jana wartet auch darauf. | The checker accepts only *darauf* for a thing, not *auf sie*. Too strict? |
| 7 | 03-5, 82 | Entweder Mira bekommt die Stelle bei Blauwerk oder sie sucht weiter. | Accepted only without a comma. With two main clauses a comma before *oder* may be allowed. Should both versions pass? |
| 8 | 04-2, 116 | Die Zeitung schreibt, die Mieten würden steigen. | *würde* + Infinitiv as the replacement form. Is *die Mieten stiegen* better, or also acceptable? |
| 9 | 04-5, 85 | Mira stellt einen Antrag auf drei Tage Urlaub. | Natural, or rather *einen Urlaubsantrag für drei Tage*? |
| 10 | 05-3, 62 | Ich hätte am Montag gern frei. | Natural as a polite request in an e-mail to the boss? (Original line: *Ich brauche am Montag frei.*) |
| 11 | 01-5, 32 and 128; 04-2, 131, 138, 155 | Ja-Nein-Frage | Spelling: *Ja-Nein-Frage* or *Ja-nein-Frage*? |
| 12 | 01-6, 90 | Die Nachbarin, der Mira beim Einkaufen hilft, ist schon 90. | Age without *Jahre alt*. Fine in everyday German? |

## How to change an answer

If a sentence is wrong, change both the `===>` line and, if needed, the `--->`
line in the lesson file. If another version is also correct, add it as an
`oder` line below the `===>` line. Then run the tests (see the README): they
check that every accepted answer passes and every original line fails.
