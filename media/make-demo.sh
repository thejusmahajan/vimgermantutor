#!/bin/sh
# media/make-demo.sh - records media/demo.gif: lesson 1.5 in Neovim, driven
# through tmux, rendered with media/render.py (Pillow) and ffmpeg.
# Needs: tmux, nvim, python3 with Pillow, ffmpeg.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
D=$(mktemp -d)
GERMANTUTOR_DATA_DIR=$D/data
export GERMANTUTOR_DATA_DIR
cd "$root"
tmux new-session -d -s gtdemo -x 80 -y 24 \
  "env TERM=xterm-256color COLORTERM=truecolor bin/vimgermantutor --nvim 1.5 -- -c 'set nohlsearch'"
sleep 2
n=0
frames=''
shot() { # shot SECONDS: capture the screen and keep it for SECONDS
  n=$((n+1))
  f=$(printf '%s/f%02d' "$D" $n)
  sleep 0.7
  tmux capture-pane -t gtdemo -e -p > "$f.ans"
  pos=$(tmux display -p -t gtdemo '#{cursor_x},#{cursor_y}')
  frames="$frames{\"file\":\"$f.ans\",\"png\":\"$f.png\",\"cursor\":[$pos],\"secs\":$1},"
}
keys() { tmux send-keys -t gtdemo "$@"; }

shot 3
keys '/^---> Mira bleibt' Enter zt; for i in 1 2 3 4 5 6 7 8; do keys k; done
for i in 1 2 3 4 5 6 7 8; do keys j; done
shot 2.5
keys '/ ist' Enter;              shot 1.6
keys d a;                        shot 0.9
keys w;                          shot 1.6
keys f .;                        shot 1.2
keys P;                          shot 2.6
keys j z o;                      shot 2.8
keys z c '/^---> Sie schreibt' Enter; shot 1.2
keys '/ kann' Enter;             shot 1.4
keys d a w;                      shot 1.8
keys f . P;                      shot 3.5
keys Escape ':q!' Enter
sleep 0.5
tmux kill-session -t gtdemo 2>/dev/null || true

printf '{"cols":80,"rows":24,"frames":[%s]}' "${frames%,}" > "$D/spec.json"
python3 "$root/media/render.py" "$D/spec.json"
python3 - "$D" <<'PY'
import json, sys
d = sys.argv[1]
spec = json.load(open(d + '/spec.json'))
with open(d + '/list.txt', 'w') as f:
    for fr in spec['frames']:
        f.write("file '%s'\nduration %s\n" % (fr['png'], fr['secs']))
    f.write("file '%s'\n" % spec['frames'][-1]['png'])
PY
ffmpeg -loglevel error -y -f concat -safe 0 -i "$D/list.txt" \
  -vf 'palettegen=max_colors=64:stats_mode=full' "$D/palette.png"
ffmpeg -loglevel error -y -f concat -safe 0 -i "$D/list.txt" -i "$D/palette.png" \
  -lavfi 'fps=10[x];[x][1:v]paletteuse=dither=none' -loop 0 "$root/media/demo.gif"
rm -rf "$D"
echo "wrote media/demo.gif"
