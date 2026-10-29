#!/bin/sh
# test/launcher.sh vim|nvim - starts bin/vimgermantutor and checks that it
# opened a copy of lesson 1.2 and left the original untouched.
root=$(cd "$(dirname "$0")/.." && pwd)
GERMANTUTOR_TEST_OUT=$root/test/launcher.out
GERMANTUTOR_DATA_DIR=${TMPDIR:-/tmp}/germantutor-launcher-test
export GERMANTUTOR_TEST_OUT GERMANTUTOR_DATA_DIR
rm -f "$GERMANTUTOR_TEST_OUT"
case $1 in
  nvim) "$root/bin/vimgermantutor" --nvim 1.2 -- --headless -S "$root/test/launcher_check.vim" ;;
  *) "$root/bin/vimgermantutor" --vim 1.2 -- -es -S "$root/test/launcher_check.vim" </dev/null ;;
esac
cat "$GERMANTUTOR_TEST_OUT" 2>/dev/null || echo "launcher wrote no result"
grep -qx 'result=ok' "$GERMANTUTOR_TEST_OUT" 2>/dev/null
