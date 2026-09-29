"""Mundo: fondos orbitales por capa, tiles, peligros y VFX.

Los fondos se calculan con funciones de onda (reales) del átomo de hidrógeno:
cada capa muestra la forma de su orbital característico.
"""

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

from . import palette as P
from .svg import circle, g, path, polyline, rect

# --- Fondos orbitales -------------------------------------------------------


def _orbital_density(kind: str, x: np.ndarray, y: np.ndarray) -> np.ndarray:
    """|ψ|² en un corte 2D (unidades de radio de Bohr). Sin normalizar."""
    r = np.sqrt(x**2 + y**2) + 1e-9
    if kind == "1s":
        psi = np.exp(-r)
    elif kind == "2p":  # 2p_z: dos lóbulos verticales
        psi = y * np.exp(-r / 2)
    elif kind == "3d":  # 3d_xz: trébol de cuatro lóbulos
        psi = x * y * np.exp(-r / 3)
    elif kind == "4f":  # 4f_{x(x²-3y²)}: seis lóbulos
        psi = x * (x**2 - 3 * y**2) * np.exp(-r / 4)
    else:
        raise ValueError(kind)
    return psi**2


_EXTENT = {"1s": 3.4, "2p": 11, "3d": 17, "4f": 26}


def orbital_background(layer: str, width: int = 1280, height: int = 720, seed: int = 1) -> Image.Image:
    """Nube de probabilidad del orbital de la capa + muestreo de 'posiciones medidas'."""
    info = P.LAYER[layer]
    kind = info["orbital"]
    ext = _EXTENT[kind]
    aspect = width / height
    xs = np.linspace(-ext * aspect, ext * aspect, width)
    ys = np.linspace(ext, -ext, height)
    X, Y = np.meshgrid(xs, ys)
    d = _orbital_density(kind, X, Y)
    d = d / d.max()
    cloud = np.power(d, 0.45)  # comprime el rango para que se vean las colas

    rng = np.random.default_rng(seed)
    # "Mediciones": puntos muestreados según la densidad (como la ilustración clásica de libro)
    flat = d.ravel() / d.sum()
    idx = rng.choice(flat.size, size=int(width * height * 0.006), p=flat)
    dots = np.zeros(flat.size)
    dots[idx] = rng.uniform(0.35, 1.0, idx.size)
    dots = dots.reshape(d.shape)

    tint = np.array(P.hex_to_rgb(info["tint"]), dtype=float) / 255
    accent = np.array(P.hex_to_rgb(info["accent"]), dtype=float) / 255
    void = np.array(P.hex_to_rgb(P.VOID), dtype=float) / 255

    img = void[None, None, :] + cloud[..., None] * tint[None, None, :] * 0.55
    glow = Image.fromarray((np.clip(dots, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))
    glow = np.asarray(glow, dtype=float) / 255
    img += (dots[..., None] * 0.9 + glow[..., None] * 1.5) * accent[None, None, :] * (0.35 + 0.65 * cloud[..., None])

    # Anillos de "niveles de energía" muy tenues centrados en el núcleo
    r_px = np.sqrt((np.arange(width)[None, :] - width / 2) ** 2 + (np.arange(height)[:, None] - height / 2) ** 2)
    for k in range(1, 6):
        img += (np.abs(r_px - k * 130) < 0.8)[..., None] * accent[None, None, :] * 0.06

    # Viñeta
    vign = 1 - 0.55 * np.clip(r_px / (width * 0.62), 0, 1) ** 2
    img *= vign[..., None]
    return Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))


def decoherence_strip(width: int = 1280, height: int = 220, seed: int = 3, phase: float = 0) -> Image.Image:
    """La Decoherencia: frente de ruido que disuelve píxeles, con alfa.

    `phase` (0–1) desplaza las ondas del frente: sirve para animarla en bucle.
    """
    rng = np.random.default_rng(seed)
    x = np.arange(width) * (1280 / width)
    tau = 2 * np.pi
    front = 70 + 18 * np.sin(x / 57 + tau * phase) + 10 * np.sin(x / 13 + 1.3 - 2 * tau * phase) + 6 * np.sin(x / 5.1 + 3 * tau * phase)
    yy = np.arange(height)[:, None]
    depth = (yy - front[None, :])  # >0 dentro de la onda
    noise = rng.random((height, width))
    blocks = np.kron(rng.random((height // 4 + 1, width // 4 + 1)), np.ones((4, 4)))[:height, :width]
    inside = depth > 0
    dissolve = (depth > -40) & (blocks > np.clip((-depth) / 40, 0, 1)) & ~inside
    alpha = np.where(inside, np.clip(0.35 + depth / 180, 0, 0.95), 0.0)
    alpha = np.where(dissolve, 0.55 * blocks, alpha)
    edge = np.exp(-(depth**2) / 18)
    alpha = np.clip(alpha + edge * 0.9, 0, 1)
    scan = 0.85 + 0.15 * (np.arange(height) % 3 == 0)[:, None]
    base = np.array(P.hex_to_rgb(P.DECOHERENCE), dtype=float) / 255
    rgb = np.ones((height, width, 3)) * base * (0.55 + 0.45 * noise[..., None]) * scan[..., None]
    rgb = np.clip(rgb + edge[..., None] * 0.4, 0, 1)
    rgba = np.dstack([rgb, alpha])
    return Image.fromarray((rgba * 255).astype(np.uint8), "RGBA")


def save_png(img: Image.Image, out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, optimize=True)


# --- Tiles (unidad de rejilla: 32 px) --------------------------------------

TILE = 32


def platform(width_tiles: int = 4, color: str = P.INK, level: str = "") -> str:
    """Plataforma sólida: un 'nivel de energía'. Barra con borde superior luminoso y marcas."""
    w = width_tiles * TILE
    body = rect(0, 0, w, 14, rx=3, fill=P.VOID_3, stroke=color, sw=0.8, opacity=0.95)
    # rect invisible: da alto a la caja del filtro de brillo (una línea horizontal tiene alto 0)
    top = rect(0, -8, w, 16, fill="#000", opacity=0) + path(f"M3,0.5 L{w - 3},0.5", stroke=color, sw=2.5)
    ticks = "".join(path(f"M{x},4 L{x},10", stroke=color, sw=1, opacity=0.35) for x in range(8, w - 4, 8))
    label = f'<text x="{w - 6}" y="-5" font-family="DejaVu Sans Mono" font-size="8" fill="{color}" opacity="0.55" text-anchor="end">{level}</text>' if level else ""
    return body + ticks + g(top, glow=2) + label


def one_way_platform(width_tiles: int = 3, color: str = P.INK) -> str:
    """Plataforma atravesable desde abajo: nivel 'virtual', discontinuo."""
    w = width_tiles * TILE
    return g(rect(0, -8, w, 16, fill="#000", opacity=0) + path(f"M2,1 L{w - 2},1", stroke=color, sw=2.5, dash="10 6"), glow=2) + path(f"M2,7 L{w - 2},7", stroke=color, sw=1, opacity=0.25, dash="2 4")


def wall(width_tiles: int = 2, height_tiles: int = 6, color: str = P.INK_DIM) -> str:
    """Pared: retícula cristalina."""
    w, h = width_tiles * TILE, height_tiles * TILE
    grid = "".join(path(f"M{x},0 L{x},{h}", stroke=P.GRID, sw=1) for x in range(0, w + 1, 16))
    grid += "".join(path(f"M0,{y} L{w},{y}", stroke=P.GRID, sw=1) for y in range(0, h + 1, 16))
    nodes = "".join(circle(x, y, 1.2, fill=color, opacity=0.5) for x in range(0, w + 1, 16) for y in range(0, h + 1, 16))
    return rect(0, 0, w, h, fill=P.VOID_2) + grid + nodes + g(rect(0, 0, w, h, stroke=color, sw=1.5, opacity=0.8), glow=1)


def potential_spikes(width_tiles: int = 2) -> str:
    """Pico de potencial: la gráfica de un potencial con picos delta."""
    w = width_tiles * TILE
    pts = []
    n = width_tiles * 3
    for i in range(n + 1):
        x = i * w / n
        pts.append((x, 16))
        if i < n:
            pts.append((x + w / n / 2, 0))
    base = path(f"M0,16 L{w},16", stroke=P.DANGER, sw=1, opacity=0.5)
    return base + g(polyline(pts, stroke=P.DANGER, sw=2, fill="none"), glow=2) + g(polyline(pts, fill=P.DANGER, opacity=0.15), glow=0) if False else base + g(polyline(pts, stroke=P.DANGER, sw=2), glow=2)


# --- VFX: trazas de cámara de burbujas -------------------------------------


def spiral_track(x0: float, y0: float, r0: float, turns: float, direction: int, decay: float = 0.18, a0: float = 0) -> list[tuple[float, float]]:
    """Partícula cargada perdiendo energía en un campo magnético: espiral que se cierra."""
    pts = []
    steps = int(turns * 90)
    for i in range(steps):
        t = i / 90 * 2 * math.pi
        r = r0 * math.exp(-decay * t)
        a = a0 + direction * t
        pts.append((x0 + r * math.cos(a), y0 + r * math.sin(a)))
    return pts


def bubble_chamber(width: int = 1280, height: int = 400, seed: int = 7) -> str:
    """Lámina decorativa de trazas: la firma visual de todos los VFX."""
    rng = np.random.default_rng(seed)
    out = ""
    colors = [P.NEGATIVE, P.POSITIVE, P.NEUTRAL, P.PLAYER, P.FAMILY["electromagnetic"]]
    # Vértices de desintegración: una línea que entra y se abre en V con espirales
    for _ in range(9):
        vx, vy = rng.uniform(80, width - 80), rng.uniform(60, height - 60)
        c1, c2 = rng.choice(colors, 2, replace=False)
        ang = rng.uniform(0, 2 * math.pi)
        inc = [(vx - math.cos(ang) * 400, vy - math.sin(ang) * 400), (vx, vy)]
        out += polyline(inc, stroke=P.NEUTRAL, sw=0.8, opacity=0.25, dash="1 3")
        for c, d in ((c1, 1), (c2, -1)):
            a = ang + d * rng.uniform(0.3, 0.8)
            r0 = rng.uniform(30, 90)
            cx, cy = vx + math.cos(a + d * math.pi / 2) * r0, vy + math.sin(a + d * math.pi / 2) * r0
            pts = spiral_track(cx, cy, r0, rng.uniform(1.5, 3.5), d, a0=a - d * math.pi / 2)
            out += g(polyline(pts, stroke=str(c), sw=1.3, opacity=0.85), glow=2)
        out += circle(vx, vy, 2.5, fill=P.INK)
    # Burbujas: puntos minúsculos a lo largo de trazas rectas
    for _ in range(14):
        x, y = rng.uniform(0, width), rng.uniform(0, height)
        a = rng.uniform(0, 2 * math.pi)
        for k in range(0, 260, 7):
            out += circle(x + math.cos(a) * k, y + math.sin(a) * k, 0.9, fill=P.INK_DIM, opacity=0.5)
    return out


def projectile(color: str = P.PLAYER, length: float = 46) -> str:
    """Proyectil del jugador: cabeza brillante y estela ondulada (paquete de ondas)."""
    import math as m

    pts = [(-length + i, 2.5 * m.sin(i / 3.2) * (i / length)) for i in range(0, int(length) + 1)]
    return g(polyline(pts, stroke=color, sw=1.6, opacity=0.8), glow=2) + g(circle(0, 0, 4.5, fill="#FFFFFF") + circle(0, 0, 6.5, stroke=color, sw=2), glow=3)
