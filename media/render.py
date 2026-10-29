"""Render tmux screen captures (capture-pane -e -p) to PNG frames with PIL.

Used by media/make-demo.sh to build media/demo.gif. Needs Pillow and the
DejaVu Sans Mono font."""
import re, sys, json
from PIL import Image, ImageDraw, ImageFont

FONT = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf', 15)
BOLD = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf', 15)
CW, CH = 9, 19
PALETTE = ['#1e1e2e', '#e5534b', '#57ab5a', '#c69026', '#539bf5', '#b083f0', '#39c5cf', '#c9d1d9',
           '#636e7b', '#ff7b72', '#7ee787', '#f2cc60', '#79c0ff', '#d2a8ff', '#56d4dd', '#ffffff']
BG, FG = '#1e1e2e', '#c9d1d9'

def xterm256(n):
    if n < 16: return PALETTE[n]
    if n < 232:
        n -= 16; r, g, b = n // 36, (n // 6) % 6, n % 6
        f = lambda v: 0 if v == 0 else 55 + v * 40
        return '#%02x%02x%02x' % (f(r), f(g), f(b))
    v = 8 + (n - 232) * 10
    return '#%02x%02x%02x' % (v, v, v)

def parse(text, cols, rows):
    grid = [[(' ', FG, BG, False)] * cols for _ in range(rows)]
    for y, line in enumerate(text.split('\n')[:rows]):
        fg, bg, bold, rev = FG, BG, False, False
        x = 0
        for tok in re.split(r'(\x1b\[[0-9;]*m)', line):
            if tok.startswith('\x1b['):
                codes = [int(c) if c else 0 for c in tok[2:-1].split(';')] or [0]
                i = 0
                while i < len(codes):
                    c = codes[i]
                    if c == 0: fg, bg, bold, rev = FG, BG, False, False
                    elif c == 1: bold = True
                    elif c == 7: rev = True
                    elif c == 22: bold = False
                    elif c == 27: rev = False
                    elif 30 <= c <= 37: fg = PALETTE[c - 30]
                    elif 90 <= c <= 97: fg = PALETTE[c - 90 + 8]
                    elif 40 <= c <= 47: bg = PALETTE[c - 40]
                    elif 100 <= c <= 107: bg = PALETTE[c - 100 + 8]
                    elif c == 39: fg = FG
                    elif c == 49: bg = BG
                    elif c in (38, 48) and i + 2 < len(codes) and codes[i + 1] == 5:
                        col = xterm256(codes[i + 2])
                        if c == 38: fg = col
                        else: bg = col
                        i += 2
                    elif c in (38, 48) and i + 4 < len(codes) and codes[i + 1] == 2:
                        col = '#%02x%02x%02x' % tuple(codes[i + 2:i + 5])
                        if c == 38: fg = col
                        else: bg = col
                        i += 4
                    i += 1
                continue
            for ch in tok:
                if x < cols:
                    f, b = (bg, fg) if rev else (fg, bg)
                    grid[y][x] = (ch, f, b, bold)
                x += 1
    return grid

def render(grid, path, cursor=None):
    rows, cols = len(grid), len(grid[0])
    pad = 12
    img = Image.new('RGB', (cols * CW + 2 * pad, rows * CH + 2 * pad), BG)
    d = ImageDraw.Draw(img)
    for y, row in enumerate(grid):
        for x, (ch, f, b, bold) in enumerate(row):
            px, py = pad + x * CW, pad + y * CH
            if cursor == (x, y):
                f, b = BG, '#c9d1d9'
            if b != BG:
                d.rectangle([px, py, px + CW - 1, py + CH - 1], fill=b)
            if ch != ' ':
                d.text((px, py + 1), ch, font=BOLD if bold else FONT, fill=f)
    img.save(path)

if __name__ == '__main__':
    spec = json.load(open(sys.argv[1]))
    for i, frame in enumerate(spec['frames']):
        grid = parse(open(frame['file'], encoding='utf-8').read(), spec['cols'], spec['rows'])
        render(grid, frame['png'], tuple(frame['cursor']) if frame.get('cursor') else None)
