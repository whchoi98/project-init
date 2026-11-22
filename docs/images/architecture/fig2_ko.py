"""Figure 2, Korean version."""
import fig2
from figtext import FIG2

T = FIG2["ko"]


def landscape(theme):
    return fig2.build(theme, T)
