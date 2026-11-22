"""Figure 2, English version."""
import fig2
from figtext import FIG2

T = FIG2["en"]


def landscape(theme):
    return fig2.build(theme, T)
