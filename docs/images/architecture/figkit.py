"""Shared layout helpers for the project-init architecture figures (used by fig1.py, fig2.py, fig3.py).

Color meaning, fixed across the three pages:
  blue    commands a user or Claude runs
  yellow  generated files and documents
  green   deterministic automation: hooks, scripts, checks
  purple  guidance and judgment by the model
  orange  emphasis: the critical path, the Core tier
  None    neutral (actor, Optional tier)
"""
from infokit import CODE_FAMILY, cw, nlines, para, rw, tag


def code(d, x, y, s, size=14, color="text", anchor="start", bold=False, box=None):
    """One line in D2Coding: file names, commands, paths."""
    d.text(x, y, s, size, 400 if bold else 300, color, anchor, box=box, family=CODE_FAMILY)


def code_chip(d, x, y, s, color=None, size=13, h=26, pad=10, box=None):
    """Chip with a code label. Returns its width."""
    w = cw(s, size) + 2 * pad
    if color:
        d.rect(x, y, w, h, rx=6, fill=color + "F", fo=0.12, stroke=color, sw=1.1)
    else:
        d.rect(x, y, w, h, rx=6, fill="panel", stroke="chipline", sw=1.1)
    code(d, x + w / 2, y + h / 2 + size * 0.34, s, size, "text" if color else "text2", "middle", box=box)
    return w


def chip_rows(d, x, y, w, names, color=None, size=13, h=26, gap=8, row_gap=8, box=None):
    """Code chips wrapped into rows of width w. Returns the y below the last row."""
    cx, cy = x, y
    for s in names:
        width = cw(s, size) + 20
        if cx + width > x + w and cx > x:
            cx, cy = x, cy + h + row_gap
        code_chip(d, cx, cy, s, color, size, h, 10, box)
        cx += width + gap
    return cy + h


def label_chip(d, x, y, text, color=None, size=12, h=24, pad=10, box=None):
    """Rounded label: accent colored, or neutral when color is None. Returns its width."""
    if color:
        return tag(d, x, y, text, color, size, h, pad, box=box)
    w = rw(text, size, 700) + 2 * pad
    d.rect(x, y, w, h, rx=h / 2, fill="panel", stroke="chipline", sw=1.1)
    d.text(x + w / 2, y + h / 2 + size * 0.36, text, size, 700, "muted", "middle", box=box)
    return w


def label_rows(d, x, y, w, labels, color=None, size=13, h=26, gap=8, row_gap=8, box=None):
    """Label chips wrapped into rows of width w. Returns the y below the last row."""
    cx, cy = x, y
    for s in labels:
        width = rw(s, size, 700) + 24
        if cx + width > x + w and cx > x:
            cx, cy = x, cy + h + row_gap
        label_chip(d, cx, cy, s, color, size, h, 12, box)
        cx += width + gap
    return cy + h


def centered_para(d, x, mid, w, text, size=14, lh=21, color="text2", box=None, maxl=5):
    """Paragraph whose block is vertically centered on mid."""
    n = min(maxl, nlines(text, size, w))
    para(d, x, mid + size * 0.36 - (n - 1) * lh / 2, w, text, size, lh, 400, color, box=box, maxl=maxl)


def step_card(d, x, y, w, h, num, name, desc, chip, color, name_code=False, dsize=14, dlh=21):
    """Numbered step: number, name, rule, description, and a chip at the bottom."""
    box = (x, y, w, h)
    d.rect(x, y, w, h, rx=12, fill="panel", stroke=color or "line2", sw=1.4)
    d.text(x + 18, y + 30, "%02d" % num, 13, 700, color or "muted", ls=1.0, box=box)
    if name_code:
        code(d, x + 18, y + 62, name, 18, "text", bold=True, box=box)
    else:
        d.text(x + 18, y + 62, name, 19, 700, "text", box=box)
    d.line(x + 18, y + 78, x + w - 18, y + 78, stroke="cardline", sw=1.2)
    para(d, x + 18, y + 106, w - 36, desc, dsize, dlh, 400, "text2", box=box, maxl=6)
    label_chip(d, x + 18, y + h - 42, chip, color, 12, 24, 10, box=box)


def chain(d, x, y, w, h, steps, gap=40, dsize=14, dlh=21):
    """Step cards left to right with an arrow between neighbors."""
    n = len(steps)
    cw_ = (w - gap * (n - 1)) / n
    for i, (name, desc, chip, color, name_code) in enumerate(steps):
        cx = x + i * (cw_ + gap)
        step_card(d, cx, y, cw_, h, i + 1, name, desc, chip, color, name_code, dsize, dlh)
        if i < n - 1:
            d.arrow([(cx + cw_ + 7, y + h / 2), (cx + cw_ + gap - 7, y + h / 2)], color="arrow", sw=2.0)


def tier_row(d, x, y, w, h, name, cond, items, color, left=190):
    """Tier name and condition on the left, contents on the right."""
    box = (x, y, w, h)
    d.rect(x, y, w, h, rx=10, fill="panel", stroke="cardline", sw=1.1)
    d.rect(x + 8, y + 12, 4, h - 24, rx=2, fill=(color + "F") if color else "line2")
    d.text(x + 26, y + h / 2 - 3, name, 19, 700, color or "text", box=box)
    d.text(x + 26, y + h / 2 + 19, cond, 12.5, 400, "muted", box=box)
    centered_para(d, x + left, y + h / 2, w - left - 20, items, 14, 21, "text2", box)


def name_block(d, x, mid, name, where, name_code, box):
    """Mechanism name with its location underneath, centered on mid."""
    if name_code:
        code(d, x, mid - 3, name, 16, "text", bold=True, box=box)
    else:
        d.text(x, mid - 3, name, 16, 700, "text", box=box)
    if "/" in where or "." in where:   # a path or file name
        code(d, x, mid + 17, where, 12, "muted", box=box)
    else:
        d.text(x, mid + 17, where, 12, 400, "muted", box=box)


def type_tag(d, right, mid, text, color, box):
    """Type label whose right edge sits at `right`."""
    w = rw(text, 12.5, 700) + 24
    tag(d, right - w, mid - 12, text, color, 12.5, 24, 12, box=box)
