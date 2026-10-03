"""Exporta el arte del juego a Godot.

Uso:  uv run build_game_assets.py
Salida:
  ../assets/generated/            SVG sin filtros ni texto (el brillo lo pone el motor)
  ../assets/generated/manifest.json   lista de assets con su tamaño y su origen
  ../core/palette.gd              la paleta como constantes de GDScript (clase Palette)

Los SVG se importan en Godot con `svg/scale = 2` y se dibujan a escala 0,5, para
que queden nítidos aunque la ventana sea mayor que 1280×720.
"""

import json
from collections.abc import Callable
from pathlib import Path

from atomic_art import characters as C
from atomic_art import enemies as E
from atomic_art import items as I
from atomic_art import palette as P
from atomic_art import world as W
from atomic_art.svg import doc, g

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parent
OUT = PROJECT / "assets" / "generated"
PALETTE_GD = PROJECT / "core" / "palette.gd"

# Lienzos (ancho, alto) de las piezas de Wilas. Todas comparten el centro del núcleo.
CORE_CANVAS = (52, 52)
ORBITAL_CANVAS = (72, 72)
ELECTRON_CANVAS = (8, 8)
# Atlas de tiles de una capa (distribución en atomic_art/world.py) y otros lienzos del mundo
ATLAS_CANVAS = (W.ATLAS_COLUMNS * W.TILE, W.ATLAS_ROWS * W.TILE)
SPIKES_CANVAS = (2 * W.TILE, 20)
REWARD_ICON_CANVAS = (48, 48)
# Enemigos de la Capa K y proyectil del jugador (Fase 6)
ORBITAL_ELECTRON_CANVAS = (28, 28)
DECAY_ELECTRON_CANVAS = (18, 18)
FREE_NEUTRON_CANVAS = (40, 48)
ALPHA_PARTICLE_CANVAS = (44, 44)
ALPHA_LINES_CANVAS = (48, 28)
PROJECTILE_CANVAS = (64, 16)
# Recogibles, contenedores, tienda e iconos (Fase 7)
PICKUP_CANVAS = {1: (28, 28), 5: (36, 36), 10: (48, 48)}
POSITRON_CANVAS = (28, 28)
HEAL_CANVAS = (28, 32)
HEAL_BIG_CANVAS = (44, 44)
WELL_CANVAS = (76, 52)
BOUND_ELECTRON_CANVAS = (64, 40)
PEDESTAL_CANVAS = (48, 56)
SUPERPOSITION_CANVAS = (52, 44)
SHOPKEEPER_CANVAS = (64, 64)
ICON_CANVAS = (64, 72)
GEM_CANVAS = (10, 10)
# Capas con tileset exportado (se añaden según llegan al juego)
TILESET_LAYERS = ("K",)

# (ruta relativa a OUT, lienzo, función que devuelve el SVG centrado en (0, 0), origen)
Asset = tuple[str, tuple[int, int], Callable[[], str], str]

ASSETS: list[Asset] = [
    ("player/player_core.svg", CORE_CANVAS, C.wilas_core, "characters.wilas_core"),
    ("player/player_orbital.svg", ORBITAL_CANVAS, C.wilas_orbital, "characters.wilas_orbital"),
    ("player/player_orbital_front.svg", ORBITAL_CANVAS, C.wilas_orbital_front, "characters.wilas_orbital_front"),
    ("player/player_electron.svg", ELECTRON_CANVAS, C.wilas_electron, "characters.wilas_electron"),
] + [
    (f"player/player_eyes_{expr}.svg", CORE_CANVAS, (lambda e=expr: C.wilas_eyes(e)), f"characters.wilas_eyes('{expr}')")
    for expr in C.EXPRESSIONS
] + [
    (f"tilesets/layer_{layer.lower()}_tiles.svg", ATLAS_CANVAS, (lambda l=layer: W.tileset_atlas(l)), f"world.tileset_atlas('{layer}')")
    for layer in TILESET_LAYERS
] + [
    ("hazards/potential_spikes.svg", SPIKES_CANVAS, W.potential_spikes_sprite, "world.potential_spikes_sprite"),
] + [
    ("enemies/orbital_electron.svg", ORBITAL_ELECTRON_CANVAS, E.orbital_electron_sprite, "enemies.orbital_electron_sprite"),
    ("enemies/decay_electron.svg", DECAY_ELECTRON_CANVAS, E.decay_electron_sprite, "enemies.decay_electron_sprite"),
    ("enemies/free_neutron.svg", FREE_NEUTRON_CANVAS, E.free_neutron_sprite, "enemies.free_neutron_sprite"),
    ("enemies/alpha_particle.svg", ALPHA_PARTICLE_CANVAS, E.alpha_particle_sprite, "enemies.alpha_particle_sprite"),
    # Las líneas se dibujan a la izquierda de (0, 0): se desplazan para que el lienzo las contenga
    ("enemies/alpha_speed_lines.svg", ALPHA_LINES_CANVAS, (lambda: g(E.alpha_speed_lines(), x=ALPHA_LINES_CANVAS[0] / 2)), "enemies.alpha_speed_lines"),
    ("combat/player_projectile.svg", PROJECTILE_CANVAS, W.projectile_sprite, "world.projectile_sprite"),
] + [
    (f"pickups/photon_{value}.svg", PICKUP_CANVAS[value], (lambda v=value: I.photon_sprite(v)), f"items.photon_sprite({value})")
    for value in PICKUP_CANVAS
] + [
    ("pickups/positron.svg", POSITRON_CANVAS, I.positron_sprite, "items.positron_sprite"),
    ("pickups/heal.svg", HEAL_CANVAS, I.heal_sprite, "items.heal_sprite"),
    ("pickups/heal_big.svg", HEAL_BIG_CANVAS, (lambda: I.heal_sprite(big=True)), "items.heal_sprite(big=True)"),
    # El pozo se dibuja con su borde superior a 26 px del centro: el lienzo lo baja para que quepa
    ("containers/quantum_well.svg", WELL_CANVAS, I.quantum_well_sprite, "items.quantum_well_sprite"),
    ("containers/quantum_well_lit.svg", WELL_CANVAS, (lambda: I.quantum_well_sprite(lit=True)), "items.quantum_well_sprite(lit=True)"),
    ("containers/bound_electron.svg", BOUND_ELECTRON_CANVAS, I.bound_electron_sprite, "items.bound_electron_sprite"),
    ("containers/item_pedestal.svg", PEDESTAL_CANVAS, (lambda: g(I.item_pedestal_sprite(), y=20)), "items.item_pedestal_sprite"),
    ("containers/superposition_wave.svg", SUPERPOSITION_CANVAS, I.superposition_wave_sprite, "items.superposition_wave_sprite"),
    ("shop/shopkeeper.svg", SHOPKEEPER_CANVAS, I.shopkeeper_sprite, "items.shopkeeper_sprite"),
    ("icons/icon_gem.svg", GEM_CANVAS, I.icon_gem_sprite, "items.icon_gem_sprite"),
] + [
    (f"icons/{icon_id}.svg", ICON_CANVAS, (lambda i=icon_id: I.game_icon(i)), f"items.game_icon('{icon_id}')")
    for icon_id in I.GAME_ICONS
] + [
    (f"rewards/reward_{reward}.svg", REWARD_ICON_CANVAS, (lambda r=reward: I.reward_game_icon(r)), f"items.reward_game_icon('{reward}')")
    for reward in I.REWARD_GAME_GLYPHS
]

# .import mínimo de un SVG nuevo: Godot lo completa al importar y conserva la escala doble
DEFAULT_IMPORT = '[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\nsvg/scale=2.0\n'


def export_svg(body: str, size: tuple[int, int]) -> str:
    """SVG de juego: centrado en el lienzo, sin filtros de brillo ni texto."""
    w, h = size
    svg = doc(w, h, g(body, x=w / 2, y=h / 2), glow=False)
    assert "filter" not in svg and "<text" not in svg, "Los SVG del juego no llevan filtros ni texto"
    return svg


def color_literal(hex_color: str) -> str:
    r, g_, b = P.hex_to_rgb(hex_color)
    return f"Color({r / 255:.4f}, {g_ / 255:.4f}, {b / 255:.4f})"


def palette_gd() -> str:
    """La paleta como clase de GDScript, con el formato de gdformat."""
    tokens = {
        "VOID": P.VOID,
        "VOID_2": P.VOID_2,
        "VOID_3": P.VOID_3,
        "GRID": P.GRID,
        "INK": P.INK,
        "INK_DIM": P.INK_DIM,
        "PLAYER": P.PLAYER,
        "PLAYER_DEEP": P.PLAYER_DEEP,
        "NEGATIVE": P.NEGATIVE,
        "POSITIVE": P.POSITIVE,
        "NEUTRAL": P.NEUTRAL,
        "DECOHERENCE": P.DECOHERENCE,
        "DANGER": P.DANGER,
        "PHOTON": P.PHOTON,
        "POSITRON": P.POSITRON,
        "HIGGS": P.HIGGS,
    }
    tokens |= {f"FAMILY_{k.upper()}": v for k, v in P.FAMILY.items()}
    tokens |= {f"RARITY_{k.upper()}": v for k, v in P.RARITY.items()}
    for layer, info in P.LAYER.items():
        tokens[f"LAYER_{layer}_TINT"] = info["tint"]
        tokens[f"LAYER_{layer}_ACCENT"] = info["accent"]
    lines = [
        "class_name Palette",
        "extends RefCounted",
        "## Colors of the art direction (docs/13-art-style.md#paleta).",
        "## Generated by art/build_game_assets.py from art/atomic_art/palette.py: do not edit.",
        "",
    ]
    lines += [f"const {name}: Color = {color_literal(value)}  # {value.upper()}" for name, value in tokens.items()]
    return "\n".join(lines) + "\n"


def main() -> None:
    if OUT.exists():
        # Se borran los SVG y el manifiesto, pero no los .import de Godot, que
        # guardan la escala de importación y los uid de cada asset
        for svg in OUT.rglob("*.svg"):
            svg.unlink()
    OUT.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, dict] = {}
    for rel, size, fn, source in ASSETS:
        out = OUT / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(export_svg(fn(), size), encoding="utf-8")
        imported = out.with_name(out.name + ".import")
        if not imported.exists():
            imported.write_text(DEFAULT_IMPORT, encoding="utf-8")
        manifest[rel] = {"size": list(size), "source": source}
        print("  ", rel)
    # Assets que ya no existen: su .import queda huérfano
    for imported in OUT.rglob("*.svg.import"):
        if imported.with_suffix("").relative_to(OUT).as_posix() not in manifest:
            imported.unlink()
            print("   (borrado)", imported.relative_to(OUT))
    (OUT / "manifest.json").write_text(
        json.dumps({"generator": "art/build_game_assets.py", "assets": manifest}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    PALETTE_GD.write_text(palette_gd(), encoding="utf-8")
    print(f"Listo → {OUT.relative_to(PROJECT)} y {PALETTE_GD.relative_to(PROJECT)}")


if __name__ == "__main__":
    main()
