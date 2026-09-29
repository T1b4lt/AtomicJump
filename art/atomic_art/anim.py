"""Animaciones de ejemplo: cada escena es una función `t -> SVG` con t en [0, 1) que hace bucle.

Los tiempos y curvas de easing de aquí son la referencia para implementarlas en Godot
(tweens, AnimationPlayer o shaders): el generador no produce las animaciones del juego,
solo las previsualiza.
"""

import math
from collections.abc import Callable
from io import BytesIO
from pathlib import Path

import numpy as np
import resvg_py
from PIL import Image

from . import characters as C
from . import enemies as E
from . import items as I
from . import palette as P
from . import world as W
from .svg import circle, coil, doc, ellipse, g, path, polyline, rect, text

TAU = 2 * math.pi


# --- Curvas -----------------------------------------------------------------


def seg(t: float, a: float, b: float) -> float:
    """Progreso 0–1 de t dentro del tramo [a, b]."""
    return min(1.0, max(0.0, (t - a) / (b - a)))


def ease_out(x: float) -> float:
    return 1 - (1 - x) ** 3


def ease_in(x: float) -> float:
    return x**3


def ease_io(x: float) -> float:
    return x * x * (3 - 2 * x)


def lerp(a: float, b: float, x: float) -> float:
    return a + (b - a) * x


def bump(x: float) -> float:
    """0 → 1 → 0."""
    return math.sin(math.pi * min(1.0, max(0.0, x)))


# --- Render -----------------------------------------------------------------


def render_frames(scene: Callable[[float], str], w: int, h: int, frames: int, zoom: float, resources_dir: Path, background: str | None = P.VOID) -> list[Image.Image]:
    out = []
    for i in range(frames):
        svg = doc(w, h, scene(i / frames), background=background)
        png = resvg_py.svg_to_bytes(svg_string=svg, zoom=zoom, resources_dir=str(resources_dir))
        out.append(Image.open(BytesIO(bytes(png))).convert("RGBA"))
    return out


def save_webp(frames: list[Image.Image], out: Path, fps: int) -> None:
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=round(1000 / fps), loop=0, quality=82, method=4)


# --- Wilas ------------------------------------------------------------------


def wilas_idle(t: float) -> str:
    """Reposo: flota, respira, el electrón orbita y parpadea."""
    bob = 3 * math.sin(TAU * t)
    breathe = 0.025 * math.sin(TAU * t)
    expr = "blink" if 0.70 < t < 0.75 else "neutral"
    return g(C.wilas(expr, sx=1 + breathe, sy=1 - breathe, electron_phase=(720 * t) % 360), x=80, y=72 + bob, scale=1.6)


GROUND = 262
JR = 20 * 1.4  # radio de Wilas en pantalla en la escena de salto


def _jump_state(t: float) -> tuple[float, float, float, str]:
    """Altura, escala x, escala y y expresión en la escena de salto con doble salto."""
    if t < 0.06:  # anticipación
        e = ease_out(seg(t, 0, 0.06))
        return 0, 1 + 0.25 * e, 1 - 0.22 * e, "neutral"
    if t < 0.36:  # primer salto
        u = seg(t, 0.06, 0.36)
        return 90 * ease_out(u), lerp(0.84, 1, u), lerp(1.22, 1, u), "jump"
    if t < 0.58:  # salto cuántico (doble salto)
        u = seg(t, 0.36, 0.58)
        return 90 + 70 * ease_out(u), lerp(0.88, 1, u), lerp(1.15, 1, u), "jump"
    if t < 0.84:  # caída
        u = seg(t, 0.58, 0.84)
        return 160 * (1 - ease_in(u)), 0.95, 1.08, "neutral"
    if t < 0.92:  # aterrizaje
        e = bump(seg(t, 0.84, 0.92))
        return 0, 1 + 0.28 * e, 1 - 0.25 * e, "happy" if e > 0.3 else "neutral"
    return 0, 1, 1, "neutral"


def wilas_jump(t: float) -> str:
    out = g(W.platform(5, P.LAYER["K"]["accent"]), x=40, y=GROUND)
    # Estela: posiciones anteriores
    for k, op in ((3, 0.05), (2, 0.08), (1, 0.12)):
        h, _, _, _ = _jump_state((t - k * 0.018) % 1)
        out += circle(120, GROUND - JR - h, JR * 0.8, fill=P.PLAYER, opacity=op)
    h, sx, sy, expr = _jump_state(t)
    # Polvo de despegue y aterrizaje
    for start in (0.04, 0.84):
        u = seg(t, start, start + 0.14)
        if 0 < u < 1:
            for d in (-1, 1):
                for k in range(3):
                    out += circle(120 + d * (18 + 40 * ease_out(u) * (1 + k * 0.4)), GROUND - 4 - 8 * k * u, 3 - k * 0.6, fill=P.INK, opacity=0.6 * (1 - u))
    # Pulso del salto cuántico
    u = seg(t, 0.36, 0.52)
    if 0 < u < 1:
        y = GROUND - JR - 90 + JR
        out += g(ellipse(120, y, 12 + 40 * ease_out(u), 4 + 10 * ease_out(u), stroke=P.PLAYER, sw=2.5 * (1 - u)), glow=3, opacity=1 - u)
    cy = GROUND - JR * sy - h
    out += g(C.wilas(expr, sx=sx, sy=sy, electron_phase=(720 * t) % 360), x=120, y=cy, scale=1.4)
    labels = ((0.0, 0.06, "anticipación"), (0.06, 0.36, "salto"), (0.36, 0.58, "salto cuántico"), (0.58, 0.84, "caída"), (0.84, 0.92, "aterrizaje"), (0.92, 1.0, "reposo"))
    lbl = next(s for a, b, s in labels if a <= t < b)
    return out + text(120, 294, lbl, size=11, fill=P.INK_DIM, anchor="middle", mono=True)


def wilas_hurt(t: float) -> str:
    """Daño: destello blanco, retroceso, parpadeo de invulnerabilidad (1 s)."""
    hit = 0.1
    u = seg(t, hit, hit + 0.12)
    flash = (1 - u) if t >= hit else 0
    kx = -18 * bump(seg(t, hit, hit + 0.25))
    blink_on = not (hit + 0.12 < t < 0.75 and int(t * 30) % 2 == 0)
    expr = "hurt" if hit <= t < hit + 0.3 else "neutral"
    out = ""
    if hit <= t < hit + 0.2:  # proyectil enemigo que impacta
        r = seg(t, hit, hit + 0.2)
        out += g(circle(100, 72, 8 + 26 * r, stroke=P.POSITIVE, sw=3 * (1 - r)), glow=2, opacity=1 - r)
    elif t < hit:
        out += g(circle(200 - 90 * seg(t, 0, hit), 72, 5, fill=P.POSITIVE), glow=3)
    wil = g(C.wilas(expr, flash=flash, electron_phase=(720 * t) % 360), x=90 + kx, y=72, scale=1.6)
    return out + (wil if blink_on else g(wil, opacity=0.25))


# --- Enemigos ---------------------------------------------------------------


def orbital_electron(t: float) -> str:
    cx, cy, r = 110, 85, 55
    th = TAU * t
    out = circle(cx, cy, r, stroke=P.NEGATIVE, sw=1, dash="2 5", opacity=0.4) + circle(cx, cy, 2.5, fill=P.NEGATIVE, opacity=0.6)
    for k in range(14):  # estela que se desvanece
        a0, a1 = th - (k + 1) * 0.09, th - k * 0.09
        out += g(path(f"M{cx + r * math.cos(a0):.1f},{cy + r * math.sin(a0):.1f} A{r},{r} 0 0 1 {cx + r * math.cos(a1):.1f},{cy + r * math.sin(a1):.1f}", stroke=P.NEGATIVE, sw=4 - k * 0.2, opacity=0.5 * (1 - k / 14)), glow=2)
    x, y = cx + r * math.cos(th), cy + r * math.sin(th)
    return out + g(E._sphere(11, P.NEGATIVE, "oe") + E._slit(9, 1), x=x, y=y, glow=2)


def _muon_body() -> str:
    return path("M0,16 L-11,-8 Q0,-18 11,-8 Z", fill=P.NEGATIVE) + E._slit(9, -3)


def muon_fall(t: float) -> str:
    x, ground = 80, 232
    out = path(f"M20,{ground} L140,{ground}", stroke=P.LAYER["L"]["accent"], sw=2.5)
    if t < 0.36:  # aviso
        on = 0.25 + 0.6 * (math.sin(TAU * t * 9) > 0)
        out += g(path(f"M{x},0 L{x},{ground}", stroke=P.NEGATIVE, sw=1.5, dash="4 6", opacity=on), glow=2)
        out += g(ellipse(x, ground, 14, 4, stroke=P.NEGATIVE, sw=2, opacity=on), glow=2)
        return out
    if t < 0.5:  # caída en picado
        u = ease_in(seg(t, 0.36, 0.5))
        y = lerp(-30, ground - 16, u)
        out += g(path(f"M{x},{max(-40, y - 160)} L{x},{y - 10}", stroke=P.NEGATIVE, sw=2, opacity=0.8), glow=3)
        return out + g(_muon_body(), x=x, y=y, glow=2)
    u = seg(t, 0.5, 0.64)
    y = ground - 16 - 34 * bump(u)
    r = seg(t, 0.5, 0.68)
    if r < 1:
        out += g(ellipse(x, ground, 10 + 40 * ease_out(r), 3 + 8 * ease_out(r), stroke=P.NEGATIVE, sw=2.5 * (1 - r)), glow=3, opacity=1 - r)
    fade = 1 - seg(t, 0.82, 0.97)
    return out + g(_muon_body(), x=x, y=y, glow=2, opacity=fade)


def kaon(t: float) -> str:
    m = 0.5 + 0.5 * math.cos(TAU * t)  # 1 = sólido, 0 = intangible
    s = 1 + 0.05 * math.sin(2 * TAU * t)
    body = circle(0, 0, 16, fill=P.NEUTRAL, opacity=0.12 + 0.85 * m) + circle(0, 0, 16, stroke=P.NEUTRAL, sw=2, dash="3 3", opacity=1 - m)
    osc = polyline([(xx, -30 + 4 * math.sin(xx / 3 + TAU * t * 2)) for xx in range(-18, 19)], stroke=P.NEUTRAL, sw=1.2, opacity=0.7)
    lbl = "vulnerable" if m > 0.5 else "intangible"
    return g(g(body, glow=2, scale=s) + osc + E._slit(12, 0), x=70, y=72, scale=1.5) + text(70, 134, lbl, size=11, fill=P.INK_DIM, anchor="middle", mono=True)


def quark_triplet(t: float) -> str:
    base = [(0, -24), (-22, 15), (22, 15)]
    pts = []
    for k, (x, y) in enumerate(base):
        ph = TAU * t + k * 2.1
        dx, dy = 4 * math.sin(ph), 4 * math.cos(ph * 1.3)
        if k == 0:  # uno tira hacia fuera: el muelle se estira
            dy -= 16 * bump(seg(t, 0.2, 0.7))
        pts.append((x + dx, y + dy))
    springs = "".join(polyline(coil(*pts[i], *pts[(i + 1) % 3], loops=5, r=3.5), stroke=P.FAMILY["strong"], sw=1.4, opacity=0.9) for i in range(3))
    quarks = "".join(g(E._sphere(8, c, f"q{i}") + E._slit(6, 0), x=x, y=y) for i, ((x, y), c) in enumerate(zip(pts, P.QUARK_COLORS)))
    return g(g(springs, glow=1) + g(quarks, glow=2), x=110, y=100, scale=1.6)


def pauli_pair(t: float) -> str:
    th = TAU * t
    out = path("M260,10 L260,270", stroke=P.INK_DIM, sw=1, dash="2 6", opacity=0.6)
    out += ellipse(260, 140, 190, 64, stroke=P.NEGATIVE, sw=1, dash="3 6", opacity=0.35)
    shielded = 1 if t < 0.5 else 0
    swap = max(bump(seg(t, 0.46, 0.56)), bump(seg(t, 0.96, 1.0)) if t > 0.96 else 0)
    for k, side in enumerate((-1, 1)):
        x = 260 + side * (120 + 60 * math.cos(th))
        y = 140 + 60 * math.sin(th)
        up = side < 0
        ay = 1 if up else -1
        arrow = path(f"M0,{24 * ay} L0,{-24 * ay} M-8,{-14 * ay} L0,{-24 * ay} L8,{-14 * ay}", stroke=P.VOID, sw=4)
        crown = "".join(path(f"M{math.cos(a) * 38:.1f},{math.sin(a) * 38:.1f} L{math.cos(a) * 48:.1f},{math.sin(a) * 48:.1f}", stroke=P.NEGATIVE, sw=3) for a in [i * math.pi / 6 + th * side for i in range(12)])
        shield = ""
        if k == shielded:
            shield = g(g(circle(0, 0, 50, stroke=P.INK, sw=2.5, dash="10 5"), rotate=math.degrees(th) * 2), glow=3)
        flash = g(circle(0, 0, 40 + 30 * swap, stroke=P.INK, sw=3), glow=4, opacity=swap) if swap > 0.01 else ""
        out += g(g(crown, glow=2) + g(E._sphere(34, P.NEGATIVE, f"pp{k}"), glow=3) + arrow + shield + flash, x=x, y=y, scale=0.9)
    return out + text(260, 272, "el escudo cambia de gemelo: nunca en el mismo estado", size=11, fill=P.INK_DIM, anchor="middle", mono=True)


# --- Objetos ----------------------------------------------------------------


def photon_collect(t: float) -> str:
    wx, wy = 60, 62
    out = ""
    arrived = 0
    for k, x0 in enumerate((180, 220, 260)):
        bob = 5 * math.sin(TAU * t * 2 + k)
        u = seg(t, 0.3 + k * 0.05, 0.5 + k * 0.05)
        if u >= 1:
            arrived += 1
            appear = seg(t, 0.85, 1.0)
            if appear > 0:
                out += g(I.photon(1, phase=TAU * t * 3), x=x0, y=wy + bob, opacity=appear)
            continue
        e = ease_in(u)
        x, y = lerp(x0, wx, e), lerp(wy + bob, wy, e)
        out += g(I.photon(1, phase=TAU * t * 3 + k), x=x, y=y, scale=1 - 0.5 * e)
    if t > 0.5:
        r = seg(t, 0.5, 0.75)
        out += g(circle(wx, wy, 26 + 20 * r, stroke=P.PHOTON, sw=2.5 * (1 - r)), glow=2, opacity=1 - r)
        tu = seg(t, 0.55, 0.9)
        out += text(wx, wy - 40 - 20 * tu, "+3 γ", size=14, fill=P.PHOTON, anchor="middle", mono=True, weight="bold", opacity=1 - tu)
    return g(C.wilas("happy" if 0.5 < t < 0.8 else "neutral", electron_phase=(720 * t) % 360), x=wx, y=wy, scale=1.3) + out


def well_open(t: float) -> str:
    cx, cy = 90, 140
    out = ""
    for k in range(3):  # pago: tres fotones caen dentro
        u = seg(t, 0.08 + k * 0.07, 0.25 + k * 0.07)
        if 0 < u < 1:
            out += g(I.photon(1, phase=TAU * t * 4), x=cx + (k - 1) * 18 * (1 - u), y=lerp(10, cy + 10, ease_in(u)), scale=0.7)
    lit = 3 * seg(t, 0.2, 0.42)
    jump = seg(t, 0.42, 0.6)
    item_y = lerp(8, -70, ease_out(jump)) + (4 * math.sin(TAU * t * 3) if t > 0.6 else 0)
    fade = 1 - seg(t, 0.88, 1.0)
    burst = ""
    r = seg(t, 0.42, 0.62)
    if 0 < r < 1:
        burst = g(circle(0, 8, 8 + 30 * r, stroke=P.RARITY["common"], sw=2.5 * (1 - r)), glow=3, opacity=1 - r)
    well = I.quantum_well(5, lit=lit, item_y=item_y, price_opacity=1 - seg(t, 0.2, 0.3))
    return out + g(g(well + burst, opacity=fade if t > 0.88 else 1), x=cx, y=cy, scale=1.4)


def annihilation(t: float) -> str:
    cx, cy = 180, 92
    out = ""
    boom = 0.42
    item_glow = 1 + 0.4 * seg(t, boom, boom + 0.1)
    item = g(path("M0,-10 L9,0 L0,10 L-9,0 Z", fill=P.RARITY["rare"]), glow=3, scale=item_glow)
    if t < boom:
        th = TAU * t * 1.5
        orbit = g(ellipse(0, 0, 26, 12, stroke=P.NEGATIVE, sw=1.8, rotate=-20 + 30 * math.sin(th)) + ellipse(0, 0, 26, 12, stroke=P.NEGATIVE, sw=1.8, rotate=40 + 30 * math.sin(th), opacity=0.6), glow=2)
        a = math.radians(-20 + 30 * math.sin(th))
        ex, ey = 26 * math.cos(th * 2), 12 * math.sin(th * 2)
        ex, ey = ex * math.cos(a) - ey * math.sin(a), ex * math.sin(a) + ey * math.cos(a)
        out += g(orbit + item + g(circle(ex, ey, 4.5, fill=P.NEGATIVE), glow=3), x=cx, y=cy, scale=1.4)
        u = ease_in(seg(t, 0.05, boom))
        out += g(I.positron(), x=lerp(20, cx - 10, u), y=cy, scale=1.2)
    else:
        fade = 1 - seg(t, 0.9, 1.0)
        f = seg(t, boom, boom + 0.18)
        out += g(circle(cx, cy, 10 + 70 * ease_out(f), fill="#FFFFFF", opacity=0.9 * (1 - f)), glow=6)
        gu = seg(t, boom, boom + 0.4)
        if gu < 1:  # dos fotones gamma en direcciones opuestas
            for d in (-1, 1):
                x0, y0 = cx + d * 110 * ease_out(gu), cy - d * 40 * ease_out(gu)
                pts = [(x0 - d * i * 0.9, y0 + d * i * 0.33 + 3 * math.sin(i / 2.5)) for i in range(40)]
                out += g(polyline(pts, stroke=P.PHOTON, sw=2), glow=3, opacity=1 - gu)
        out += g(item, x=cx, y=cy - 10 * ease_out(seg(t, boom, boom + 0.2)) + 3 * math.sin(TAU * t * 3), scale=1.4, opacity=fade)
        out += text(cx, cy + 58, "e⁺ + e⁻ → γ γ", size=12, fill=P.PHOTON, anchor="middle", mono=True, opacity=bump(seg(t, boom + 0.05, 0.9)))
    return out


# --- VFX y mundo ------------------------------------------------------------


def shot_impact(t: float) -> str:
    wy, ex = 70, 320
    out = ""
    recoil = 0.0
    hit_flash = 0.0
    knock = 0.0
    for t0 in (0.0, 0.33, 0.66):
        dt = (t - t0) % 1
        if dt < 0.14:  # vuelo del proyectil
            x = lerp(90, ex - 20, dt / 0.14)
            out += g(W.projectile(), x=x, y=wy)
        if dt < 0.05:
            recoil = max(recoil, 1 - dt / 0.05)
        hu = (dt - 0.14) / 0.22
        if 0 <= hu < 1:  # impacto: trazas en espiral de cámara de burbujas
            hit_flash = max(hit_flash, 1 - hu * 3)
            knock = max(knock, bump(hu * 2))
            for d, c in ((1, P.PLAYER), (-1, P.NEUTRAL)):
                pts = W.spiral_track(ex - 20 + d * 12, wy + d * 14, 16, 1.6 * ease_out(hu) + 0.05, d, decay=0.25, a0=math.pi * (0.5 if d > 0 else 1.5))
                out += g(polyline(pts, stroke=c, sw=1.4), glow=2, opacity=1 - hu)
            out += circle(ex - 20, wy, 3 + 10 * hu, stroke=P.INK, sw=1.5, opacity=1 - hu)
    enemy = E.free_neutron("si") + (circle(0, 0, 17, fill="#FFFFFF", opacity=max(0.0, hit_flash)) if hit_flash > 0 else "")
    out += g(enemy, x=ex + 6 * knock, y=wy, scale=1.3)
    return g(C.wilas("focus", electron_phase=(720 * t) % 360), x=50 - 3 * recoil, y=wy, scale=1.3) + out


def fork_collapse(t: float) -> str:
    acc = P.LAYER["K"]["accent"]
    out = g(W.wall(4, 2), x=0, y=0) + g(W.wall(1, 2), x=192, y=0) + g(W.wall(4, 2), x=288, y=0)
    gaps = [(128, 192), (224, 288)]  # huecos (x0, x1): las dos salidas
    # Wilas sube hacia la salida izquierda
    u = ease_io(seg(t, 0.0, 0.45))
    wx = lerp(200, 160, u)
    wy = lerp(210, 40, u)
    collapse = ease_out(seg(t, 0.45, 0.7))
    for k, ((x0, x1), (fam, gl, rar), lbl) in enumerate(zip(gaps, (("strong", "fission", "rare"), ("item", "mass", "common")), ("FISIÓN", "OBSERVABLE"))):
        mid = (x0 + x1) / 2
        if k == 1:
            if collapse > 0:  # la rama no elegida colapsa: la pared se cierra
                wv = (x1 - x0) / 2 * collapse
                out += rect(x0, 0, wv, 64, fill=P.VOID_2, stroke=P.INK_DIM, sw=1) + rect(x1 - wv, 0, wv, 64, fill=P.VOID_2, stroke=P.INK_DIM, sw=1)
                for j in range(8):  # fragmentos que se disuelven
                    a = j * TAU / 8
                    out += rect(mid + math.cos(a) * 30 * collapse - 2, 100 + math.sin(a) * 20 * collapse - 2, 4, 4, fill=P.INK_DIM, opacity=1 - collapse)
            out += g(I.icon(fam, gl, rar), x=mid, y=100, scale=0.5 * (1 - collapse) + 0.001, opacity=1 - collapse)
            out += g(rect(x0, -8, x1 - x0, 16, fill="#000", opacity=0) + path(f"M{x0},64 L{x1},64", stroke=acc, sw=2, dash="6 6"), glow=2, opacity=1 - collapse)
        else:
            chosen = seg(t, 0.4, 0.5)
            out += g(I.icon(fam, gl, rar), x=mid, y=100 - 60 * ease_in(seg(t, 0.35, 0.45)), scale=0.5, opacity=1 - seg(t, 0.4, 0.45))
            out += g(rect(x0, -8, x1 - x0, 16, fill="#000", opacity=0) + path(f"M{x0},64 L{x1},64", stroke=acc if chosen < 1 else P.PLAYER, sw=2 + 2 * bump(chosen), dash="6 6"), glow=3)
        out += text(mid, 130, lbl, size=9, fill=acc, anchor="middle", mono=True, opacity=1 - (collapse if k == 1 else seg(t, 0.4, 0.45)))
    out += g(W.platform(3, acc), x=150, y=238)
    wil = g(C.wilas("jump" if 0.02 < t < 0.45 else "happy", sx=0.9 if t < 0.45 else 1, sy=1.12 if t < 0.45 else 1, electron_phase=(720 * t) % 360), x=wx, y=wy, scale=1.0)
    out += g(wil, opacity=1 - seg(t, 0.43, 0.5))
    fade = seg(t, 0.9, 1.0)
    return out + (rect(0, 0, 400, 260, fill=P.VOID, opacity=fade) if fade else "")


def decoherence_frames(bg: Path, frames: int, w: int = 480, h: int = 270, zoom: float = 1.0) -> list[Image.Image]:
    """La Decoherencia sube, se traga una plataforma y el bucle reinicia."""
    acc = P.LAYER["K"]["accent"]
    base_svg = doc(w, h, f'<image href="{bg.name}" x="0" y="0" width="{w}" height="{h}"/>' + g(W.platform(4, acc), x=60, y=200) + g(W.platform(3, acc), x=290, y=140) + g(W.platform(3, acc), x=120, y=80), background=P.VOID)
    base = Image.open(BytesIO(bytes(resvg_py.svg_to_bytes(svg_string=base_svg, zoom=zoom, resources_dir=str(bg.parent))))).convert("RGBA")
    W_, H_ = base.size
    out = []
    for i in range(frames):
        t = i / frames
        strip = W.decoherence_strip(W_, int(220 * zoom), seed=100 + i, phase=t)
        y = int(lerp(H_ - 40 * zoom, H_ - 190 * zoom, ease_io(seg(t, 0.0, 0.8))))
        frame = base.copy()
        layer = Image.new("RGBA", frame.size)
        layer.alpha_composite(strip, (0, max(0, y)) if y >= 0 else (0, 0))
        if t > 0.8:
            a = np.asarray(layer).copy()
            a[..., 3] = (a[..., 3] * (1 - seg(t, 0.8, 1.0))).astype(np.uint8)
            layer = Image.fromarray(a)
        frame.alpha_composite(layer)
        out.append(frame)
    return out


def orbital_shimmer_frames(layer: str, frames: int, w: int = 480, h: int = 270, seed: int = 5) -> list[Image.Image]:
    """El fondo vive: la nube respira y las 'mediciones' parpadean."""
    info = P.LAYER[layer]
    kind = info["orbital"]
    ext = W._EXTENT[kind]
    xs = np.linspace(-ext * w / h, ext * w / h, w)
    ys = np.linspace(ext, -ext, h)
    X, Y = np.meshgrid(xs, ys)
    d = W._orbital_density(kind, X, Y)
    d /= d.max()
    cloud = np.power(d, 0.45)
    rng = np.random.default_rng(seed)
    n = int(w * h * 0.012)
    idx = rng.choice(d.size, size=n, p=(d.ravel() / d.sum()))
    birth = rng.random(n)
    tint = np.array(P.hex_to_rgb(info["tint"]), dtype=float) / 255
    accent = np.array(P.hex_to_rgb(info["accent"]), dtype=float) / 255
    void = np.array(P.hex_to_rgb(P.VOID), dtype=float) / 255
    r_px = np.sqrt((np.arange(w)[None, :] - w / 2) ** 2 + (np.arange(h)[:, None] - h / 2) ** 2)
    vign = 1 - 0.55 * np.clip(r_px / (w * 0.62), 0, 1) ** 2
    out = []
    for i in range(frames):
        t = i / frames
        breathe = 1 + 0.12 * math.sin(TAU * t)
        img = void[None, None, :] + cloud[..., None] * tint[None, None, :] * 0.55 * breathe
        bright = np.sin(np.pi * ((t * 2 + birth) % 1)) ** 4
        dots = np.zeros(d.size)
        np.add.at(dots, idx, bright)
        dots = dots.reshape(d.shape)
        img += np.clip(dots, 0, 1.2)[..., None] * accent[None, None, :] * 1.1
        img *= vign[..., None]
        out.append(Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).convert("RGBA").resize((w * 2, h * 2), Image.LANCZOS))
    return out


# --- Escena de juego --------------------------------------------------------


def _parabola(p0: tuple[float, float], p1: tuple[float, float], u: float, height: float) -> tuple[float, float]:
    x = lerp(p0[0], p1[0], u)
    y = lerp(p0[1], p1[1], u) - height * 4 * u * (1 - u)
    return x, y


def _hero_path(t: float) -> tuple[float, float, float, float, str]:
    """Posición, escalas y expresión de Wilas en la escena de juego."""
    A, B, C_ = (110, 272), (330, 192), (500, 112)
    if t < 0.14:  # corre por la plataforma
        u = ease_io(seg(t, 0, 0.14))
        return lerp(A[0], 190, u), A[1] - 2 * abs(math.sin(TAU * t * 5)), 1, 1, "neutral"
    if t < 0.38:  # salta a B
        u = seg(t, 0.14, 0.38)
        x, y = _parabola((190, A[1]), B, u, 70)
        return x, y, 0.9 if u < 0.5 else 0.96, 1.12 if u < 0.5 else 1.06, "jump"
    if t < 0.44:  # aterriza
        e = bump(seg(t, 0.38, 0.44))
        return B[0], B[1] + 20 * 0.22 * e, 1 + 0.25 * e, 1 - 0.22 * e, "neutral"
    if t < 0.58:  # dispara
        return B[0], B[1], 1, 1, "focus"
    if t < 0.86:  # salto con doble salto hasta C
        u = seg(t, 0.58, 0.86)
        if u < 0.5:
            x, y = _parabola(B, (415, 150), u * 2, 55)
        else:
            x, y = _parabola((415, 150), C_, (u - 0.5) * 2, 45)
        return x, y, 0.9, 1.12, "jump"
    e = bump(seg(t, 0.86, 0.92))
    return C_[0], C_[1] + 20 * 0.22 * e, 1 + 0.25 * e, 1 - 0.22 * e, "happy"


def gameplay_scene(t: float) -> str:
    acc = P.LAYER["K"]["accent"]
    out = '<image href="bg_K.png" x="0" y="0" width="640" height="360"/>'
    out += g(W.wall(2, 12), x=0, y=0) + g(W.wall(2, 12), x=576, y=0)
    out += g(W.platform(6, acc, "n=1"), x=70, y=292) + g(W.platform(4, acc), x=270, y=212) + g(W.platform(4, acc, "n=2"), x=440, y=132) + g(W.one_way_platform(3, acc), x=90, y=150)
    # Electrón orbital: muere con el disparo y reaparece
    oc, orad = (480, 230), 34
    th = TAU * t * 1.5
    alive_fade = 1 - seg(t, 0.5, 0.52) + seg(t, 0.9, 1.0)
    ex, ey = oc[0] + orad * math.cos(th), oc[1] + orad * math.sin(th)
    out += circle(*oc, orad, stroke=P.NEGATIVE, sw=1, dash="2 5", opacity=0.35)
    if alive_fade > 0.01:
        out += g(E._sphere(9, P.NEGATIVE, "ge") + E._slit(8, 1), x=ex, y=ey, glow=2, opacity=min(1.0, alive_fade))
    # Disparo en t = 0.46 hacia el electrón
    su = seg(t, 0.46, 0.5)
    hx, hy = oc[0] + orad * math.cos(TAU * 0.5 * 1.5), oc[1] + orad * math.sin(TAU * 0.5 * 1.5)
    if 0 < su < 1:
        out += g(W.projectile(), x=lerp(360, hx, su), y=lerp(192, hy, su), rotate=math.degrees(math.atan2(hy - 192, hx - 360)))
    hu = seg(t, 0.5, 0.75)
    if 0 < hu < 1:
        for d, c in ((1, P.NEGATIVE), (-1, P.PLAYER)):
            pts = W.spiral_track(hx + d * 10, hy + d * 10, 14, 1.8 * ease_out(hu) + 0.05, d, decay=0.25, a0=math.pi * (0.5 if d > 0 else 1.5))
            out += g(polyline(pts, stroke=c, sw=1.3), glow=2, opacity=1 - hu)
        out += text(hx, hy - 20 - 16 * hu, "+1 q", size=11, fill=P.INK, anchor="middle", mono=True, opacity=1 - hu)
    # Fotones en el camino
    x, y, sx, sy, expr = _hero_path(t)
    collected = 0
    for k, (px, py) in enumerate(((240, 225), (268, 205), (296, 190))):
        taken_at = 0.2 + k * 0.035
        if t < taken_at or t > 0.95:
            out += g(I.photon(1, phase=TAU * t * 3 + k), x=px, y=py + 3 * math.sin(TAU * t * 2 + k), scale=0.8, opacity=seg(t, 0.95, 1.0) if t > 0.95 else 1)
        else:
            collected += 1
            r = seg(t, taken_at, taken_at + 0.1)
            if r < 1:
                out += g(circle(px, py, 6 + 16 * r, stroke=P.PHOTON, sw=2 * (1 - r)), glow=2, opacity=1 - r)
    # Pulso del doble salto
    pu = seg(t, 0.72, 0.82)
    if 0 < pu < 1:
        out += g(ellipse(415, 172, 10 + 30 * pu, 3 + 7 * pu, stroke=P.PLAYER, sw=2 * (1 - pu)), glow=3, opacity=1 - pu)
    out += g(C.wilas(expr, sx=sx, sy=sy, electron_phase=(720 * t) % 360), x=x, y=y, scale=1.0)
    # HUD mínimo
    out += rect(20, 16, 140, 10, rx=5, fill=P.VOID_2, stroke=P.PLAYER, sw=1) + g(rect(22, 18, 104, 6, rx=3, fill=P.PLAYER), glow=1)
    out += g(I.photon(1), x=560, y=22, scale=0.7) + text(574, 27, str(12 + collected), size=12, fill=P.PHOTON, mono=True, weight="bold")
    fade = seg(t, 0.93, 1.0)
    return out + (rect(0, 0, 640, 360, fill=P.VOID, opacity=0.6 * bump(fade)) if fade else "")
