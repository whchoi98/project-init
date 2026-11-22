"""Figure 3, English version."""
import fig3
from figtext import FIG3

T = FIG3["en"]


def landscape(theme):
    return fig3.build(theme, T)
