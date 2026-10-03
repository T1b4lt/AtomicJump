# art/ — generador de arte de AtomicJump

Todo el arte del juego se genera por código con el estilo **"Luz sobre el vacío"**: vectores luminosos sobre fondo oscuro, colores por carga eléctrica y fondos calculados con orbitales reales. La propuesta completa está en [`docs/assets/art-direction/index.html`](../docs/assets/art-direction/index.html).

## Uso

```bash
cd art
uv sync                          # instala dependencias
uv run build_art_direction.py    # regenera imágenes y animaciones de la propuesta (~2 min)
uv run build_art_direction.py --anim   # solo las animaciones
uv run build_game_assets.py      # exporta el arte del juego a ../assets/generated/ y la paleta a ../core/palette.gd
```

El arte del juego (`assets/generated/`, con su `manifest.json`) y `core/palette.gd` se generan y **se versionan**: no se editan a mano. Detalles en [13-dirección de arte](../docs/13-art-style.md#exportación-a-godot).

## Estructura

| Módulo | Contenido |
|---|---|
| `atomic_art/palette.py` | Paleta central: **única fuente de verdad de los colores** |
| `atomic_art/svg.py` | Utilidades para componer SVG y renderizar a PNG (resvg) |
| `atomic_art/characters.py` | Wilas y los personajes desbloqueables |
| `atomic_art/enemies.py` | Enemigos por capa y jefes |
| `atomic_art/items.py` | Recogibles, contenedores y sistema de iconos (marco + glifo + joya) |
| `atomic_art/world.py` | Fondos orbitales (NumPy), tiles, Decoherencia y trazas de cámara de burbujas |
| `atomic_art/mockups.py` | Composiciones: captura simulada, tarjeta de partida, hoja de modelo |
| `build_game_assets.py` | Exportación a Godot: SVG sin filtros ni texto por piezas, manifiesto y paleta en GDScript |
| `atomic_art/anim.py` | Animaciones de referencia (escenas `t → SVG` en bucle, exportadas a WebP). Sus tiempos y curvas son la referencia para implementarlas en Godot |

## Reglas

- Cada asset es una función que devuelve un fragmento SVG centrado en `(0, 0)`.
- Los colores salen siempre de `palette.py`; nunca se escriben a mano.
- Los filtros de brillo (`glow`) son solo para las previsualizaciones: el importador SVG de Godot no soporta filtros, así que en el juego el brillo lo pone el motor.
- La carpeta tiene un `.gdignore` para que Godot no la importe.
