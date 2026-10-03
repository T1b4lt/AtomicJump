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


# --- Arte del juego (Fase 7) ------------------------------------------------
# Versiones sin filtros ni texto de los recogibles y contenedores, por piezas
# cuando se animan en el motor, y el sistema de iconos del juego: marco + glifo
# (la joya de rareza la dibuja el motor con `icon_gem`, porque la rareza de una
# interacción no es fija).


def _hbar(x: float, y: float, s: float, color: str, sw: float = 2.0) -> str:
    """ħ dibujada con trazos (el SVG del juego no lleva texto). `s` es el alto de la h."""
    h = f"M{x - s * 0.28:.2f},{y - s:.2f} L{x - s * 0.28:.2f},{y:.2f} M{x - s * 0.28:.2f},{y - s * 0.42:.2f} Q{x + s * 0.3:.2f},{y - s * 0.62:.2f} {x + s * 0.3:.2f},{y - s * 0.2:.2f} L{x + s * 0.3:.2f},{y:.2f}"
    bar = f"M{x - s * 0.5:.2f},{y - s * 0.72:.2f} L{x + s * 0.06:.2f},{y - s * 0.86:.2f}"
    return path(h + " " + bar, stroke=color, sw=sw)


def photon_sprite(value: int = 1) -> str:
    """Fotón del juego (×1, ×5, ×10): paquete de ondas con sus halos."""
    return without_glow(photon(value))


def positron_sprite() -> str:
    """Positrón del juego: hueco con contorno magenta y signo +."""
    return without_glow(positron())


def heal_sprite(big: bool = False) -> str:
    """Cuanto de energía (+20) o cuanto grande (+50, con un anillo): rombo menta con ħ."""
    k = 1.35 if big else 1.0
    body = path(f"M0,{-13 * k} L{11 * k},0 L0,{13 * k} L{-11 * k},0 Z", fill=P.PLAYER, opacity=0.9)
    ring = circle(0, 0, 19, stroke=P.PLAYER, sw=1.4, opacity=0.6, dash="3 4") if big else ""
    return ring + body + _hbar(0, 6 * k, 11 * k, P.VOID, sw=2.2 * k)


def quantum_well_sprite(lit: bool = False) -> str:
    """Pozo cuántico del juego. Sin `lit`, el pozo con sus niveles apagados y el
    objeto en el fondo; con `lit`, solo los tres niveles encendidos (se funden
    encima al pagar). El precio lo escribe el motor."""
    if lit:
        return "".join(path(f"M{-26 + i * 4},{12 - i * 9} L{26 - i * 4},{12 - i * 9}", stroke=P.PHOTON, sw=2.6) for i in range(3))
    well = path("M-34,-26 L-34,-4 Q-34,18 -18,18 L18,18 Q34,18 34,-4 L34,-26", stroke=P.INK, sw=2.4)
    levels = "".join(path(f"M{-26 + i * 4},{12 - i * 9} L{26 - i * 4},{12 - i * 9}", stroke=P.PHOTON, sw=1.2, opacity=0.8 - i * 0.22, dash="4 3" if i else "") for i in range(3))
    return well + levels + circle(0, 8, 6, fill=P.RARITY["common"])


def bound_electron_sprite() -> str:
    """Electrón ligado del juego sin su electrón (lo mueve el motor por la órbita): dos órbitas y el objeto raro dentro."""
    item = path("M0,-10 L9,0 L0,10 L-9,0 Z", fill=P.RARITY["rare"])
    orbit = ellipse(0, 0, 26, 12, stroke=P.NEGATIVE, sw=1.8, rotate=-20)
    orbit2 = ellipse(0, 0, 26, 12, stroke=P.NEGATIVE, sw=1.8, rotate=40, opacity=0.6)
    return orbit + orbit2 + item


def item_pedestal_sprite() -> str:
    """Pedestal: un nivel de energía corto con un haz tenue hacia arriba, donde flota el icono."""
    beam = "".join(path(f"M{x},-2 L{x * 0.6:.1f},-44", stroke=P.INK, sw=1, opacity=0.25, dash="2 4") for x in (-14, 14))
    base = rect(-22, -2, 44, 8, rx=3, fill=P.VOID_3, stroke=P.INK, sw=1.6)
    marks = "".join(path(f"M{x},6 L{x},2", stroke=P.INK_DIM, sw=1) for x in (-12, 0, 12))
    return beam + base + marks


def superposition_wave_sprite() -> str:
    """|ψ⟩ de la Superposición con trazos: barra, ψ y ángulo, sobre una onda cuántica."""
    c = P.FAMILY["quantum"]
    psi = path("M-6,-6 Q-6,2 0,2 Q6,2 6,-6 M0,-9 L0,7", stroke=c, sw=1.6)
    ket = path("M-12,-9 L-12,7 M10,-9 L15,-1 L10,7", stroke=c, sw=1.6)
    wave_ = polyline([(x, 16 + 3 * math.sin(x / 3)) for x in range(-24, 25)], stroke=c, sw=1.4)
    return psi + ket + wave_


def shopkeeper_sprite() -> str:
    """El Pión (tendero): pareja quark–antiquark (relleno y hueco) unidos por un muelle de gluón, con ojos rasgados."""
    q = circle(-14, 0, 12, fill=P.FAMILY["strong"])
    anti = circle(14, 0, 12, fill=P.VOID) + circle(14, 0, 12, stroke=P.FAMILY["strong"], sw=2.4)
    spring = polyline(coil(-3, 0, 3, 0, loops=3, r=3), stroke=P.FAMILY["strong"], sw=1.6)
    eyes = path("M-19,-3 L-15,-1 M-9,-3 L-13,-1", stroke=P.VOID, sw=2) + path("M9,-3 L13,-1 M19,-3 L15,-1", stroke=P.INK, sw=2)
    halo = circle(0, 0, 30, stroke=P.FAMILY["strong"], sw=1, opacity=0.3, dash="2 5")
    return halo + q + anti + spring + eyes


def icon_gem_sprite() -> str:
    """Joya de rareza: rombo blanco de 8 px que el motor tiñe con el color de la rareza."""
    return path("M0,-4 L4,0 L0,4 L-4,0 Z", fill="#FFFFFF")


# Glifos del juego: solo trazos y rellenos, sin texto. `c` es el color de la familia (INK en objetos).


def _gg_mass(c: str) -> str:  # Masa efectiva: núcleo menta con una pesa encima
    return circle(0, 4, 11, fill=P.PLAYER, opacity=0.85) + path("M-8,-14 L8,-14 M0,-14 L0,-7", stroke=P.INK, sw=2.2) + rect(-5, -18, 10, 6, rx=2, fill=P.INK)


def _gg_spin_up(c: str) -> str:  # Espín alto: flecha de espín y +1
    return path("M-2,14 L-2,-14 M-9,-7 L-2,-14 L5,-7", stroke=P.PLAYER, sw=2.6) + path("M8,10 L14,10 M11,7 L11,13 M16,6 L18,4 L18,15", stroke=P.INK, sw=1.6)


def _gg_planck(c: str) -> str:  # Constante de Planck: ħ
    return _hbar(0, 14, 26, c, sw=2.6)


def _gg_momentum(c: str) -> str:  # Momento lineal: partícula con líneas de velocidad
    lines = "".join(path(f"M{-18 + i * 2},{y} L{-6 + i},{y}", stroke=c, sw=1.6, opacity=0.5 + i * 0.15) for i, y in enumerate((-7, 0, 7)))
    return lines + circle(6, 0, 7, fill=P.PLAYER) + path("M14,-6 L19,0 L14,6", stroke=P.INK, sw=2)


def _gg_compton_length(c: str) -> str:  # Longitud de Compton: onda que se comprime entre dos flechas
    pts = [(x, 6 * math.sin(x * x / 30 + 1)) for x in [i * 0.5 for i in range(-28, 29)]]
    return polyline(pts, stroke=P.PLAYER, sw=2) + path("M-18,-14 L-10,-14 M-13,-17 L-10,-14 L-13,-11 M18,-14 L10,-14 M13,-17 L10,-14 L13,-11", stroke=c, sw=1.6)


def _gg_shielding(c: str) -> str:  # Apantallamiento nuclear: núcleo tras un escudo de arcos
    nucleus = circle(-6, 0, 4, fill=P.POSITIVE) + circle(0, -3, 4, fill=P.NEUTRAL) + circle(-1, 4, 4, fill=P.POSITIVE)
    arcs = "".join(path(f"M{8 + i * 4},-{14 - i} Q{16 + i * 4},0 {8 + i * 4},{14 - i}", stroke=P.NEGATIVE, sw=2 - i * 0.4, opacity=1 - i * 0.25) for i in range(3))
    return nucleus + arcs


def _gg_fine_structure(c: str) -> str:  # Constante de estructura fina: línea espectral desdoblada
    return path("M-4,-16 L-4,16 M4,-16 L4,16", stroke=P.PHOTON, sw=2.2) + polyline([(x, 18 + 2 * math.sin(x)) for x in [i * 0.5 for i in range(-32, 33)]], stroke=c, sw=1.2, opacity=0.6) + path("M-16,-2 L-9,-2 M16,-2 L9,-2", stroke=c, sw=1.4, dash="2 2")


def _gg_free_path(c: str) -> str:  # Recorrido libre medio: camino en zigzag entre colisiones
    pts = [(-16, 10), (-8, -4), (0, 6), (10, -10)]
    dots = "".join(circle(x, y, 2.2, fill=P.INK_DIM) for x, y in pts[1:-1])
    return polyline(pts, stroke=P.PLAYER, sw=2) + dots + path("M10,-10 L17,-14 M12,-16 L17,-14 L15,-9", stroke=P.PLAYER, sw=2)


def _gg_binding(c: str) -> str:  # Energía de enlace: dos nucleones unidos por un muelle
    return polyline(coil(-8, 0, 8, 0, loops=4, r=3), stroke=P.FAMILY["strong"], sw=1.8) + circle(-12, 0, 6, fill=P.POSITIVE) + circle(12, 0, 6, fill=P.NEUTRAL)


def _gg_bose_einstein(c: str) -> str:  # Condensado de Bose-Einstein: puntos que caen hacia un mismo estado
    dots = "".join(circle(16 * math.cos(a), 16 * math.sin(a), 2, fill=P.PHOTON, opacity=0.8) + path(f"M{13 * math.cos(a):.1f},{13 * math.sin(a):.1f} L{8 * math.cos(a):.1f},{8 * math.sin(a):.1f}", stroke=P.PHOTON, sw=1.2, opacity=0.6) for a in [i * math.tau / 8 for i in range(8)])
    return dots + circle(0, 0, 5, fill=P.PHOTON)


def _gg_photoelectric(c: str) -> str:  # Efecto fotoeléctrico: un fotón arranca un electrón de una placa
    plate = path("M-16,14 L16,14", stroke=P.INK, sw=3)
    ph = polyline([(-16 + i * 0.5, -14 + i * 0.5 + 2.4 * math.sin(i * 0.9)) for i in range(29)], stroke=P.PHOTON, sw=1.8)
    e = path("M2,12 L12,-8", stroke=P.NEGATIVE, sw=1.8) + circle(13, -10, 3.5, fill=P.NEGATIVE)
    return plate + ph + e


def _gg_compton_effect(c: str) -> str:  # Efecto Compton: un fotón rebota en un electrón
    inc = polyline([(-18 + i * 0.5, 2.6 * math.sin(i * 0.9)) for i in range(32)], stroke=P.PHOTON, sw=1.8)
    out = polyline([(-2 + i * 0.4, -i * 0.4 + 2 * math.sin(i * 0.7)) for i in range(38)], stroke=P.PHOTON, sw=1.6, opacity=0.8)
    return inc + out + circle(0, 0, 3.2, fill=P.NEGATIVE) + path("M0,0 L10,12", stroke=P.NEGATIVE, sw=1.8)


def _gg_doppler(c: str) -> str:  # Efecto Doppler: frentes de onda comprimidos hacia delante
    arcs = "".join(path(f"M{x},-{r} A{r},{r} 0 0 1 {x},{r}", stroke=P.PLAYER, sw=1.6, opacity=1 - i * 0.2) for i, (x, r) in enumerate(((4, 9), (2, 12), (-2, 15), (-8, 17))))
    return arcs + circle(-4, 0, 4, fill=P.PLAYER) + path("M10,-4 L16,0 L10,4", stroke=P.INK, sw=1.6)


def _gg_standing_wave(c: str) -> str:  # Onda estacionaria: envolvente con nodos
    a = polyline([(x, 9 * math.sin(x * math.pi / 12)) for x in [i * 0.5 for i in range(-36, 37)]], stroke=P.PLAYER, sw=2)
    b = polyline([(x, -9 * math.sin(x * math.pi / 12)) for x in [i * 0.5 for i in range(-36, 37)]], stroke=P.PLAYER, sw=1.4, opacity=0.5)
    nodes = "".join(circle(x, 0, 2, fill=P.INK) for x in (-12, 0, 12))
    return a + b + nodes


def _gg_half_life(c: str) -> str:  # Vida media: curva de desintegración exponencial
    axes = path("M-16,-14 L-16,14 L16,14", stroke=P.INK_DIM, sw=1.4)
    curve = polyline([(-16 + i, -12 + 26 * (1 - math.exp(-i / 9))) for i in range(33)], stroke=P.FAMILY["weak"], sw=2.2)
    half = path("M-16,1 L-10,1 L-10,14", stroke=P.FAMILY["weak"], sw=1, dash="2 2", opacity=0.7)
    return axes + half + curve


def _gg_vacuum_energy(c: str) -> str:  # Energía del vacío: bucle de un par virtual con un cuanto
    loop = ellipse(0, 0, 16, 10, stroke=P.INK, sw=1.4, dash="3 3")
    pair = circle(-16, 0, 3.5, fill=P.NEGATIVE) + circle(16, 0, 3.5, fill=P.VOID) + circle(16, 0, 3.5, stroke=P.POSITIVE, sw=1.4)
    return loop + pair + path("M0,-7 L6,0 L0,7 L-6,0 Z", fill=P.PLAYER)


def _gg_zeno(c: str) -> str:  # Efecto Zenón: un ojo que observa (y congela)
    eye = path("M-18,0 Q0,-16 18,0 Q0,16 -18,0 Z", stroke=P.INK, sw=2)
    return eye + circle(0, 0, 6, fill=P.NEGATIVE) + circle(0, 0, 2.5, fill=P.VOID) + path("M-6,-16 L-4,-12 M6,-16 L4,-12 M0,-18 L0,-13", stroke=P.INK_DIM, sw=1.4)


def _gg_collapse(c: str) -> str:  # Colapso: una onda que colapsa en un pico
    left = polyline([(x, 4 * math.sin(x * 0.8) * (1 - abs(x) / 18)) for x in [i * 0.5 for i in range(-36, -4)]], stroke=P.FAMILY["quantum"], sw=1.6, opacity=0.6)
    right = polyline([(x, 4 * math.sin(x * 0.8) * (1 - abs(x) / 18)) for x in [i * 0.5 for i in range(5, 37)]], stroke=P.FAMILY["quantum"], sw=1.6, opacity=0.6)
    spike = path("M-4,8 L0,-16 L4,8", stroke=P.INK, sw=2.2)
    return left + right + spike + path("M-16,8 L16,8", stroke=P.INK_DIM, sw=1.2)


def _gg_wave_packet(c: str) -> str:  # Transformación Paquete de ondas: envolvente gaussiana
    pts = [(x, 12 * math.exp(-(x / 8) ** 2) * math.sin(x * 1.2)) for x in [i * 0.5 for i in range(-36, 37)]]
    env = polyline([(x, -12 * math.exp(-(x / 8) ** 2)) for x in [i * 0.5 for i in range(-36, 37)]], stroke=P.PLAYER, sw=1, opacity=0.5, dash="2 2")
    return env + polyline(pts, stroke=P.PLAYER, sw=2.2)


def _gg_heart_wave(c: str) -> str:  # Corazón-onda: aumento de coherencia máxima
    heart = path("M0,12 C-18,0 -14,-16 0,-6 C14,-16 18,0 0,12 Z", stroke=P.PLAYER, sw=2.2)
    return heart + polyline([(x, 2 * math.sin(x * 0.9)) for x in [i * 0.5 for i in range(-14, 15)]], stroke=P.PLAYER, sw=1.6) + path("M10,-16 L16,-16 M13,-19 L13,-13", stroke=P.INK, sw=1.6)


def _gg_heal(c: str) -> str:  # Curación: cuanto de energía grande
    return g(heal_sprite(big=False), scale=1.1)


def _gg_reroll(c: str) -> str:  # Reintento de la tienda: dos flechas en círculo alrededor de un fotón
    arcs = path("M-14,-4 A14,14 0 0 1 10,-10 M14,4 A14,14 0 0 1 -10,10", stroke=c, sw=2.2)
    heads = path("M10,-10 L11,-17 M10,-10 L3,-11 M-10,10 L-11,17 M-10,10 L-3,11", stroke=c, sw=2.2)
    return arcs + heads + g(photon_sprite(1), scale=0.7)


def _gg_eye(c: str) -> str:  # Recompensa de observable: un ojo
    return path("M-14,0 Q0,-12 14,0 Q0,12 -14,0 Z", stroke=P.INK, sw=2) + circle(0, 0, 5, fill=P.INK) + circle(0, 0, 2, fill=P.VOID)


# Interacciones (Fase 8)


def _gg_arc(c: str) -> str:  # Arco voltaico: línea eléctrica horizontal
    return polyline([(-18, 4), (-10, -4), (-4, 4), (2, -6), (8, 4), (18, -4)], stroke=c, sw=2.2) + circle(-18, 4, 2.5, fill=c) + circle(18, -4, 2.5, fill=c)


def _gg_faraday(c: str) -> str:  # Campo de Faraday: jaula alrededor de una partícula
    cage = circle(0, 0, 15, stroke=c, sw=1.8) + path("M-15,0 L15,0 M0,-15 L0,15 M-10.6,-10.6 L10.6,10.6 M-10.6,10.6 L10.6,-10.6", stroke=c, sw=1, opacity=0.5)
    return cage + circle(0, 0, 4, fill=P.PLAYER)


def _gg_nuclear_charge(c: str) -> str:  # Carga nuclear: embestida que atraviesa
    return path("M-18,0 L10,0 M4,-7 L12,0 L4,7", stroke=c, sw=2.4) + "".join(path(f"M{-14 + i * 6},{-8 + (i % 2) * 16} L{-10 + i * 6},{-4 + (i % 2) * 8}", stroke=c, sw=1.4, opacity=0.6) for i in range(3)) + circle(15, 0, 3, fill=P.INK)


def _gg_color_charge(c: str) -> str:  # Color: las tres cargas de color
    return "".join(circle(math.cos(a) * 8, math.sin(a) * 8, 6, fill=col) for a, col in zip((-math.pi / 2, math.pi / 6, 5 * math.pi / 6), P.QUARK_COLORS)) + circle(0, 0, 15, stroke=c, sw=1.2, opacity=0.6)


def _gg_ghost_neutrino(c: str) -> str:  # Neutrino fantasma: mira punteada casi invisible
    return circle(0, 0, 12, stroke=c, sw=1.6, dash="2 3") + path("M-18,0 L-8,0 M8,0 L18,0 M0,-18 L0,-8 M0,8 L0,18", stroke=c, sw=1.4, opacity=0.7) + circle(0, 0, 2.5, fill=c, opacity=0.6)


def _gg_flavor_change(c: str) -> str:  # Cambio de sabor: dos flechas que se intercambian
    return path("M-14,-6 L10,-6 M5,-11 L10,-6 L5,-1 M14,6 L-10,6 M-5,1 L-10,6 L-5,11", stroke=c, sw=2.2)


def _gg_radioactivity(c: str) -> str:  # Radiactividad: trébol
    blades = ""
    for k in range(3):
        a = math.radians(-90 + k * 120)
        a0, a1 = a - math.radians(30), a + math.radians(30)
        blades += path(f"M{5 * math.cos(a0):.1f},{5 * math.sin(a0):.1f} L{16 * math.cos(a0):.1f},{16 * math.sin(a0):.1f} A16,16 0 0 1 {16 * math.cos(a1):.1f},{16 * math.sin(a1):.1f} L{5 * math.cos(a1):.1f},{5 * math.sin(a1):.1f} A5,5 0 0 0 {5 * math.cos(a0):.1f},{5 * math.sin(a0):.1f} Z", fill=c)
    return blades + circle(0, 0, 3, fill=c)


def _gg_time_dilation(c: str) -> str:  # Dilatación temporal: reloj estirado
    return ellipse(0, 0, 17, 11, stroke=c, sw=2) + path("M0,0 L0,-7 M0,0 L8,2", stroke=P.INK, sw=1.8) + path("M-17,0 L-21,0 M17,0 L21,0", stroke=c, sw=1.4, opacity=0.6)


def _gg_gravity_assist(c: str) -> str:  # Asistencia gravitatoria: trayectoria que rodea una masa
    return circle(4, 6, 6, fill=c) + path("M-18,14 Q-10,-6 4,-6 Q16,-6 14,-18", stroke=P.PLAYER, sw=2) + path("M10,-16 L14,-18 L15,-13", stroke=P.PLAYER, sw=2)


def _gg_gravitational_wave(c: str) -> str:  # Onda gravitacional: ondas concéntricas
    return "".join(circle(0, 0, r, stroke=c, sw=2 - i * 0.4, opacity=1 - i * 0.25) for i, r in enumerate((6, 11, 16))) + circle(0, 0, 2.5, fill=c)


def _gg_orbit(c: str) -> str:  # Órbita: dos partículas alrededor de Wilas
    return circle(0, 0, 14, stroke=c, sw=1.4, dash="3 3") + circle(0, 0, 5, fill=P.PLAYER) + circle(14, 0, 3.5, fill=c) + circle(-14, 0, 3.5, fill=c)


def _gg_lens(c: str) -> str:  # Lente gravitatoria: rayos que se curvan alrededor de una masa
    return circle(0, 0, 5, fill=P.FAMILY["gravity"]) + path("M-18,-10 Q0,-2 18,-10 M-18,10 Q0,2 18,10", stroke=P.FAMILY["electromagnetic"], sw=1.8)


def _gg_electroweak(c: str) -> str:  # Electrodébil: cadena eléctrica que se desintegra
    return polyline([(-16, -8), (-6, -2), (-10, 4), (2, 10)], stroke=P.FAMILY["electromagnetic"], sw=2.2) + path("M2,10 L12,2 M2,10 L14,14", stroke=P.FAMILY["weak"], sw=1.8) + circle(2, 10, 2, fill=P.INK)


GAME_GLYPHS = {
    "mass": _gg_mass,
    "spin_up": _gg_spin_up,
    "planck": _gg_planck,
    "momentum": _gg_momentum,
    "compton_length": _gg_compton_length,
    "shielding": _gg_shielding,
    "fine_structure": _gg_fine_structure,
    "free_path": _gg_free_path,
    "binding": _gg_binding,
    "bose_einstein": _gg_bose_einstein,
    "photoelectric": _gg_photoelectric,
    "compton_effect": _gg_compton_effect,
    "doppler": _gg_doppler,
    "standing_wave": _gg_standing_wave,
    "half_life": _gg_half_life,
    "vacuum_energy": _gg_vacuum_energy,
    "zeno": _gg_zeno,
    "collapse": _gg_collapse,
    "wave_packet": _gg_wave_packet,
    "heart_wave": _gg_heart_wave,
    "heal": _gg_heal,
    "eye": _gg_eye,
    "reroll": _gg_reroll,
    "chain": lambda c: without_glow(_g_chain(c)),
    "photon_vertex": lambda c: without_glow(_g_photon_vertex(c)),
    "fission": lambda c: without_glow(_g_fission(c)),
    "gluon": lambda c: without_glow(_g_gluon(c)),
    "beta": lambda c: without_glow(_g_beta(c)),
    "superposition": lambda c: without_glow(_g_superposition(c)),
    "spin": lambda c: without_glow(_g_spin(c)),
    "arc": _gg_arc,
    "faraday": _gg_faraday,
    "nuclear_charge": _gg_nuclear_charge,
    "color_charge": _gg_color_charge,
    "ghost_neutrino": _gg_ghost_neutrino,
    "flavor_change": _gg_flavor_change,
    "radioactivity": _gg_radioactivity,
    "time_dilation": _gg_time_dilation,
    "gravity_assist": _gg_gravity_assist,
    "gravitational_wave": _gg_gravitational_wave,
    "orbit": _gg_orbit,
    "lens": _gg_lens,
    "electroweak": _gg_electroweak,
}

# Iconos del juego: id → (marco, glifo). Los marcos "a+b" son unificaciones:
# el marco de la primera familia con el de la segunda dentro, más pequeño.
GAME_ICONS = {
    # Observables (Fase 7)
    "effective_mass": ("item", "mass"),
    "high_spin": ("item", "spin_up"),
    "planck_constant": ("item", "planck"),
    "linear_momentum": ("item", "momentum"),
    "compton_length": ("item", "compton_length"),
    "nuclear_shielding": ("item", "shielding"),
    "fine_structure": ("item", "fine_structure"),
    "mean_free_path": ("item", "free_path"),
    "binding_energy": ("item", "binding"),
    "bose_einstein": ("item", "bose_einstein"),
    "photoelectric_effect": ("item", "photoelectric"),
    "compton_effect": ("item", "compton_effect"),
    "doppler_effect": ("item", "doppler"),
    "standing_wave": ("item", "standing_wave"),
    "half_life": ("item", "half_life"),
    "vacuum_energy": ("item", "vacuum_energy"),
    # Operadores
    "zeno_effect": ("item", "zeno"),
    "collapse": ("item", "collapse"),
    # Transformaciones y elecciones
    "wave_packet": ("item", "wave_packet"),
    "rest_heal": ("item", "heal"),
    "rest_max_hp": ("item", "heart_wave"),
    "shop_reroll": ("item", "reroll"),
    # Interacciones (Fase 8)
    "chain_discharge": ("electromagnetic", "chain"),
    "ionic_jump": ("electromagnetic", "photon_vertex"),
    "voltaic_arc": ("electromagnetic", "arc"),
    "faraday_cage": ("electromagnetic", "faraday"),
    "fission": ("strong", "fission"),
    "confinement": ("strong", "gluon"),
    "nuclear_charge": ("strong", "nuclear_charge"),
    "color_charge": ("strong", "color_charge"),
    "beta_decay": ("weak", "beta"),
    "ghost_neutrino": ("weak", "ghost_neutrino"),
    "flavor_change": ("weak", "flavor_change"),
    "radioactivity": ("weak", "radioactivity"),
    "time_dilation": ("gravity", "time_dilation"),
    "gravity_assist": ("gravity", "gravity_assist"),
    "gravitational_wave": ("gravity", "gravitational_wave"),
    "orbit": ("gravity", "orbit"),
    "superposition": ("quantum", "superposition"),
    "spin": ("quantum", "spin"),
    "electroweak": ("electromagnetic+weak", "electroweak"),
    "gravitational_lens": ("gravity+electromagnetic", "lens"),
}


def game_icon(icon_id: str) -> str:
    """Icono del juego (64 px, marco de ~56): marco de la familia y glifo, sin joya ni filtros."""
    frame_kind, glyph = GAME_ICONS[icon_id]
    kinds = frame_kind.split("+")
    color = P.FAMILY.get(kinds[0], P.INK)
    frame = _frame(kinds[0], color)
    if len(kinds) > 1:
        inner = P.FAMILY[kinds[1]]
        frame += g(_frame(kinds[1], inner).replace(f'fill="{P.VOID_2}"', 'fill="none"'), scale=0.78)
    return frame + GAME_GLYPHS[glyph](color)


REWARD_GAME_GLYPHS = {
    "coins": lambda: photon_sprite(5),
    "key": positron_sprite,
    "item": lambda: _gg_eye(P.INK),
}


def reward_game_icon(reward: str) -> str:
    """Icono de recompensa de bifurcación del juego (sin filtros)."""
    frame = rect(-20, -20, 40, 40, rx=8, fill=P.VOID_2, stroke=P.INK, sw=2)
    return frame + g(REWARD_GAME_GLYPHS[reward](), scale=0.9)
