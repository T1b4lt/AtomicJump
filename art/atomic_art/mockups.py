"""Composiciones de ejemplo: captura de juego simulada y tarjeta de partida."""

import math

from . import characters as C
from . import enemies as E
from . import items as I
from . import palette as P
from . import world as W
from .svg import circle, g, path, polyline, rect, text

WIDTH, HEIGHT = 1280, 720


def _hud(layer: str) -> str:
    acc = P.LAYER[layer]["accent"]
    out = ""
    # Coherencia
    out += rect(28, 26, 260, 16, rx=8, fill=P.VOID_2, stroke=P.PLAYER, sw=1.2, opacity=0.95)
    out += g(rect(31, 29, 190, 10, rx=5, fill=P.PLAYER), glow=2)
    out += text(30, 62, "COHERENCIA  78 / 100", size=12, fill=P.PLAYER, mono=True)
    out += "".join(g(circle(222 + i * 16, 57, 5, fill=P.PLAYER if i == 0 else "none", stroke=P.PLAYER, sw=1.5), glow=1) for i in range(2))
    # Centro: capa y altura
    out += text(WIDTH / 2, 38, f"CAPA {layer} · 7/16", size=15, fill=acc, anchor="middle", mono=True, weight="bold")
    out += text(WIDTH / 2, 58, "142.6 pm", size=12, fill=P.INK_DIM, anchor="middle", mono=True)
    # Divisas
    for i, (ico, val, col) in enumerate(((I.photon(1), "37", P.PHOTON), (I.positron(), "1", P.POSITRON), (I.quark(), "4", P.INK))):
        x = WIDTH - 200 + i * 66
        out += g(ico, x=x, y=38, scale=0.9) + text(x + 16, 43, val, size=14, fill=col, mono=True, weight="bold")
    # Operador
    out += g(I.icon("item", "cat", "epic"), x=62, y=HEIGHT - 64, scale=0.85)
    out += g(path(f"M{62 - 30},{HEIGHT - 20} L{62 + 10},{HEIGHT - 20}", stroke=P.PLAYER, sw=3), glow=1) + path(f"M{62 + 10},{HEIGHT - 20} L{62 + 30},{HEIGHT - 20}", stroke=P.INK_DIM, sw=3, opacity=0.4)
    # Interacciones por ranura
    for i, (k, gl, r) in enumerate((("strong", "fission", "rare"), ("electromagnetic", "photon_vertex", "rare"), ("gravity", "singularity", "epic"))):
        out += g(I.icon(k, gl, r), x=WIDTH - 180 + i * 58, y=HEIGHT - 58, scale=0.72)
    return out


def gameplay(layer: str = "K", bg_href: str = "bg_K.png", deco_href: str = "decoherence.png", with_hud: bool = True) -> str:
    acc = P.LAYER[layer]["accent"]
    out = f'<image href="{bg_href}" x="0" y="0" width="{WIDTH}" height="{HEIGHT}"/>'
    out += g(W.bubble_chamber(WIDTH, HEIGHT, seed=11), opacity=0.13)

    # Paredes laterales con salida doble arriba (bifurcación)
    out += g(W.wall(3, 23), x=0, y=0) + g(W.wall(3, 23), x=WIDTH - 96, y=0)
    # Techo con dos salidas (bifurcación): 96-448 | hueco | 544-736 | hueco | 832-1184
    out += g(W.wall(11, 2), x=96, y=0) + g(W.wall(6, 2), x=544, y=0) + g(W.wall(11, 2), x=832, y=0)
    # Recompensas de las ramas, flotando en cada salida
    for x, (k, gl, r), lbl in ((496, ("strong", "fission", "rare"), "FISIÓN"), (784, ("item", "mass", "common"), "OBSERVABLE")):
        out += g(rect(x - 44, -8, 88, 16, fill="#000", opacity=0) + path(f"M{x - 44},64 L{x + 44},64", stroke=acc, sw=2, dash="6 6"), glow=2)
        out += g(I.icon(k, gl, r), x=x, y=28, scale=0.62) + text(x, 90, lbl, size=10, fill=acc, anchor="middle", mono=True)

    # Plataformas
    plats = [(3, 160, 560, 5, "n=1"), (1, 520, 500, 4, ""), (0, 820, 430, 5, "n=2"), (3, 330, 360, 4, ""), (1, 640, 290, 3, ""), (0, 900, 230, 5, "n=3"), (0, 180, 210, 5, "")]
    for kind, x, y, wt, lvl in plats:
        out += g(W.platform(wt, acc, lvl) if kind != 1 else W.one_way_platform(wt, acc), x=x, y=y)
    out += g(W.potential_spikes(2), x=880, y=414)

    # Recogibles
    for i in range(5):
        out += g(I.photon(1), x=560 + i * 26, y=470 - 12 * math.sin(i / 4 * math.pi), scale=0.8)
    out += g(I.photon(5), x=990, y=200)
    out += g(I.positron(), x=560, y=250)
    out += g(I.quantum_well(5), x=290, y=196, scale=0.8)
    out += g(I.heal(), x=720, y=265)

    # Enemigos
    out += g(E.orbital_electron("m1"), x=760, y=170)
    out += g(E.alpha_particle("m2"), x=1010, y=402)
    out += g(E.free_neutron("m3"), x=250, y=532)
    out += g(E.muon_enemy("m4"), x=660, y=150, scale=0.9)

    # Wilas saltando y disparando
    out += g(polyline([(250 + t * 4, 540 - 170 * math.sin(t / 60 * math.pi) + 0) for t in range(0, 40)], stroke=P.PLAYER, sw=1, dash="2 5", opacity=0.5))
    out += g(C.wilas("jump", sx=0.92, sy=1.1, uid="hero"), x=420, y=410, scale=1.1)
    out += g(W.projectile(), x=520, y=405) + g(W.projectile(), x=600, y=405, opacity=0.8)
    out += g(W.projectile(), x=420, y=320, rotate=-90)

    # Decoherencia
    out += f'<image href="{deco_href}" x="0" y="{HEIGHT - 120}" width="{WIDTH}" height="220" opacity="0.7"/>'
    if with_hud:
        out += _hud(layer)
    return out


def run_card(bg_href: str = "bg_N.png") -> str:
    """Tarjeta de partida: la pantalla pensada para la captura."""
    out = f'<image href="{bg_href}" x="0" y="0" width="{WIDTH}" height="{HEIGHT}" opacity="0.55"/>'
    out += rect(160, 70, 960, 580, rx=22, fill=P.VOID, stroke=P.INK_DIM, sw=1.2, opacity=0.92)
    out += text(WIDTH / 2, 130, "DECOHERENCIA EN LA CAPA M · TRAMO 9", size=16, fill=P.INK_DIM, anchor="middle", mono=True)
    out += g(text(WIDTH / 2, 205, "K7QX-2MPA", size=64, fill=P.INK, anchor="middle", mono=True, weight="bold"), glow=3)
    out += text(WIDTH / 2, 236, "semilla · g1   [ copiar ]", size=13, fill=P.INK_DIM, anchor="middle", mono=True)
    out += g(C.wilas("happy", uid="card"), x=270, y=330, scale=1.6)
    stats = [("PUNTUACIÓN", "48 210"), ("ALTURA", "812.4 pm"), ("TIEMPO", "18:42"), ("ENTROPÍA", "4"), ("ENEMIGOS", "173"), ("JEFES", "2")]
    for i, (k, v) in enumerate(stats):
        x, y = 390 + (i % 3) * 240, 305 + (i // 3) * 70
        out += text(x, y, k, size=11, fill=P.INK_DIM, mono=True) + text(x, y + 30, v, size=26, fill=P.INK, mono=True, weight="bold")
    out += text(210, 470, "BUILD", size=11, fill=P.INK_DIM, mono=True)
    build = [("strong", "fission", "rare"), ("electromagnetic", "chain", "common"), ("gravity", "singularity", "epic"), ("quantum", "superposition", "legendary"), ("item", "mass", "common"), ("item", "spin_up", "rare"), ("item", "cat", "epic")]
    for i, b in enumerate(build):
        out += g(I.icon(*b), x=240 + i * 72, y=520, scale=0.85)
    out += text(830, 470, "RECOMPENSAS", size=11, fill=P.INK_DIM, mono=True)
    out += g(I.quark(), x=850, y=515) + text(872, 522, "+ 46", size=20, fill=P.INK, mono=True, weight="bold")
    out += g(I.higgs(), x=990, y=515, scale=0.8) + text(1010, 522, "+ 1", size=20, fill=P.HIGGS, mono=True, weight="bold")
    out += text(WIDTH / 2, 620, "Causa: Partículas virtuales (explosión)", size=12, fill=P.POSITIVE, anchor="middle", mono=True)
    return out


def wilas_sheet() -> str:
    """Hoja de modelo de Wilas: expresiones y deformación elástica."""
    out = ""
    for i, e in enumerate(("neutral", "happy", "jump", "focus", "hurt")):
        out += g(C.wilas(e, uid=f"e{i}"), x=70 + i * 110, y=70, scale=1.5)
    for i, (sx, sy, lbl) in enumerate(((1.25, 0.78, "aterrizaje"), (1, 1, "reposo"), (0.85, 1.2, "despegue"), (0.9, 1.12, "subida"), (1.05, 0.95, "caída"))):
        out += g(C.wilas("neutral" if i != 2 else "jump", sx=sx, sy=sy, uid=f"s{i}"), x=70 + i * 110, y=210, scale=1.5)
        out += text(70 + i * 110, 275, lbl, size=11, fill=P.INK_DIM, anchor="middle", mono=True)
    return out
