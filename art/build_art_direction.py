"""Genera las imágenes de la propuesta de dirección de arte.

Uso:  uv run build_art_direction.py
Salida: ../docs/assets/art-direction/img/
"""

import shutil
import tempfile
from pathlib import Path

import sys

from atomic_art import anim as A
from atomic_art import characters as C
from atomic_art import enemies as E
from atomic_art import items as I
from atomic_art import mockups as M
from atomic_art import palette as P
from atomic_art import world as W
from atomic_art.svg import doc, g, save, text

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parent / "docs" / "assets" / "art-direction" / "img"


# Enemigos cuya traza se extiende a un lado: se desplazan para que quepa
X_OFFSET = {("K", 0): 95, ("K", 2): 100}


def render(name: str, width: float, height: float, body: str, zoom: float = 2, background: str | None = None) -> None:
    """Renderiza a PNG (el SVG intermedio se descarta: el script es la fuente)."""
    with tempfile.TemporaryDirectory() as tmp:
        svg_path = Path(tmp) / f"{name}.svg"
        save(doc(width, height, body, background=background), svg_path, png_zoom=zoom, resources_dir=OUT)
        shutil.move(svg_path.with_suffix(".png"), OUT / f"{name}.png")
    print("  ", name)


# (nombre, escena, ancho, alto, fotogramas, fps, zoom)
ANIMATIONS = [
    ("wilas_idle", A.wilas_idle, 160, 140, 48, 24, 2),
    ("wilas_jump", A.wilas_jump, 240, 310, 60, 30, 1.5),
    ("wilas_hurt", A.wilas_hurt, 220, 140, 45, 30, 2),
    ("orbital_electron", A.orbital_electron, 220, 170, 36, 24, 1.5),
    ("muon_fall", A.muon_fall, 160, 260, 48, 24, 1.5),
    ("kaon", A.kaon, 140, 150, 48, 24, 1.5),
    ("quark_triplet", A.quark_triplet, 220, 190, 48, 24, 1.5),
    ("pauli_pair", A.pauli_pair, 520, 285, 60, 30, 1.2),
    ("photon_collect", A.photon_collect, 300, 130, 48, 24, 1.5),
    ("well_open", A.well_open, 180, 210, 60, 30, 1.5),
    ("annihilation", A.annihilation, 320, 180, 60, 30, 1.5),
    ("shot_impact", A.shot_impact, 380, 140, 60, 30, 1.5),
    ("fork_collapse", A.fork_collapse, 400, 260, 60, 30, 1.5),
    ("gameplay", A.gameplay_scene, 640, 360, 90, 30, 1.5),
]


def build_animations() -> None:
    print("Animaciones")
    for name, scene, w, h, frames, fps, zoom in ANIMATIONS:
        A.save_webp(A.render_frames(scene, w, h, frames, zoom, OUT), OUT / f"anim_{name}.webp", fps)
        print("  ", name)
    A.save_webp(A.decoherence_frames(OUT / "bg_K.png", 48), OUT / "anim_decoherence.webp", 20)
    print("   decoherence")
    A.save_webp(A.orbital_shimmer_frames("L", 48), OUT / "anim_orbital_L.webp", 16)
    print("   orbital_L")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    if "--anim" in sys.argv:
        build_animations()
        return
    print("Fondos orbitales y Decoherencia")
    for layer in P.LAYER:
        W.save_png(W.orbital_background(layer), OUT / f"bg_{layer}.png")
    W.save_png(W.decoherence_strip(), OUT / "decoherence.png")

    print("Composiciones")
    render("hero", 1280, 720, M.gameplay(), zoom=1.5, background=P.VOID)
    render("hero_clean", 1280, 720, M.gameplay(with_hud=False), zoom=1, background=P.VOID)
    render("run_card", 1280, 720, M.run_card("bg_M.png"), zoom=1, background=P.VOID)

    print("Protagonista")
    render("wilas_sheet", 560, 290, M.wilas_sheet(), zoom=2)
    render("wilas_hero", 220, 220, g(C.wilas("neutral", uid="big"), x=110, y=110, scale=3.4), zoom=2)
    for key, fn in (("wilas", lambda: C.wilas(uid="c0")), ("muon", C.muon), ("neutrino", C.neutrino), ("tau", C.tau)):
        render(f"char_{key}", 140, 120, g(fn(), x=70, y=60, scale=1.4), zoom=2)

    print("Enemigos")
    for layer, roster in E.ROSTER.items():
        for i, (_, fn, _) in enumerate(roster):
            render(f"enemy_{layer}_{i}", 150, 130, g(fn(uid=f"{layer}{i}"), x=X_OFFSET.get((layer, i), 75), y=65, scale=1.3), zoom=2)
    render("boss_pauli", 480, 260, g(E.pauli_pair(), x=240, y=130, scale=1.2), zoom=2)

    print("Objetos")
    pickups = {"photon_1": lambda: I.photon(1), "photon_5": lambda: I.photon(5), "photon_10": lambda: I.photon(10), "positron": I.positron, "heal": I.heal, "quark": I.quark, "higgs": I.higgs}
    for key, fn in pickups.items():
        render(f"pickup_{key}", 70, 70, g(fn(), x=35, y=35, scale=1.4), zoom=2)
    for key, fn in (("well", I.quantum_well), ("bound", I.bound_electron), ("superposition", I.superposition)):
        render(f"container_{key}", 140, 120, g(fn(), x=70, y=66, scale=1.3), zoom=2)
    for i, (_, kind, glyph, rarity) in enumerate(I.ICON_SAMPLES):
        render(f"icon_{i}", 80, 84, g(I.icon(kind, glyph, rarity), x=40, y=38), zoom=2)

    print("Mundo")
    acc = P.LAYER["K"]["accent"]
    tiles = (
        g(W.platform(5, acc, "n=1"), x=20, y=50)
        + g(W.one_way_platform(4, acc), x=220, y=50)
        + g(W.potential_spikes(3), x=390, y=36)
        + g(W.wall(3, 3), x=520, y=10)
        + text(20, 100, "nivel de energía", size=10, fill=P.INK_DIM, mono=True)
        + text(220, 100, "nivel virtual (atravesable)", size=10, fill=P.INK_DIM, mono=True)
        + text(390, 100, "pico de potencial", size=10, fill=P.INK_DIM, mono=True)
        + text(520, 125, "retícula", size=10, fill=P.INK_DIM, mono=True)
    )
    render("tiles", 640, 140, tiles, zoom=2)
    layer_platforms = "".join(g(W.platform(4, P.LAYER[k]["accent"], f"capa {k}"), x=20 + i * 150, y=30) for i, k in enumerate(P.LAYER))
    render("tiles_layers", 620, 60, layer_platforms, zoom=2)
    render("bubble_chamber", 1280, 400, W.bubble_chamber(1280, 400), zoom=1, background=P.VOID)
    render("projectile", 200, 60, g(W.projectile(), x=150, y=30, scale=1.5), zoom=2)

    print("Reglas de lenguaje visual")
    rules = (
        g(E._sphere(16, P.NEGATIVE, "r1"), x=50, y=45)
        + g(E._sphere(16, P.POSITIVE, "r2"), x=150, y=45)
        + g(E._sphere(16, P.NEUTRAL, "r3"), x=250, y=45)
        + g(E._anti(16, P.POSITIVE), x=350, y=45)
        + g(C.wilas(uid="r5"), x=460, y=45)
        + "".join(text(x, 100, t, size=11, fill=P.INK_DIM, anchor="middle", mono=True) for x, t in ((50, "carga −"), (150, "carga +"), (250, "neutra"), (350, "antimateria"), (460, "jugador")))
    )
    render("rules_color", 520, 115, rules, zoom=2)
    build_animations()
    print(f"Listo → {OUT}")


if __name__ == "__main__":
    main()
