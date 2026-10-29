#!/bin/sh
# test/run.sh [vim|nvim] [executable] - runs all tests for one editor.
root=$(cd "$(dirname "$0")/.." && pwd)
editor=${1:-vim}
exe=${2:-$editor}
log=$root/test/results.log
rm -f "$log"
GERMANTUTOR_TEST_LOG=$log
export GERMANTUTOR_TEST_LOG
if [ "$editor" = nvim ]; then
  "$exe" --headless -u NONE -i NONE -S "$root/test/run.vim"
else
  "$exe" -Nu NONE -i NONE --cmd 'set encoding=utf-8' -es -S "$root/test/run.vim" </dev/null
fi
status=$?
cat "$log" 2>/dev/null || echo "no test log written"
echo "--- launcher"
sh "$root/test/launcher.sh" "$editor" || status=1
exit $status
