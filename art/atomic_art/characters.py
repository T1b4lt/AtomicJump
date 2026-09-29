"""Personajes jugables. Todos centrados en (0, 0), unos 40 px de diámetro.

Reglas de diseño:
- El verde menta (PLAYER) es exclusivo del jugador.
- Solo el jugador tiene dos ojos redondos: es lo que le da personalidad.
"""

from . import palette as P
from .svg import circle, ellipse, g, path, radial

R = 20  # radio del núcleo de Wilas


def front_arc(rx: float, ry: float, rotate: float, color: str, sw: float, opacity: float = 0.95) -> str:
    """Mitad delantera de un orbital, para que el anillo rodee al núcleo."""
    return f'<g transform="rotate({rotate})">' + path(f"M{rx},0 A{rx},{ry} 0 0 1 {-rx},0", stroke=color, sw=sw, opacity=opacity) + "</g>"


def _eyes(expression: str, dx: float = 7, y: float = -2, r: float = 4.2) -> str:
    """Ojos de Wilas según la expresión."""
    out = ""
    for sx in (-1, 1):
        x = sx * dx
        if expression == "neutral":
            out += ellipse(x, y, r * 0.8, r * 1.15, fill=P.VOID)
            out += circle(x + 1.2, y - 1.6, 1.3, fill=P.INK)
        elif expression == "happy":
            out += path(f"M{x - r},{y + 1} Q{x},{y - r * 1.6} {x + r},{y + 1}", stroke=P.VOID, sw=2.4)
        elif expression == "jump":
            out += ellipse(x, y - 1.5, r * 0.8, r * 1.35, fill=P.VOID)
            out += circle(x + 1.0, y - 4, 1.3, fill=P.INK)
        elif expression == "blink":
            out += path(f"M{x - r * 0.8},{y} L{x + r * 0.8},{y}", stroke=P.VOID, sw=2.4)
        elif expression == "hurt":
            out += path(f"M{x - 3},{y - 3} L{x + 3},{y + 3} M{x + 3},{y - 3} L{x - 3},{y + 3}", stroke=P.VOID, sw=2.2)
        elif expression == "focus":
            out += path(f"M{x - r},{y - 2 + sx * 1.5} L{x + r},{y - 2 - sx * 1.5}", stroke=P.VOID, sw=2)
            out += ellipse(x, y + 1, r * 0.75, r * 0.7, fill=P.VOID)
    return out


def _core(color: str, deep: str, r: float, gid: str) -> str:
    grad = radial(gid, [(0, "#FFFFFF", 1), (0.35, color, 1), (1, deep, 1)])
    return f"<defs>{grad}</defs>" + circle(0, 0, r, fill=f"url(#{gid})")


def wilas(
    expression: str = "neutral",
    *,
    sx: float = 1,
    sy: float = 1,
    orbit_angle: float = -25,
    electron_phase: float = 40,
    flash: float = 0,
    uid: str = "w",
) -> str:
    """Wilas: núcleo luminoso, un orbital inclinado con su electrón y dos ojos.

    `electron_phase` (grados) es la posición del electrón en el orbital: en la mitad
    superior pasa por detrás del núcleo. `flash` (0–1) tiñe de blanco al recibir daño.
    """
    import math

    ring = ellipse(0, 0, R * 1.55, R * 0.55, stroke=P.PLAYER, sw=1.6, rotate=orbit_angle, opacity=0.85)
    a = math.radians(orbit_angle)
    phi = math.radians(electron_phase)
    ex, ey = R * 1.55 * math.cos(phi), R * 0.55 * math.sin(phi)
    ex, ey = ex * math.cos(a) - ey * math.sin(a), ex * math.sin(a) + ey * math.cos(a)
    electron = g(circle(ex, ey, 2.6, fill=P.INK), glow=3)
    behind = math.sin(phi) < 0
    halo = circle(0, 0, R + 5, fill=P.PLAYER, opacity=0.12)
    body = halo + _core(P.PLAYER, P.PLAYER_DEEP, R, f"core_{uid}")
    if flash:
        body += circle(0, 0, R, fill="#FFFFFF", opacity=flash)
    body += _eyes(expression)
    body = f'<g transform="scale({sx},{sy})">{body}</g>'
    front = g(front_arc(R * 1.55, R * 0.55, orbit_angle, P.PLAYER, 1.6), glow=2)
    return g(ring, glow=2) + (electron if behind else "") + body + front + ("" if behind else electron)


def muon(uid: str = "mu") -> str:
    """Muón: tanque. Núcleo grande y cuadrado, doble anillo pesado."""
    grad = radial(f"core_{uid}", [(0, "#FFFFFF", 1), (0.3, P.PLAYER, 1), (1, P.PLAYER_DEEP, 1)])
    body = f"<defs>{grad}</defs>" + f'<rect x="-24" y="-22" width="48" height="44" rx="14" fill="url(#core_{uid})"/>'
    rings = ellipse(0, 0, 36, 12, stroke=P.PLAYER, sw=3, rotate=-12, opacity=0.9) + ellipse(0, 0, 32, 9, stroke=P.PLAYER, sw=1.2, rotate=18, opacity=0.6)
    front = front_arc(36, 12, -12, P.PLAYER, 3) + front_arc(32, 9, 18, P.PLAYER, 1.2, 0.6)
    return g(rings, glow=2) + body + _eyes("focus", dx=9, r=4.6) + g(front, glow=2)


def neutrino(uid: str = "nu") -> str:
    """Neutrino: pequeño, casi fantasma, contorno punteado."""
    body = circle(0, 0, 14, fill=P.PLAYER, opacity=0.25) + circle(0, 0, 14, stroke=P.PLAYER, sw=1.6, dash="3 3")
    trail = "".join(circle(-18 - i * 9, 4 + i * 2, 5 - i, fill=P.PLAYER, opacity=0.25 - i * 0.05) for i in range(4))
    return g(trail, glow=2) + g(body, glow=2) + _eyes("neutral", dx=5, r=3)


def tau(uid: str = "tau") -> str:
    """Tau: rombo afilado que se desintegra en fragmentos."""
    grad = radial(f"core_{uid}", [(0, "#FFFFFF", 1), (0.35, P.PLAYER, 1), (1, P.PLAYER_DEEP, 1)])
    body = f"<defs>{grad}</defs>" + path("M0,-26 L22,0 L0,26 L-22,0 Z", fill=f"url(#core_{uid})")
    shards = "".join(
        path(f"M{x},{y} l4,-6 l3,7 Z", fill=P.PLAYER, opacity=o)
        for x, y, o in [(26, -18, 0.8), (32, -6, 0.5), (-30, 14, 0.6), (-36, 22, 0.3), (24, 20, 0.45)]
    )
    return g(shards, glow=2) + body + _eyes("focus", dx=7, r=3.8)
