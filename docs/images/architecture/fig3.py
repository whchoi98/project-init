"""Figure 3: one /init-project run and the four auto-sync layers (docs/architecture.md, Data Flow Summary)."""
from infokit import Doc, callout, dot_list, footer_note, header, section

from figkit import centered_para, chain, name_block, type_tag


def s1(d, x, y, w, h, T):
    cy = section(d, x, y, w, h, 1, *T["s1"])
    top = cy + 8
    chain(d, x + 24, top, w - 48, y + h - 24 - top, T["steps"])


def s2(d, x, y, w, h, T):
    cy = section(d, x, y, w, h, 2, *T["s2"])
    box = (x, y, w, h)
    ix, iw = x + 24, w - 48
    c_name, c_trig, c_what = ix + 20, ix + 330, ix + 570
    for cx, label in zip((c_name, c_trig, c_what), T["cols"]):
        d.text(cx, cy + 14, label, 12, 700, "faint", ls=0.6, box=box)
    d.text(ix + iw - 18, cy + 14, T["cols"][3], 12, 700, "faint", "end", ls=0.6, box=box)
    top, gap, n = cy + 26, 8, len(T["rows"])
    rh = (y + h - 24 - top - gap * (n - 1)) / n
    for i, (name, where, trigger, what, typ, color, name_code) in enumerate(T["rows"]):
        ry = top + i * (rh + gap)
        rbox, mid = (ix, ry, iw, rh), ry + rh / 2
        d.rect(ix, ry, iw, rh, rx=10, fill="panel", stroke="cardline", sw=1.1)
        d.rect(ix + 8, ry + 12, 4, rh - 24, rx=2, fill=color + "F")
        name_block(d, c_name, mid, name, where, name_code, rbox)
        centered_para(d, c_trig, mid, c_what - c_trig - 20, trigger, 14, 20, "text2", rbox, maxl=2)
        centered_para(d, c_what, mid, ix + iw - 130 - c_what, what, 14, 20, "text2", rbox, maxl=3)
        type_tag(d, ix + iw - 18, mid, typ, color, rbox)


def s3(d, x, y, w, h, T):
    cy = section(d, x, y, w, h, 3, *T["s3"])
    box = (x, y, w, h)
    ix, iw = x + 24, w - 48
    yy = cy + 22
    for (title, items), color in ((T["updated"], "green"), (T["suggested"], "purple")):
        d.text(ix, yy, title, 14, 700, color, box=box)
        last = dot_list(d, ix, yy + 32, iw, items, 15, 22, 15, dot=color, box=box)
        yy = last + 56
    callout(d, ix, y + h - 22 - 58, iw, *T["insight"], box=box)


def build(theme, T):
    d = Doc(1920, 1080, theme)
    d.rect(0, 0, 1920, 1080, fill="bg")
    header(d, 48, 76, T["title"], T["sub_en"], T["sub2"])
    s1(d, 48, 140, 1824, 350, T)
    s2(d, 48, 510, 1180, 534, T)
    s3(d, 1248, 510, 624, 534, T)
    footer_note(d, 1872, 1064, T["note"])
    return d.svg()
