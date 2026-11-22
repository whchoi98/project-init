"""Figure 3, Korean version."""
import fig3
from figtext import FIG3

T = FIG3["ko"]


def landscape(theme):
    return fig3.build(theme, T)
