"""Recogibles, contenedores e iconografía."""

import math

from . import palette as P
from .svg import circle, coil, ellipse, g, path, polyline, radial, rect, text, wave, without_glow

# --- Recogibles -------------------------------------------------------------


def photon(value: int = 1, phase: float = 0) -> str:
    """Fotón (moneda): paquete de ondas. Más valor = más periodos y más brillo."""
    size = {1: 10, 5: 13, 10: 16}[value]
    periods = {1: 1.5, 5: 2.5, 10: 3.5}[value]
    pts = [(x - size, y) for x, y in wave(0, 0, size * 2, size * 0.45, periods, phase=phase)]
    env = "".join(circle(0, 0, size + 4 + i * 3, stroke=P.PHOTON, sw=0.8, opacity=0.35 - i * 0.12) for i in range(value // 5 + 1))
    return g(env, glow=2) + g(polyline(pts, stroke=P.PHOTON, sw=2.6), glow=3) + circle(0, 0, 2, fill="#FFFFFF")


def positron() -> str:
    """Positrón (llave): antimateria positiva. Hueco con signo +."""
    return circle(0, 0, 11, fill=P.VOID) + g(circle(0, 0, 11, stroke=P.POSITRON, sw=2.5), glow=3) + path("M-5,0 L5,0 M0,-5 L0,5", stroke=P.POSITRON, sw=2.4)


def heal() -> str:
    """Cuanto de energía (curación): rombo menta con ħ."""
    return g(path("M0,-13 L11,0 L0,13 L-11,0 Z", fill=P.PLAYER, opacity=0.9), glow=3) + text(0, 5, "ħ", size=14, fill=P.VOID, anchor="middle", weight="bold")


def quark() -> str:
    """Quark (moneda permanente): tres cargas de color."""
    return "".join(g(circle(math.cos(a) * 5, math.sin(a) * 5, 4.8, fill=c), glow=2) for a, c in zip((-math.pi / 2, math.pi / 6, 5 * math.pi / 6), P.QUARK_COLORS)) + circle(0, 0, 11, stroke=P.INK, sw=1, opacity=0.5)


def higgs() -> str:
    """Bosón de Higgs (moneda rara): esfera dorada con halo discontinuo (el propagador escalar)."""
    grad = radial("higgs_g", [(0, "#FFFFFF", 1), (0.4, P.HIGGS, 1), (1, "#A8741A", 1)])
    return f"<defs>{grad}</defs>" + g(circle(0, 0, 17, stroke=P.HIGGS, sw=1.8, dash="5 4"), glow=2) + circle(0, 0, 11, fill="url(#higgs_g)") + text(0, 4.5, "H", size=12, fill=P.VOID, anchor="middle", weight="bold")


# --- Contenedores -----------------------------------------------------------


def quantum_well(cost: int = 5, lit: float = 0, item_y: float = 8, item_opacity: float = 1, price_opacity: float = 1) -> str:
    """Pozo cuántico (cofre común): el objeto duerme en el fondo del pozo de potencial.

    `lit` (0–3) ilumina los niveles de energía al pagar; `item_y` saca el objeto del pozo.
    """
    well = path("M-34,-26 L-34,-4 Q-34,18 -18,18 L18,18 Q34,18 34,-4 L34,-26", stroke=P.INK, sw=2.4)
    levels = ""
    for i in range(3):
        on = min(1.0, max(0.0, lit - i))
        levels += path(f"M{-26 + i * 4},{12 - i * 9} L{26 - i * 4},{12 - i * 9}", stroke=P.PHOTON, sw=1.2 + 1.2 * on, opacity=0.8 - i * 0.22 + 0.4 * on, dash="4 3" if i and on < 1 else "")
    item = g(circle(0, item_y, 6, fill=P.RARITY["common"]), glow=3, opacity=item_opacity)
    price = text(0, -32, f"{cost} γ", size=11, fill=P.PHOTON, anchor="middle", mono=True, weight="bold", opacity=price_opacity)
    return g(well, glow=1) + g(levels, glow=1) + item + price


def bound_electron() -> str:
    """Electrón ligado (cofre especial): un electrón en órbita cerrada custodia el objeto."""
    item = g(path("M0,-10 L9,0 L0,10 L-9,0 Z", fill=P.RARITY["rare"]), glow=3)
    orbit = ellipse(0, 0, 26, 12, stroke=P.NEGATIVE, sw=1.8, rotate=-20)
    orbit2 = ellipse(0, 0, 26, 12, stroke=P.NEGATIVE, sw=1.8, rotate=40, opacity=0.6)
    e = g(circle(22, -10, 4.5, fill=P.NEGATIVE), glow=3)
    hint = g(circle(0, -34, 7, fill=P.VOID) + circle(0, -34, 7, stroke=P.POSITRON, sw=1.6) + path("M-3,-34 L3,-34 M0,-37 L0,-31", stroke=P.POSITRON, sw=1.5), glow=1)
    return g(orbit + orbit2, glow=2) + item + e + hint


def superposition() -> str:
    """Superposición: dos objetos solapados; al observar uno, el otro colapsa."""
    a = g(circle(-7, 0, 11, fill=P.RARITY["epic"], opacity=0.55), glow=3)
    b = g(path("M7,-11 L18,0 L7,11 L-4,0 Z", fill=P.RARITY["rare"], opacity=0.55), glow=3)
    psi = polyline([(x, 22 + 3 * math.sin(x / 3)) for x in range(-24, 25)], stroke=P.FAMILY["quantum"], sw=1.4)
    return a + b + g(psi, glow=1) + text(0, -20, "|ψ⟩", size=11, fill=P.FAMILY["quantum"], anchor="middle", mono=True)


# --- Iconos -----------------------------------------------------------------
# Marco = familia (forma + color). Joya inferior = rareza. Glifo = diagrama de Feynman o símbolo.

FRAME_SHAPES = {
    "electromagnetic": "circle",
    "strong": "hexagon",
    "weak": "triangle",
    "gravity": "diamond",
    "quantum": "star",
    "item": "square",
}


def _frame(kind: str, color: str, r: float = 28) -> str:
    shape = FRAME_SHAPES[kind]
    if shape == "circle":
        d = f"M{r},0 A{r},{r} 0 1 1 {-r},0 A{r},{r} 0 1 1 {r},0 Z"
    elif shape == "square":
        return rect(-r + 2, -r + 2, 2 * r - 4, 2 * r - 4, rx=10, fill=P.VOID_2, stroke=color, sw=2.4)
    else:
        n, rot, rad = {"hexagon": (6, 0, r), "triangle": (3, -90, r * 1.2), "diamond": (4, -90, r * 1.1), "star": (10, -90, r)}[shape]
        pts = []
        for i in range(n):
            rr = rad if shape != "star" or i % 2 == 0 else rad * 0.72
            a = math.radians(rot + i * 360 / n)
            pts.append((rr * math.cos(a), rr * math.sin(a) + (6 if shape == "triangle" else 0)))
        d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"
    return path(d, fill=P.VOID_2, stroke=color, sw=2.4)


def icon(kind: str, glyph: str, rarity: str = "common") -> str:
    color = P.FAMILY.get(kind, P.INK)
    gem = g(path("M0,-4 L4,0 L0,4 L-4,0 Z", fill=P.RARITY[rarity]), y=31, glow=2)
    return g(_frame(kind, color), glow=1) + GLYPHS[glyph](color) + gem


def _g_chain(c: str) -> str:  # Descarga en cadena
    return g(polyline([(-16, -10), (-6, -2), (-10, 4), (2, 10), (-2, 14)], stroke=c, sw=2.4) + circle(-16, -10, 3, fill=c) + circle(12, -12, 3, fill=c) + polyline([(-6, -2), (12, -12)], stroke=c, sw=1.4, dash="2 3"), glow=2)


def _g_photon_vertex(c: str) -> str:  # Feynman: e⁻ emite un fotón
    return path("M-16,14 L0,0 L-16,-14", stroke=P.INK, sw=2) + g(polyline([(x, 3 * math.sin(x * 0.9)) for x in [i * 0.5 for i in range(0, 37)]], stroke=c, sw=2), glow=2)


def _g_fission(c: str) -> str:
    return g(circle(-8, 0, 7, fill=c) + circle(9, 0, 7, fill=c, opacity=0.8), glow=2) + "".join(path(f"M{math.cos(a) * 12:.1f},{math.sin(a) * 12:.1f} L{math.cos(a) * 18:.1f},{math.sin(a) * 18:.1f}", stroke=c, sw=1.6) for a in [i * math.pi / 4 for i in range(8)])


def _g_gluon(c: str) -> str:  # Feynman: intercambio de gluón
    return path("M-16,-14 L-4,-8 L-16,-2 M16,2 L4,8 L16,14", stroke=P.INK, sw=1.8) + g(polyline(coil(-4, -8, 4, 8, loops=4, r=3), stroke=c, sw=1.8), glow=2)


def _g_beta(c: str) -> str:  # Feynman: desintegración beta (n → p e ν̄)
    return (
        path("M-18,10 L-4,0 L-18,-10", stroke=P.INK, sw=1.8)
        + g(polyline([(-4 + i * 0.5, 2.2 * math.sin(i * 0.5)) for i in range(25)], stroke=c, sw=1.8), glow=2)
        + path("M8,0 L18,-10 M8,0 L18,10", stroke=c, sw=1.8)
        + circle(8, 0, 1.8, fill=c)
    )


def _g_singularity(c: str) -> str:
    pts = []
    for i in range(160):
        t = i / 160 * 3 * 2 * math.pi
        r = 18 * math.exp(-0.12 * t)
        pts.append((r * math.cos(t), r * math.sin(t)))
    return g(polyline(pts, stroke=c, sw=1.8), glow=2) + circle(0, 0, 3.5, fill=P.VOID) + circle(0, 0, 3.5, stroke=c, sw=1.2)


def _g_superposition(c: str) -> str:
    return g(circle(-5, 0, 11, stroke=c, sw=2) + circle(5, 0, 11, stroke=c, sw=2, opacity=0.6), glow=2) + circle(0, 0, 2.5, fill=P.INK)


def _g_spin(c: str) -> str:
    return g(path("M0,-16 L0,16 M-16,0 L16,0 M0,-16 l-4,5 M0,-16 l4,5 M0,16 l-4,-5 M0,16 l4,-5 M-16,0 l5,-4 M-16,0 l5,4 M16,0 l-5,-4 M16,0 l-5,4", stroke=c, sw=2), glow=2)


def _g_mass(c: str) -> str:  # Observable: Masa efectiva
    return g(circle(0, 2, 12, fill=P.PLAYER, opacity=0.85), glow=2) + text(0, 7, "m*", size=12, fill=P.VOID, anchor="middle", weight="bold")


def _g_cat(c: str) -> str:  # Observable: Gato de Schrödinger
    head = path("M-12,-2 L-12,-14 L-5,-7 L5,-7 L12,-14 L12,-2 Q12,12 0,12 Q-12,12 -12,-2 Z", stroke=P.INK, sw=1.8, fill="none", dash="0")
    half = path("M0,-7 L5,-7 L12,-14 L12,-2 Q12,12 0,12 Z", fill=P.INK, opacity=0.35)
    return g(head, glow=1) + half + circle(-5, 0, 1.8, fill=P.INK) + path("M3,-1 l4,2 M7,-1 l-4,2", stroke=P.INK, sw=1.2)


def _g_spin_up(c: str) -> str:  # Observable: Espín alto (+1 salto)
    return g(path("M0,14 L0,-14 M-7,-7 L0,-14 L7,-7", stroke=P.PLAYER, sw=2.6), glow=2) + text(10, 14, "+1", size=9, fill=P.INK, mono=True)


GLYPHS = {
    "chain": _g_chain,
    "photon_vertex": _g_photon_vertex,
    "fission": _g_fission,
    "gluon": _g_gluon,
    "beta": _g_beta,
    "singularity": _g_singularity,
    "superposition": _g_superposition,
    "spin": _g_spin,
    "mass": _g_mass,
    "cat": _g_cat,
    "spin_up": _g_spin_up,
}

ICON_SAMPLES = [
    ("Descarga en cadena", "electromagnetic", "chain", "common"),
    ("Salto iónico", "electromagnetic", "photon_vertex", "rare"),
    ("Fisión", "strong", "fission", "rare"),
    ("Confinamiento", "strong", "gluon", "epic"),
    ("Desintegración beta", "weak", "beta", "common"),
    ("Singularidad", "gravity", "singularity", "epic"),
    ("Superposición", "quantum", "superposition", "legendary"),
    ("Espín", "quantum", "spin", "epic"),
    ("Masa efectiva", "item", "mass", "common"),
    ("Espín alto", "item", "spin_up", "rare"),
    ("Gato de Schrödinger", "item", "cat", "epic"),
]


# --- Iconos de recompensa de bifurcación ------------------------------------

REWARD_GLYPHS = {
    "coins": lambda: photon(5),
    "key": positron,
}


def reward_icon(reward: str) -> str:
    """Icono que flota sobre una salida de bifurcación: marco cuadrado y el recogible de la recompensa."""
    frame = rect(-20, -20, 40, 40, rx=8, fill=P.VOID_2, stroke=P.INK, sw=2)
    return frame + g(without_glow(REWARD_GLYPHS[reward]()), scale=0.9)
