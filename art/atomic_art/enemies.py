"""Enemigos y jefes. Centrados en (0, 0).

Reglas de diseño:
- Color = carga eléctrica real: negativa cian, positiva magenta, neutra blanco frío.
- Materia = relleno sólido. Antimateria = núcleo oscuro con contorno de color (imagen en negativo).
- Los enemigos nunca tienen ojos redondos: una rendija o marcas angulares.
- Cada enemigo lleva su "traza" (la huella de su movimiento), que anticipa cómo se mueve.
"""

import math

from . import palette as P
from .svg import circle, coil, ellipse, g, path, polyline, radial


def _slit(w: float = 10, y: float = 0, color: str = P.VOID, angry: bool = True) -> str:
    """Dos ojos rasgados inclinados hacia dentro: la mirada de los enemigos."""
    t = w * 0.16 if angry else 0
    gap = w * 0.2
    eye = lambda x0, x1, y0, y1: f"M{x0:.2f},{y0:.2f} L{x1:.2f},{y1:.2f} L{x1:.2f},{y1 + 3.2:.2f} L{x0:.2f},{y0 + 2:.2f} Z"
    d = eye(-w / 2 - 1, -gap, y - t - 1, y + t) + " " + eye(w / 2 + 1, gap, y - t - 1, y + t)
    return path(d, fill=color, stroke=color, sw=0.8)


def _sphere(r: float, color: str, uid: str, hot: str = "#FFFFFF") -> str:
    grad = radial(f"sph_{uid}", [(0, hot, 1), (0.45, color, 1), (1, color, 0.55)])
    return f"<defs>{grad}</defs>" + circle(0, 0, r, fill=f"url(#sph_{uid})")


def _anti(r: float, color: str) -> str:
    """Antimateria: vacío rodeado de luz."""
    return circle(0, 0, r, fill=P.VOID) + g(circle(0, 0, r, stroke=color, sw=2.5), glow=3) + circle(0, 0, r * 0.45, stroke=color, sw=1, opacity=0.5)


# --- Capa K -----------------------------------------------------------------


def orbital_electron(uid: str = "oe") -> str:
    """Electrón orbital: gira alrededor de un punto. Su traza es el círculo de la órbita."""
    orbit = circle(-34, 0, 34, stroke=P.NEGATIVE, sw=1, dash="2 5", opacity=0.45)
    arc = path("M0,0 A34,34 0 0 0 -34,-34", stroke=P.NEGATIVE, sw=3, opacity=0.35)
    body = _sphere(11, P.NEGATIVE, uid) + _slit(9, 1)
    return orbit + g(arc, glow=3) + g(body, glow=2) + circle(-34, 0, 2, fill=P.NEGATIVE, opacity=0.6)


def free_neutron(uid: str = "fn") -> str:
    """Neutrón libre: tres quarks (udd) dentro de una cápsula neutra que patrulla."""
    shell = circle(0, 0, 17, fill=P.VOID_3, stroke=P.NEUTRAL, sw=2)
    quarks = circle(-6, -4, 4, fill=P.QUARK_COLORS[0]) + circle(6, -4, 4, fill=P.QUARK_COLORS[1]) + circle(0, 6, 4, fill=P.QUARK_COLORS[2])
    crack = path("M10,-14 L6,-7 L11,-3", stroke=P.NEUTRAL, sw=1.4, opacity=0.8)
    feet = path("M-12,15 L-16,22 M12,15 L16,22", stroke=P.NEUTRAL, sw=2)
    return g(shell + feet, glow=1) + g(quarks, glow=2) + crack + _slit(12, -12, P.NEUTRAL, angry=True)


def alpha_particle(uid: str = "ap") -> str:
    """Partícula alfa: 2 protones + 2 neutrones, pesada, embiste en horizontal."""
    lines = "".join(path(f"M{-34 - i * 4},{y} l-{16 + i * 6},0", stroke=P.POSITIVE, sw=2, opacity=0.6 - i * 0.15) for i, y in enumerate((-10, 0, 10)))
    balls = (
        g(_sphere(11, P.POSITIVE, uid + "a"), x=-8, y=-8)
        + g(_sphere(11, P.NEUTRAL, uid + "b", hot="#FFFFFF"), x=8, y=-8)
        + g(_sphere(11, P.NEUTRAL, uid + "c"), x=-8, y=8)
        + g(_sphere(11, P.POSITIVE, uid + "d"), x=8, y=8)
    )
    return g(lines, glow=2) + g(balls, glow=2) + _slit(14, -1)


# --- Capa L -----------------------------------------------------------------


def muon_enemy(uid: str = "me") -> str:
    """Muón: cae en picado desde arriba con una traza vertical larga."""
    trail = path("M0,-70 L0,-10", stroke=P.NEGATIVE, sw=6, opacity=0.18) + path("M0,-80 L0,-10", stroke=P.NEGATIVE, sw=1.5, opacity=0.7)
    body = path("M0,16 L-11,-8 Q0,-18 11,-8 Z", fill=P.NEGATIVE)
    return g(trail, glow=3) + g(body, glow=2) + _slit(9, -3)


def kaon(uid: str = "ka") -> str:
    """Kaón: oscila entre sólido (vulnerable) e intangible. Mitad y mitad."""
    solid = path("M0,-16 A16,16 0 0 0 0,16 Z", fill=P.NEUTRAL)
    ghost = path("M0,-16 A16,16 0 0 1 0,16", stroke=P.NEUTRAL, sw=2, dash="3 3") + path("M0,-16 A16,16 0 0 1 0,16 Z", fill=P.NEUTRAL, opacity=0.15)
    osc = polyline([(x, -26 + 4 * math.sin(x / 3)) for x in range(-18, 19)], stroke=P.NEUTRAL, sw=1.2, opacity=0.7)
    return g(solid, glow=2) + g(ghost, glow=1) + osc + _slit(12, 0)


def antiproton(uid: str = "apr") -> str:
    """Antiprotón: antimateria. Si te toca, se aniquila contigo."""
    spikes = "".join(
        path(f"M{math.cos(a) * 20:.1f},{math.sin(a) * 20:.1f} L{math.cos(a) * 27:.1f},{math.sin(a) * 27:.1f}", stroke=P.NEGATIVE, sw=2)
        for a in [i * math.pi / 4 for i in range(8)]
    )
    return g(spikes, glow=2) + _anti(18, P.NEGATIVE) + _slit(12, 0, P.NEGATIVE)


# --- Capa M -----------------------------------------------------------------


def neutrino_enemy(uid: str = "ne") -> str:
    """Neutrino: casi invisible, atraviesa paredes. Solo destella."""
    return g(circle(0, 0, 12, stroke=P.NEUTRAL, sw=1.2, dash="1 4", opacity=0.6), glow=2) + circle(0, 0, 3, fill=P.NEUTRAL, opacity=0.8) + g(
        path("M-22,0 L-14,0 M14,0 L22,0 M0,-22 L0,-14 M0,14 L0,22", stroke=P.NEUTRAL, sw=1, opacity=0.5), glow=1
    )


def virtual_pair(uid: str = "vp") -> str:
    """Partículas virtuales: pareja partícula-antipartícula unida por un bucle."""
    loop = ellipse(0, 0, 26, 14, stroke=P.INK_DIM, sw=1.2, dash="4 3", opacity=0.8)
    a = g(_sphere(9, P.NEGATIVE, uid) + _slit(7, 0), x=-26, glow=2)
    b = g(_anti(9, P.POSITIVE), x=26)
    return loop + a + b


def monopole(uid: str = "mo") -> str:
    """Monopolo: desvía proyectiles con sus líneas de campo."""
    field = "".join(
        path(f"M{math.cos(t) * 18:.1f},{math.sin(t) * 18:.1f} Q{math.cos(t + 0.4) * 34:.1f},{math.sin(t + 0.4) * 34:.1f} {math.cos(t + 0.2) * 44:.1f},{math.sin(t + 0.2) * 44:.1f}", stroke=P.FAMILY["gravity"], sw=1.2, opacity=0.6)
        for t in [i * math.pi / 5 for i in range(10)]
    )
    core = path("M-16,0 A16,16 0 0 1 16,0 Z", fill=P.POSITIVE) + path("M-16,0 A16,16 0 0 0 16,0 Z", fill=P.NEGATIVE)
    return g(field, glow=2) + g(core, glow=2) + _slit(12, 0)


# --- Capa N -----------------------------------------------------------------


def quark_triplet(uid: str = "qt") -> str:
    """Trío de quarks unidos por muelles de gluón (confinamiento)."""
    pts = [(0, -22), (-20, 14), (20, 14)]
    springs = "".join(polyline(coil(*pts[i], *pts[(i + 1) % 3], loops=5, r=3.5), stroke=P.FAMILY["strong"], sw=1.4, opacity=0.9) for i in range(3))
    quarks = "".join(g(_sphere(8, c, f"{uid}{i}") + _slit(6, 0), x=x, y=y) for i, ((x, y), c) in enumerate(zip(pts, P.QUARK_COLORS)))
    return g(springs, glow=1) + g(quarks, glow=2)


def tau_enemy(uid: str = "te") -> str:
    """Tau: élite rápida y agresiva, estrella de puntas."""
    pts = []
    for i in range(12):
        a = i * math.pi / 6 - math.pi / 2
        r = 26 if i % 2 == 0 else 13
        pts.append((math.cos(a) * r, math.sin(a) * r))
    d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"
    return g(path(d, fill=P.NEGATIVE), glow=3) + circle(0, 0, 9, fill=P.VOID) + _slit(10, 0, P.NEGATIVE)


def z_boson(uid: str = "zb") -> str:
    """Bosón Z: torreta pesada que dispara en abanico."""
    hexa = "M" + " L".join(f"{math.cos(i * math.pi / 3) * 22:.1f},{math.sin(i * math.pi / 3) * 22:.1f}" for i in range(6)) + " Z"
    emit = "".join(
        g(polyline([(x, 2.5 * math.sin(x / 2.2)) for x in range(24, 44)], stroke=P.NEUTRAL, sw=1.5), rotate=a) for a in (-150, -120, -90, -60, -30)
    )
    return g(emit, glow=2) + g(path(hexa, fill=P.VOID_3, stroke=P.NEUTRAL, sw=2.5), glow=1) + path("M-8,-6 L8,-6 L-8,6 L8,6", stroke=P.NEUTRAL, sw=2.2)


# --- Jefes ------------------------------------------------------------------


def pauli_pair(uid: str = "pp") -> str:
    """Jefe Capa K: dos electrones 1s gemelos con espín opuesto, siempre en espejo."""
    orbit = ellipse(0, 0, 120, 44, stroke=P.NEGATIVE, sw=1.2, dash="3 6", opacity=0.5)
    axis = path("M0,-90 L0,90", stroke=P.INK_DIM, sw=1, dash="2 6", opacity=0.6)

    def twin(x: float, spin_up: bool, shielded: bool, id_: str) -> str:
        body = _sphere(34, P.NEGATIVE, id_)
        arrow_y = 1 if spin_up else -1
        arrow = path(f"M0,{24 * arrow_y} L0,{-24 * arrow_y} M-8,{-14 * arrow_y} L0,{-24 * arrow_y} L8,{-14 * arrow_y}", stroke=P.VOID, sw=4)
        shield = g(circle(0, 0, 46, stroke=P.INK, sw=2.5, dash="10 5"), glow=3) if shielded else ""
        crown = "".join(path(f"M{math.cos(a) * 38:.1f},{math.sin(a) * 38:.1f} L{math.cos(a) * 48:.1f},{math.sin(a) * 48:.1f}", stroke=P.NEGATIVE, sw=3) for a in [i * math.pi / 6 for i in range(12)])
        return g(g(crown, glow=2) + g(body, glow=3) + arrow + shield, x=x)

    return axis + orbit + twin(-120, True, False, uid + "a") + twin(120, False, True, uid + "b")


ROSTER = {
    "K": [("Electrón orbital", orbital_electron, "−"), ("Neutrón libre", free_neutron, "0"), ("Partícula alfa", alpha_particle, "+")],
    "L": [("Muón", muon_enemy, "−"), ("Kaón", kaon, "0"), ("Antiprotón", antiproton, "−̄")],
    "M": [("Neutrino", neutrino_enemy, "0"), ("Partículas virtuales", virtual_pair, "±"), ("Monopolo", monopole, "N/S")],
    "N": [("Trío de quarks", quark_triplet, "color"), ("Tau", tau_enemy, "−"), ("Bosón Z", z_boson, "0")],
}
