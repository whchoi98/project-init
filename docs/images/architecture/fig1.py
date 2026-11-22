"""Figure 1: the critical path (README, Architecture section)."""
from infokit import Doc, footer_note, header, section

from figkit import centered_para, chain, name_block, tier_row, type_tag


def s1(d, x, y, w, h, T):
    cy = section(d, x, y, w, h, 1, *T["s1"])
    top = cy + 8
    chain(d, x + 24, top, w - 48, y + h - 24 - top, T["steps"], dsize=15, dlh=22)


def s2(d, x, y, w, h, T):
    cy = section(d, x, y, w, h, 2, *T["s2"])
    top, gap = cy + 4, 10
    rh = (y + h - 24 - top - gap * 2) / 3
    for i, (name, cond, items, color) in enumerate(T["tiers"]):
        tier_row(d, x + 24, top + i * (rh + gap), w - 48, rh, name, cond, items, color)


def s3(d, x, y, w, h, T):
    cy = section(d, x, y, w, h, 3, *T["s3"])
    top, gap, n = cy + 4, 8, len(T["mechs"])
    rh = (y + h - 24 - top - gap * (n - 1)) / n
    ix, iw = x + 24, w - 48
    for i, (name, where, trigger, typ, color, name_code) in enumerate(T["mechs"]):
        ry = top + i * (rh + gap)
        box, mid = (ix, ry, iw, rh), ry + rh / 2
        d.rect(ix, ry, iw, rh, rx=10, fill="panel", stroke="cardline", sw=1.1)
        name_block(d, ix + 20, mid, name, where, name_code, box)
        centered_para(d, ix + 330, mid, iw - 330 - 130, trigger, 14, 20, "text2", box, maxl=2)
        type_tag(d, ix + iw - 18, mid, typ, color, box)


def build(theme, T):
    d = Doc(1920, 1080, theme)
    d.rect(0, 0, 1920, 1080, fill="bg")
    header(d, 48, 76, T["title"], T["sub_en"], T["sub2"])
    s1(d, 48, 140, 1824, 370, T)
    s2(d, 48, 530, 902, 514, T)
    s3(d, 970, 530, 902, 514, T)
    footer_note(d, 1872, 1064, T["note"])
    return d.svg()
