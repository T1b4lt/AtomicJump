# 12 · Arquitectura técnica (objetivo)

Este documento describe **hacia dónde** debe ir el código. El estado actual y los pasos para llegar aquí están en el [ROADMAP](../ROADMAP.md).

## Motor y configuración

- **Godot 4.7** (GDScript), renderer _Compatibility_.
- Viewport de referencia **1280×720** (migrado en la Fase 2); ver [13-dirección de arte](13-art-style.md). Los tramos del prototipo siguen midiendo 1160×670 (`Chunk.WIDTH` y `Chunk.HEIGHT`): la cámara centra el área de juego en horizontal y alinea su borde inferior con el del primer tramo, así que el jugador ve un poco más hacia arriba que antes, pero muere en el mismo punto. La Fase 5 rehace los tramos con el tamaño definitivo.
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
- Los nodos de las escenas se nombran en `PascalCase` (convención de Godot).
- **Navegación entre pantallas** con `SceneRouter.go_to(SceneRouter.LEVEL, params)`, que recibe rutas. Las pantallas (menús, nivel, pantalla final) se apuntan entre sí, y con `preload()` formarían ciclos de dependencias; todo lo que se **instancia** (tramos, recogibles, peligros) sí usa `preload()`.
- Textos visibles siempre como **claves de traducción**: en las escenas, el `text` del nodo es la clave (los `Control` la traducen solos); en código, `tr("CLAVE")`. Las etiquetas que muestran datos (números, semillas) llevan `auto_translate_mode = Disabled`.
- Números de capa de física con las constantes de `PhysicsLayers` (`core/physics_layers.gd`), nunca con números sueltos.
- Formato y lint con **gdtoolkit** 4.5 (`gdformat`, `gdlint`), versión fijada en `requirements-dev.txt` y configuración en `gdformatrc` y `gdlintrc` (tabs, 100 caracteres por línea, se excluyen `addons/`, `art/` y `.godot/`).
- `.editorconfig`: UTF-8, LF, tabs en `.gd` y dos espacios en el resto; los ficheros que genera Godot (`.tscn`, `.tres`, `.import`…) conservan su formato.
- Ningún `class_name` puede coincidir con un tipo o enum global de Godot (por ejemplo, la llave es `KeyPickup`, no `Key`, que choca con el enum `Key`).
- Commits con _Conventional Commits_ (release-please ya lo usa).

## Estructura de carpetas objetivo

La Fase 2 implantó esta estructura; las carpetas sin contenido todavía se crearán en su fase. Estado actual: `core/autoload/` (`events`, `run_manager`, `scene_router` con su `.tscn`, `settings`), `core/run/` (`run_state.gd`, `run_counters.gd`), `core/stats/`, `core/rng/` (`seed_code`, `seed_hash`, `world_rng`), `core/physics_layers.gd`, `actors/player/` (`player`, `scrolling_camera` y `character_data.gd`), `items/pickups/` y `items/containers/`, `world/level/` (escena de partida), `world/generation/prototype_generator.gd` (generación provisional hasta la Fase 5), `world/chunks/k/` (tramos del prototipo) y `world/chunks/parts/` (bloques, muros y fondos con los que están hechos), `world/hazards/spike/`, `ui/` (`hud`, `main_menu`, `pause_menu`, `settings_menu`, `game_over`), `data/characters/wilas.tres` y `localization/translations.csv`. Las semillas doradas están en `tests/golden/`.

```
res://
├── core/                    # Autoloads y sistemas transversales
│   ├── autoload/            # events.gd, run_manager.gd, meta_progress.gd, scene_router.gd, settings.gd, audio.gd
│   ├── rng/                 # seed_code.gd, seed_hash.gd, world_rng.gd
│   ├── run/                 # run_state.gd, run_counters.gd
│   ├── stats/               # stat_block.gd, stat_modifier.gd, stats.gd
│   ├── save/                # save_system.gd, migrations
│   └── physics_layers.gd    # constantes de las capas de física
├── actors/
│   ├── player/              # player.tscn/.gd, character_data.gd, estados, cámara
│   ├── enemies/             # enemy_base, un subdirectorio por enemigo
│   ├── bosses/
│   └── components/          # health_component, hitbox, hurtbox, knockback, status_effects
├── combat/                  # projectile, shooter, damage_info
├── world/
│   ├── level/               # escena de partida (level.tscn)
│   ├── chunks/              # chunk.gd (base), chunk_template.tscn, k/, l/, m/, n/, special/, parts/
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

Desde la Fase 2 existen `Events`, `Settings`, `RunManager` y `SceneRouter` (en ese orden de carga, en `core/autoload/`); `MetaProgress` llega en la Fase 10 y `Audio` con los SFX. Los scripts de autoload no llevan `class_name` (chocaría con el nombre del autoload).

- **`Events`**: hoy emite `run_started`, `run_ended`, `coin_collected` y `key_collected`. Como sus señales se emiten desde otros scripts, cada una lleva `@warning_ignore("unused_signal")` (el aviso está como error).
- **`SceneRouter`** (`scene_router.tscn`, una `CanvasLayer` en la capa 100 que funciona también en pausa): `go_to(ruta, params)` funde a negro, cambia de escena y vuelve a fundir; los clics se bloquean durante la transición y una segunda llamada se ignora. La nueva escena lee los parámetros con `SceneRouter.get_param("clave")`. Las rutas de las pantallas son constantes (`MAIN_MENU`, `SETTINGS_MENU`, `LEVEL`, `GAME_OVER`).
- **`Settings`**: volumen general, de música y de efectos (lineal 0–1) e idioma, en `user://settings.cfg` (secciones `audio` y `game`). Se cargan y aplican al arrancar; los valores ausentes o inválidos conservan el valor por defecto. Los buses `Music` y `Effects` están en `default_bus_layout.tres`. La pantalla de opciones aplica los cambios al momento y guarda al volver.

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

Implementado en la Fase 2 (`core/run/run_state.gd`), con lo que necesita el prototipo; el resto de campos llega con su sistema:

- `RunManager.start_run(seed_text, character)` crea el `RunState` (por defecto con Wilas; sin semilla válida, con una aleatoria) y emite `Events.run_started`; `end_run()` lo suelta, emite `Events.run_ended` y lo devuelve para que la pantalla final lo reciba por `SceneRouter`. Ir al menú desde la pausa también termina la partida.
- Campos actuales: `seed_code` (semilla como la ve el jugador, normalizada), `world_rng` (desde la Fase 3), `character`, `stats`, `hp`, `coins`, `keys` (saldo), `altitude` y `counters` (`jumps`, `coins_collected`, `keys_collected`).
- Señales: `hp_changed(value, max_value)`, `coins_changed`, `keys_changed`, `altitude_changed` y `died`. `take_damage(amount)` aplica el apantallamiento (`daño × (1 − defense)`) y emite `died` una sola vez; si baja la coherencia máxima, la coherencia se recorta.
- Los recogibles no conocen la partida: emiten `Events.coin_collected` / `Events.key_collected` y `RunManager` lo suma al `RunState` en curso.
- `Player`, `Hud` y `Level` reciben el `RunState` con `bind_run(run)` (llamar hacia abajo) en lugar de leer un autoload; así se prueban sin partida global. La escena del nivel lanzada sola (F6) empieza una partida aleatoria.

## Sistema de estadísticas

- `StatBlock` (Resource): valores base por personaje. Sus propiedades se llaman como los ids de estadística.
- `StatModifier` (Resource, para poder incluirlo en los `.tres` de objetos): `{stat, type: ADD|MULT, value, source}`. `MULT` es una fracción: `0.25` es +25 %.
- `Stats` (`RefCounted`): calcula `valor_final` cacheado; al añadir o quitar modificadores recalcula esa estadística y emite `stat_changed(stat, value)` solo si el valor cambia. `remove_modifiers_from(source)` quita todo lo de un origen y `get_modifiers(stat)` da el desglose.
- Los ids son constantes de `Stats` (`Stats.SPEED`…, lista en `Stats.ALL`) y los límites están en `Stats.MIN_VALUES` y `Stats.MAX_VALUES`.
- `CharacterData` (Resource): `id`, `name_key` y `base_stats`. Wilas está en `data/characters/wilas.tres`.
- Fórmula en [04-jugador](04-player.md#cómo-se-calculan-las-estadísticas).

## Objetos e interacciones: basados en datos y efectos

- `ItemData` / `BoonData` (Resource): id, rareza, pools, etiquetas, icono, clave de nombre y descripción, lista de **efectos**.
- Efectos como recursos reutilizables (`StatEffect`, `OnHitEffect`, `ProjectileModifierEffect`, `OnJumpEffect`…) con _hooks_ a eventos del jugador y del combate. Un objeto nuevo sencillo no necesita código: solo un `.tres` que combine efectos existentes.
- Los proyectiles se construyen a partir de un `ProjectileSpec` que los modificadores transforman (cantidad, dirección, perforación, rebotes, estados…).

## Generación y semillas

- `SeedCode`: generación, normalización y conversión de texto a `int`.
- `SeedHash`: hash estable propio (no se usa `hash()` del motor).
- `WorldRng`: `roll(domain, key)`, `roll_int`, `roll_range`, `chance`, `pick_weighted` (con _rendezvous hashing_), `local_rng(domain, key)` y `shuffled`; la clave es un `Array`. Contiene `GENERATION_VERSION`.
- Implantados en la Fase 3 (`core/rng/`). Hasta la Fase 5, `PrototypeGenerator` (`world/generation/`) elige los tramos del nivel y planifica sus objetos con funciones puras del `WorldRng` de la partida; `Chunk.place_objects(plan)` solo instancia lo planificado. Nada del mundo usa el generador global (`randi()`, `seed()`).
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

Configuradas en `project.godot` desde la Fase 2 y disponibles en código como `PhysicsLayers.WORLD`, `PhysicsLayers.HAZARDS`… Hoy: muros y suelo en `world`; bloques del prototipo (atravesables desde abajo) en `one_way_platforms`; el jugador en `player` con máscara `world` + `one_way_platforms`; recogibles y cofres en `pickups` y pinchos en `hazards`, ambos con máscara `player`. Los cuerpos estáticos no llevan máscara.

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
