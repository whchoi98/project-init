"""Figure 2: the plugin and the project it generates (docs/architecture.md, Full Architecture Diagram)."""
from infokit import Doc, footer_note, header, para, rw, section

from figkit import chip_rows, code, code_chip, label_rows
from figtext import TIER_FILES


def s1(d, x, y, w, h, T):
    cy = section(d, x, y, w, h, 1, *T["s1"])
    box = (x, y, w, h)
    ix, iw = x + 24, w - 48
    a, b = T["root"]
    wa = code_chip(d, ix, cy + 4, a, "orange", 14, 30, 12, box)
    d.arrow([(ix + wa + 8, cy + 19), (ix + wa + 44, cy + 19)], color="arrow", sw=2.0)
    code_chip(d, ix + wa + 52, cy + 4, b, "orange", 14, 30, 12, box)
    top, gap = cy + 50, 10
    total = y + h - 24 - top - gap * (len(T["parts"]) - 1)
    heights = [150] + [(total - 150) / (len(T["parts"]) - 1)] * (len(T["parts"]) - 1)   # commands needs two chip rows
    by = top
    for (name, desc, items, color), bh in zip(T["parts"], heights):
        pbox = (ix, by, iw, bh)
        d.rect(ix, by, iw, bh, rx=10, fill="panel", stroke="cardline", sw=1.1)
        d.rect(ix + 8, by + 12, 4, bh - 24, rx=2, fill=color + "F")
        code(d, ix + 26, by + 31, name, 15, color, bold=True, box=pbox)
        para(d, ix + 26, by + 55, iw - 46, desc, 13.5, 20, 400, "text2", box=pbox, maxl=1)
        rows = 2 if len(items) > 4 else 1
        chip_rows(d, ix + 26, by + bh - 14 - (26 * rows + 8 * (rows - 1)), iw - 46, items, color, box=pbox)
        by += bh + gap


def links(d, x, y, w, h, T):
    """Commands that carry the plugin's work into a project, drawn in the gap between the two cards."""
    box = (x, y, w, h)
    n = len(T["links"])
    for i, (cmd, caption) in enumerate(T["links"]):
        my = y + h * (i + 1) / (n + 1)
        code(d, x + w / 2, my - 14, cmd, 14, "blue", "middle", bold=True, box=box)
        d.arrow([(x + 8, my), (x + w - 8, my)], color="blue", sw=2.2)
        d.text(x + w / 2, my + 24, caption, 12.5, 400, "muted", "middle", box=box)


def s2(d, x, y, w, h, T):
    cy = section(d, x, y, w, h, 2, *T["s2"])
    top, gap = cy + 4, 10
    ix, iw = x + 24, w - 48
    weights = [4, 2, 3]   # chip rows per tier: Core has the most files
    unit = (y + h - 24 - top - gap * 2) / sum(weights)
    ry = top
    for (name, cond, color), files, wt in zip(T["tiers"], TIER_FILES, weights):
        rh = unit * wt
        box, left = (ix, ry, iw, rh), 190
        d.rect(ix, ry, iw, rh, rx=10, fill="panel", stroke="cardline", sw=1.1)
        d.rect(ix + 8, ry + 12, 4, rh - 24, rx=2, fill=(color + "F") if color else "line2")
        d.text(ix + 26, ry + rh / 2 - 3, name, 19, 700, color or "text", box=box)
        d.text(ix + 26, ry + rh / 2 + 19, cond, 12.5, 400, "muted", box=box)
        rows = _rows(files, iw - left - 20)
        chip_rows(d, ix + left, ry + rh / 2 - (26 * rows + 8 * (rows - 1)) / 2, iw - left - 20, files, color, box=box)
        ry += rh + gap


def _rows(names, w, size=13, gap=8):
    """Number of rows chip_rows needs for these names in width w."""
    from infokit import cw
    rows, cx = 1, 0.0
    for s in names:
        width = cw(s, size) + 20
        if cx + width > w and cx > 0:
            rows, cx = rows + 1, 0.0
        cx += width + gap
    return rows


def s3(d, x, y, w, h, T):
    cy = section(d, x, y, w, h, 3, *T["s3"])
    top, gap = cy + 2, 20
    ix, iw = x + 24, w - 48
    cw_, ch = (iw - gap) / 2, y + h - 22 - top
    for i, (title, sub, items, color) in enumerate(T["roles"]):
        cx = ix + i * (cw_ + gap)
        box = (cx, top, cw_, ch)
        d.rect(cx, top, cw_, ch, rx=10, fill="panel", stroke=color, sw=1.3)
        d.text(cx + 22, top + 31, title, 17, 700, color, box=box)
        d.text(cx + 22 + rw(title, 17, 700) + 14, top + 31, sub, 13, 400, "muted", box=box)
        label_rows(d, cx + 22, top + 48, cw_ - 44, items, color, box=box)


def build(theme, T):
    d = Doc(1920, 1080, theme)
    d.rect(0, 0, 1920, 1080, fill="bg")
    header(d, 48, 76, T["title"], T["sub_en"], T["sub2"])
    s1(d, 48, 140, 820, 704, T)
    links(d, 868, 140, 184, 704, T)
    s2(d, 1052, 140, 820, 704, T)
    s3(d, 48, 864, 1824, 180, T)
    footer_note(d, 1872, 1064, T["note"])
    return d.svg()
