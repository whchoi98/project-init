"""Figure 1, English version."""
import fig1
from figtext import FIG1

T = FIG1["en"]


def landscape(theme):
    return fig1.build(theme, T)
