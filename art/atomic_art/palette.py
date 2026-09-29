"""Paleta central de AtomicJump.

Todos los generadores leen los colores de aquí. Cambiar un token y regenerar
actualiza todos los assets de forma coherente.
"""

# Vacío y tinta
VOID = "#05070F"  # fondo base (casi negro azulado)
VOID_2 = "#0B1022"  # paneles, paredes
VOID_3 = "#141B36"  # rellenos elevados
INK = "#EAF2FF"  # blanco de luz
INK_DIM = "#8C97B8"  # texto y líneas secundarias
GRID = "#1C2547"  # retículas

# Identidad del jugador: nada más en el juego usa este verde menta
PLAYER = "#6BFFB8"
PLAYER_DEEP = "#1FAE7A"

# Carga eléctrica: regla de color para partículas
NEGATIVE = "#3DE8FF"  # cian: electrones, muones, tau...
POSITIVE = "#FF3D8B"  # magenta: protones, alfa, positrones...
NEUTRAL = "#DCE3F5"  # blanco frío: neutrones, neutrinos, Z...

# Familias de interacción
FAMILY = {
    "electromagnetic": "#FFE45C",  # amarillo luz
    "strong": "#FF6A3D",  # naranja "color"
    "weak": "#C6FF3D",  # lima radiactivo
    "gravity": "#8F7BFF",  # índigo
    "quantum": "#FF7BF1",  # rosa iridiscente
}

# Rarezas
RARITY = {
    "common": "#EAF2FF",
    "rare": "#4DA3FF",
    "epic": "#B06BFF",
    "legendary": "#FFD25A",
}

# Divisas
PHOTON = FAMILY["electromagnetic"]
POSITRON = POSITIVE
QUARK_COLORS = ("#FF4D4D", "#4DFF88", "#4D7BFF")  # carga de color r, g, b
HIGGS = "#FFD25A"

# Capas: tinte de la nube orbital de fondo
LAYER = {
    "K": {"name": "Capa K", "orbital": "1s", "tint": "#2F6BFF", "accent": "#7FB0FF"},
    "L": {"name": "Capa L", "orbital": "2p", "tint": "#12C9B4", "accent": "#7CF5E4"},
    "M": {"name": "Capa M", "orbital": "3d", "tint": "#8C4DFF", "accent": "#C7A6FF"},
    "N": {"name": "Capa N", "orbital": "4f", "tint": "#FF3D62", "accent": "#FF9DB0"},
}

# Amenaza
DECOHERENCE = "#C9D2FF"
DANGER = POSITIVE


def hex_to_rgb(color: str) -> tuple[int, int, int]:
    color = color.lstrip("#")
    return tuple(int(color[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]
