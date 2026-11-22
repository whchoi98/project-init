"""Figure 1, Korean version."""
import fig1
from figtext import FIG1

T = FIG1["ko"]


def landscape(theme):
    return fig1.build(theme, T)
