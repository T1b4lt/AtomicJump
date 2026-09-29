# 12 · Arquitectura técnica (objetivo)

Este documento describe **hacia dónde** debe ir el código. El estado actual y los pasos para llegar aquí están en el [ROADMAP](../ROADMAP.md).

## Motor y configuración

- **Godot 4.7** (GDScript), renderer _Compatibility_.
- Viewport de referencia **1280×720** (el prototipo usa 1160×670 y se migra en la Fase 2); ver [13-dirección de arte](13-art-style.md).
- `display/window/stretch/mode = canvas_items` y `aspect = keep_width` (el alto se amplía en pantallas más altas).
- Se trackean en git `*.import` y `*.uid`; se ignora `.godot/`.

## Convenciones de código

- **Tipado estático en todo**: variables, parámetros y retornos. En `project.godot` están activados como _error_ los avisos `untyped_declaration`, `unsafe_*` (`property_access`, `method_access`, `cast`, `call_argument`) y `unused_*` (`variable`, `local_constant`, `private_class_variable`, `parameter`, `signal`). `inferred_declaration` queda desactivado: se permite `:=`. Los avisos de `addons/` se excluyen (opción por defecto de Godot).
- Nombres: `snake_case` en ficheros, carpetas, variables y funciones; `PascalCase` en `class_name`; `CONSTANT_CASE` solo en `const`.
- Nombres **funcionales en inglés** en el código (`coin`, `chest`, `hp`). Los temáticos solo en traducciones (ver [02-universo](02-universe.md#regla-de-nombres-código-vs-juego)).
- Señales en pasado: `hp_changed`, `chunk_entered`, `boss_defeated`.
- **"Llamar hacia abajo, señales hacia arriba"**: un nodo llama a métodos de sus hijos y escucha señales de ellos; nunca hace `get_parent()` para manipular al padre.
- Nodos referenciados con **nombres únicos** (`%HpBar`) en lugar de rutas largas.
- Valores ajustables en `@export` o en recursos de datos, nunca como números mágicos.
- `preload()` en constantes para escenas conocidas; `load()` solo para cargas dinámicas por ruta.
- Nada de `_process` para refrescar la UI: se actualiza al recibir una señal.
- Formato y lint con **gdtoolkit** 4.5 (`gdformat`, `gdlint`), versión fijada en `requirements-dev.txt` y configuración en `gdformatrc` y `gdlintrc` (tabs, 100 caracteres por línea, se excluyen `addons/`, `art/` y `.godot/`).
- `.editorconfig`: UTF-8, LF, tabs en `.gd` y dos espacios en el resto; los ficheros que genera Godot (`.tscn`, `.tres`, `.import`…) conservan su formato.
- Ningún `class_name` puede coincidir con un tipo o enum global de Godot (por ejemplo, la llave es `KeyPickup`, no `Key`, que choca con el enum `Key`).
- Commits con _Conventional Commits_ (release-please ya lo usa).

## Estructura de carpetas objetivo

```
res://
├── core/                    # Autoloads y sistemas transversales
│   ├── autoload/            # events.gd, run_manager.gd, meta_progress.gd, scene_router.gd, settings.gd, audio.gd
│   ├── rng/                 # seed_code.gd, seed_hash.gd, world_rng.gd
│   ├── stats/               # stat_block.gd, stat_modifier.gd, stats.gd
│   └── save/                # save_system.gd, migrations
├── actors/
│   ├── player/              # player.tscn/.gd, estados, cámara
│   ├── enemies/             # enemy_base, un subdirectorio por enemigo
│   ├── bosses/
│   └── components/          # health_component, hitbox, hurtbox, knockback, status_effects
├── combat/                  # projectile, shooter, damage_info
├── world/
│   ├── chunks/              # chunk.gd (base), chunk_template.tscn, k/, l/, m/, n/, special/
│   ├── generation/          # layer_generator.gd, chunk_library.gd
│   ├── rising_threat/
│   ├── hazards/             # spike, force_field…
│   └── tilesets/
├── items/
│   ├── pickups/             # coin, key, heal
│   ├── containers/          # chest, choice_pedestal, item_pedestal
│   ├── passive/  active/  boons/   # scripts de efectos
│   └── shop/
├── lobby/                   # escena del Núcleo y estaciones
├── ui/                      # hud, menus, run_summary, boon_picker, build_screen, theme
├── data/                    # recursos .tres: characters, items, boons, enemies, layers, chunks, meta_upgrades, heat_modifiers
├── localization/            # translations.csv
├── assets/                  # arte, audio, fuentes (provisional → final)
└── tests/                   # gdUnit4
```

## Autoloads

Se mantienen pocos y con responsabilidades claras:

| Autoload       | Responsabilidad                                                                                                                                                         |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Events`       | Bus de señales **solo** para eventos globales de juego (`enemy_killed`, `item_picked`, `run_ended`…). No se usa para comunicación entre padre e hijo.                   |
| `RunManager`   | Estado de la partida en curso (`RunState`): semilla, capa y tramo actual, divisas, build, estadísticas de partida. Crea el estado al empezar y lo descarta al terminar. |
| `MetaProgress` | Datos persistentes (quarks, mejoras, desbloqueos, registros) y su carga y guardado.                                                                                     |
| `SceneRouter`  | Cambios de escena con transición y paso de parámetros.                                                                                                                  |
| `Settings`     | Opciones, carga y guardado de `settings.cfg`, aplicación a buses de audio y ventana.                                                                                    |
| `Audio`        | Música y efectos globales.                                                                                                                                              |

## Estado de partida

```gdscript
class_name RunState extends RefCounted

var seed_code: String
var world_rng: WorldRng
var character: CharacterData
var stats: Stats            # estadísticas calculadas con modificadores
var hp: float
var coins: int
var keys: int
var meta_currency: int
var passive_items: Array[ItemData]
var active_item: ItemData
var boons: Dictionary       # slot -> BoonInstance
var layer_index: int
var path: PackedStringArray # ramas elegidas: ["K/1/L", "K/2/R", ...]
var altitude: float
var counters: RunCounters   # saltos, enemigos, objetos...

signal hp_changed(value: float, max_value: float)
signal coins_changed(value: int)
# ...
```

- Reiniciar una partida es crear un `RunState` nuevo: **no hay `reset_game()` que mantener sincronizado a mano**.
- La UI se conecta a las señales de `RunState`.

## Sistema de estadísticas

- `StatBlock` (Resource): valores base por personaje.
- `StatModifier`: `{stat, type: ADD|MULT, value, source}`.
- `Stats`: calcula `valor_final` cacheado; se invalida al añadir o quitar modificadores y emite `stat_changed(stat)`.
- Fórmula en [04-jugador](04-player.md#cómo-se-calculan-las-estadísticas).

## Objetos e interacciones: basados en datos y efectos

- `ItemData` / `BoonData` (Resource): id, rareza, pools, etiquetas, icono, clave de nombre y descripción, lista de **efectos**.
- Efectos como recursos reutilizables (`StatEffect`, `OnHitEffect`, `ProjectileModifierEffect`, `OnJumpEffect`…) con _hooks_ a eventos del jugador y del combate. Un objeto nuevo sencillo no necesita código: solo un `.tres` que combine efectos existentes.
- Los proyectiles se construyen a partir de un `ProjectileSpec` que los modificadores transforman (cantidad, dirección, perforación, rebotes, estados…).

## Generación y semillas

- `SeedCode`: generación, normalización y conversión de texto a `int`.
- `SeedHash`: hash estable propio (no se usa `hash()` del motor).
- `WorldRng`: `roll(domain, key...)`, `roll_int`, `pick_weighted` (con _rendezvous hashing_) y `local_rng(address)`.
- `LayerGenerator`: produce la secuencia de tramos de una capa y de sus ramas a partir de `LayerData` y `ChunkLibrary`.
- `Chunk` (script base de todos los tramos): expone marcadores, huecos y metadatos, y rellena sus huecos al entrar en el árbol usando su dirección.
- Detalles en [08-semillas](08-seeds.md).

## Combate

- Componentes: `HealthComponent` (vida, invulnerabilidad, señales), `Hitbox` (hace daño), `Hurtbox` (recibe daño).
- `DamageInfo`: cantidad, fuente, tipo, estados a aplicar y retroceso.
- Capas de física (actualizar `project.godot`):

| Capa | Nombre               |
| ---- | -------------------- |
| 1    | `world`              |
| 2    | `player`             |
| 3    | `enemies`            |
| 4    | `pickups`            |
| 5    | `player_projectiles` |
| 6    | `enemy_projectiles`  |
| 7    | `hazards`            |
| 8    | `one_way_platforms`  |
| 9    | `rising_threat`      |

## Jugador

- Máquina de estados sencilla (`idle`, `run`, `jump`, `fall`, `dash`, `hurt`, `dead`) con estados como nodos o como enum más funciones; se evita la lógica en un único `_physics_process` gigante.
- Parámetros de movimiento (coyote, buffer, gravedad…) en un recurso `MovementConfig` exportado.

## Guardado

- `SaveSystem` serializa `MetaProgress` a JSON con `schema_version`; aplica migraciones al cargar.
- Nunca se guardan referencias a rutas `res://` frágiles: se guardan **ids** de objeto.

## Calidad

- **Tests** con gdUnit4 (v6.2.1, incluido en `addons/gdUnit4/`), ejecutables en modo _headless_: semillas doradas, monotonía, estadísticas, economía y guardado. Viven en `tests/` como `*_test.gd`. `tests/smoke_test.gd` comprueba que la escena principal carga y que todos los scripts del proyecto compilan con los avisos como error.
- **CI** (GitHub Actions, `.github/workflows/ci.yml`): `gdformat --check`, `gdlint` y los tests con Godot 4.7.2 _headless_ en cada PR y en cada push a `main`; el informe de gdUnit4 se sube como artefacto. Las builds de exportación (Windows y Linux) en cada release de release-please llegan en la Fase 15.
- **Releases** con release-please (`.github/workflows/release-please.yml`, action v5) en cada push a `main`: abre o actualiza la PR de release con la versión y el `CHANGELOG.md`. Configuración en `release-please-config.json` (tipo `simple`, `bump-minor-pre-major` para que un cambio incompatible no salte a la 1.0 antes de tiempo) y versión actual en `.release-please-manifest.json`. Usa el `GITHUB_TOKEN` del workflow, así que no hay token personal que caduque; a cambio, la CI no se dispara sola en las PR de release (solo tocan versión y CHANGELOG).
- **Exportación**: `export_presets.cfg` con los presets `Windows Desktop` y `Linux` (x86_64, PCK embebido), que excluyen `tests/` y `addons/gdUnit4/`. Salida en `export/` (ignorado por git).
- **Escenas de depuración**: jugar un tramo suelto, arena de jefe y galería de objetos.
- **Consola o menú de depuración** (solo en builds de desarrollo): dar objetos, saltar de capa, invulnerabilidad y mostrar huecos y direcciones de las tiradas.
