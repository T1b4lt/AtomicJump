"""Utilidades mínimas para componer SVG como texto."""

from pathlib import Path

import resvg_py

from . import palette as P

FONT_SANS = "DejaVu Sans"
FONT_MONO = "DejaVu Sans Mono"


def doc(width: float, height: float, body: str, *, background: str | None = None, glow: bool = True) -> str:
    """Documento SVG completo.

    `glow` añade los filtros de brillo. Solo se usan en las previsualizaciones:
    el importador SVG de Godot no soporta filtros y el brillo en el juego lo pone el motor.
    """
    bg = f'<rect width="100%" height="100%" fill="{background}"/>' if background else ""
    defs = GLOW_DEFS if glow else ""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
        f"<defs>{defs}</defs>{bg}{body}</svg>"
    )


GLOW_DEFS = "".join(
    f'<filter id="glow{n}" x="-60%" y="-60%" width="220%" height="220%">'
    f'<feGaussianBlur in="SourceGraphic" stdDeviation="{n}" result="b"/>'
    f'<feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>'
    f"</filter>"
    for n in (1, 2, 3, 4, 6, 8, 12)
)


def without_glow(body: str) -> str:
    """Quita los filtros de brillo de un fragmento, para reutilizar en el juego un asset de previsualización."""
    import re

    return re.sub(r' filter="url\(#glow\d+\)"', "", body)


def g(body: str, *, x: float = 0, y: float = 0, scale: float = 1, rotate: float = 0, glow: int | None = None, opacity: float = 1, extra: str = "") -> str:
    t = f"translate({x:.2f},{y:.2f})"
    if rotate:
        t += f" rotate({rotate:.2f})"
    if scale != 1:
        t += f" scale({scale:.3f})"
    f = f' filter="url(#glow{glow})"' if glow else ""
    o = f' opacity="{opacity}"' if opacity != 1 else ""
    return f'<g transform="{t}"{f}{o} {extra}>{body}</g>'


def circle(cx: float, cy: float, r: float, *, fill: str = "none", stroke: str = "none", sw: float = 0, opacity: float = 1, dash: str = "") -> str:
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="{r:.2f}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" opacity="{opacity}"{d}/>'


def ellipse(cx: float, cy: float, rx: float, ry: float, *, fill: str = "none", stroke: str = "none", sw: float = 0, rotate: float = 0, opacity: float = 1, dash: str = "") -> str:
    t = f' transform="rotate({rotate} {cx} {cy})"' if rotate else ""
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<ellipse cx="{cx:.2f}" cy="{cy:.2f}" rx="{rx:.2f}" ry="{ry:.2f}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" opacity="{opacity}"{t}{d}/>'


def path(d: str, *, fill: str = "none", stroke: str = "none", sw: float = 0, opacity: float = 1, dash: str = "", cap: str = "round") -> str:
    ds = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" opacity="{opacity}" stroke-linecap="{cap}" stroke-linejoin="round"{ds}/>'


def polyline(points: list[tuple[float, float]], **kw) -> str:
    d = "M" + " L".join(f"{x:.2f},{y:.2f}" for x, y in points)
    return path(d, **kw)


def rect(x: float, y: float, w: float, h: float, *, rx: float = 0, fill: str = "none", stroke: str = "none", sw: float = 0, opacity: float = 1, dash: str = "") -> str:
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" opacity="{opacity}"{d}/>'


def text(x: float, y: float, s: str, *, size: float = 14, fill: str = P.INK, anchor: str = "start", mono: bool = False, weight: str = "normal", opacity: float = 1) -> str:
    fam = FONT_MONO if mono else FONT_SANS
    return f'<text x="{x:.2f}" y="{y:.2f}" font-family="{fam}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}" opacity="{opacity}">{s}</text>'


def radial(id_: str, stops: list[tuple[float, str, float]]) -> str:
    s = "".join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o, c, a in stops)
    return f'<radialGradient id="{id_}">{s}</radialGradient>'


def wave(x0: float, y0: float, length: float, amp: float, periods: float, steps: int = 80, phase: float = 0) -> list[tuple[float, float]]:
    import math

    return [(x0 + length * i / steps, y0 + amp * math.sin(2 * math.pi * periods * i / steps + phase)) for i in range(steps + 1)]


def coil(x0: float, y0: float, x1: float, y1: float, loops: int = 6, r: float = 5, steps: int = 160) -> list[tuple[float, float]]:
    """Muelle de gluón (diagrama de Feynman) entre dos puntos."""
    import math

    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy)
    ux, uy = dx / length, dy / length
    nx, ny = -uy, ux
    pts = []
    for i in range(steps + 1):
        t = i / steps
        a = 2 * math.pi * loops * t
        along = length * t + r * 0.9 * math.sin(a)
        across = r * (1 - math.cos(a)) * 0.9
        pts.append((x0 + ux * along + nx * across, y0 + uy * along + ny * across))
    return pts


def save(svg: str, out: Path, *, png_zoom: float | None = None, resources_dir: Path | None = None) -> None:
    """Guarda el SVG y, opcionalmente, su render PNG."""
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(svg, encoding="utf-8")
    if png_zoom:
        png = resvg_py.svg_to_bytes(svg_string=svg, zoom=png_zoom, resources_dir=str(resources_dir or out.parent))
        out.with_suffix(".png").write_bytes(bytes(png))
