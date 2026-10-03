# 12 · Arquitectura técnica (objetivo)

Este documento describe **hacia dónde** debe ir el código. El estado actual y los pasos para llegar aquí están en el [ROADMAP](../ROADMAP.md).

## Motor y configuración

- **Godot 4.7** (GDScript), renderer _Compatibility_.
- Viewport de referencia **1280×720** (migrado en la Fase 2); ver [13-dirección de arte](13-art-style.md). Desde la Fase 5 los tramos miden 1280×704 (40 × 22 tiles de 32 px, `Chunk.WIDTH` y `ChunkData.height_tiles`); la cámara nunca enseña nada por debajo del primer tramo.
- **HDR 2D** activado (`rendering/viewport/hdr_2d`) y un `WorldEnvironment` con _glow_ en las escenas de juego (`world/environment/glow_environment.tres`): brilla lo que se dibuja con color por encima de 1 (ver [13-dirección de arte](13-art-style.md#implementación-en-godot)).
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

La Fase 2 implantó esta estructura; las carpetas sin contenido todavía se crearán en su fase. Estado actual: `core/autoload/` (`events`, `run_manager`, `scene_router` con su `.tscn`, `settings`), `core/run/` (`run_state.gd`, `run_counters.gd`), `core/stats/`, `core/rng/` (`seed_code`, `seed_hash`, `world_rng`), `core/physics_layers.gd`, `core/palette.gd` (generado), `actors/player/` (`player`, `player_visual`, `player_input`, `movement_config`, `player_camera` y `character_data.gd`), `actors/components/` (`health_component`, `hitbox`, `hurtbox`, `status_effects`), `actors/enemies/` (`enemy`, `enemy_data`, `behaviors/` y una carpeta por enemigo), `combat/` (`damage_info`, `projectile_spec`, `projectile`, `shooter`, `status_effect_data`, `hit_stop` y `effects/impact_effect`), `items/pickups/` y `items/containers/`, `world/level/` (escena de partida), `world/generation/` (`layer_data`, `layer_generator`, `layer_plan`, `chunk_placement`, `chunk_library`, `chunk_info`, `slot_filler`), `world/chunks/` (`chunk.gd`, `chunk_data.gd`, `chunk_validator.gd`, `fork_gate`, `chunk_template.tscn` y los tramos de la Capa K en `k/`), `world/tilesets/` (TileSet de la Capa K), `world/backgrounds/` (fondo orbital), `world/hazards/spike/`, `world/rising_threat/` (la Decoherencia y su shader), `world/environment/` (el `Environment` con _glow_), `world/debug/` (salas de pruebas de movimiento, de un tramo y de combate, y `DebugBlock`), `ui/` (`hud`, `main_menu`, `pause_menu`, `settings_menu`, `game_over`), `data/characters/wilas.tres`, `data/movement/wilas_movement.tres`, `data/layers/layer_k.tres`, `data/enemies/` (un `EnemyData` por enemigo), `data/statuses/` (estados alterados), `assets/generated/` (arte exportado por `art/build_game_assets.py`) y `localization/translations.csv`. Las semillas doradas están en `tests/golden/`.

```
res://
├── core/                    # Autoloads y sistemas transversales
│   ├── autoload/            # events.gd, run_manager.gd, meta_progress.gd, scene_router.gd, settings.gd, audio.gd
│   ├── rng/                 # seed_code.gd, seed_hash.gd, world_rng.gd
│   ├── run/                 # run_state.gd, run_counters.gd
│   ├── stats/               # stat_block.gd, stat_modifier.gd, stats.gd
│   ├── save/                # save_system.gd, migrations
│   ├── physics_layers.gd    # constantes de las capas de física
│   └── palette.gd           # paleta de colores (generada desde art/)
├── actors/
│   ├── player/              # player.tscn/.gd, player_visual, player_input, movement_config, player_camera, character_data
│   ├── enemies/             # enemy_base, un subdirectorio por enemigo
│   ├── bosses/
│   └── components/          # health_component, hitbox, hurtbox, status_effects
├── combat/                  # damage_info, projectile_spec, projectile, shooter, status_effect_data, hit_stop, effects/
├── world/
│   ├── level/               # escena de partida (level.tscn)
│   ├── chunks/              # chunk.gd (base), chunk_data, chunk_validator, fork_gate, chunk_template.tscn, k/, l/, m/, n/
│   ├── generation/          # layer_data, layer_generator, layer_plan, chunk_library, slot_filler
│   ├── backgrounds/         # fondo orbital de cada capa (shader)
│   ├── rising_threat/       # rising_threat (la Decoherencia), decoherence.gdshader
│   ├── environment/         # Environment con glow
│   ├── debug/               # salas de pruebas (movimiento, tramo suelto)
│   ├── hazards/             # spike, force_field…
│   └── tilesets/            # un TileSet por capa sobre el atlas generado
├── items/
│   ├── pickups/             # coin, key, heal
│   ├── containers/          # chest, choice_pedestal, item_pedestal
│   ├── passive/  active/  boons/   # scripts de efectos
│   └── shop/
├── lobby/                   # escena del Núcleo y estaciones
├── ui/                      # hud, menus, run_summary, boon_picker, build_screen, theme
├── data/                    # recursos .tres: characters, items, boons, enemies, layers, chunks, meta_upgrades, heat_modifiers
├── localization/            # translations.csv
├── assets/                  # arte, audio, fuentes; generated/ lo exporta art/build_game_assets.py
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

- **`Events`**: hoy emite `run_started`, `run_ended`, `coin_collected`, `key_collected`, `enemy_damaged(enemy_id)` y `enemy_killed(enemy_id, position)` (`RunManager` cuenta las muertes y el `Level` hace el _hitstop_). Como sus señales se emiten desde otros scripts, cada una lleva `@warning_ignore("unused_signal")` (el aviso está como error).
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
- Campos actuales: `seed_code` (semilla como la ve el jugador, normalizada), `world_rng` (desde la Fase 3), `character`, `stats`, `hp`, `coins`, `keys` (saldo), `altitude` (máxima alcanzada), `threat_distance` (desde la Fase 4), `layer_index` y `path` (ramas elegidas, `K/1/L`; desde la Fase 5, con `choose_branch()` y `get_choices(capa)`) y `counters` (`jumps`, `coins_collected`, `keys_collected` y, desde la Fase 6, `enemies_killed`, `kills_by_enemy` y `death_cause`).
- Señales: `hp_changed(value, max_value)`, `coins_changed`, `keys_changed`, `altitude_changed`, `threat_distance_changed`, `branch_chosen` y `died`. `take_damage(amount, reducible = true, source_id = &"")` aplica el apantallamiento (`daño × (1 − defense)`) salvo con `reducible = false` (la Decoherencia), emite `died` una sola vez y guarda `source_id` como causa de la muerte; `register_kill(enemy_id)` cuenta un enemigo eliminado; si baja la coherencia máxima, la coherencia se recorta.
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
- Implantados en la Fase 3 (`core/rng/`). Nada del mundo usa el generador global (`randi()`, `seed()`).
- `LayerGenerator` (Fase 5): produce el `LayerPlan` de una capa (camino principal y ramas de cada bifurcación, con sus recompensas) a partir de `LayerData` y `ChunkLibrary`; `SlotFiller` decide qué rellena cada hueco. Son funciones puras del `WorldRng`.
- `Chunk` (script `@tool` de todos los tramos): expone marcadores, huecos y metadatos (`ChunkData`) y se valida en el editor con `ChunkValidator`. `Level.build_chunk()` le aplica su colocación antes de entrar en el árbol (llamar hacia abajo): espejo, partes opcionales, huecos y salidas de bifurcación o recompensa.
- Detalle del formato de los tramos y del algoritmo en [05-mundo](05-world.md#implementación-fase-5).
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

Configuradas en `project.godot` desde la Fase 2 y disponibles en código como `PhysicsLayers.WORLD`, `PhysicsLayers.HAZARDS`… Hoy: en el TileSet, la retícula y los niveles de energía colisionan en `world` y los niveles virtuales (atravesables desde abajo) en `one_way_platforms`; el bloqueador de una salida de bifurcación colapsada en `world`; el jugador (cuerpo y `Hurtbox`) en `player` con máscara `world` + `one_way_platforms`; recogibles y cofres en `pickups` y pinchos en `hazards`, ambos con máscara `player`. Los enemigos: el cuerpo en ninguna capa (máscara `world` + `one_way_platforms`), el `Hurtbox` en `enemies` y el `Hitbox` de contacto con máscara `player`. Los proyectiles del jugador en `player_projectiles` con máscara `enemies`, y los de los enemigos en `enemy_projectiles` con máscara `player`; las paredes las detectan con un rayo contra `world`. Los cuerpos estáticos no llevan máscara.

Implementado en la Fase 6:

| Pieza | Qué hace |
| --- | --- |
| `DamageInfo` (`combat/`) | Un golpe: cantidad, `kind` (`CONTACT`, `PROJECTILE`, `HAZARD`, `STATUS`, `THREAT`), `source_id` (la causa de la muerte: id del enemigo, `spike`, `rising_threat`), posición de la fuente, retroceso, si lo reduce el apantallamiento, si ignora la invulnerabilidad y los estados que aplica |
| `HealthComponent` (`actors/components/`) | Vida de todo lo que se destruye salvo el jugador (su coherencia es la del `RunState`): `take_hit(info)`, invulnerabilidad opcional, señales `hp_changed`, `damaged` y `died` (una vez) |
| `Hurtbox` | `Area2D` en la capa de su dueño que no detecta nada: `receive(info)` pasa el golpe a su `health` o a su `handler` (el jugador: `Player.take_hit`) y emite `hit_received` si se acepta |
| `Hitbox` | `Area2D` cuya máscara son las capas de sus objetivos. `continuous` sigue golpeando mientras dura el contacto (la invulnerabilidad del objetivo marca el ritmo: pinchos y contacto con enemigos); si no, golpea una vez a cada `Hurtbox`, hasta `max_hits`. Emite `hit_landed` |
| `StatusEffectData` + `StatusEffects` | Estados alterados (`data/statuses/`): duración, acumulaciones, daño por tic (golpes `STATUS` que ignoran la invulnerabilidad), multiplicador de velocidad e inmovilización. Hoy existen Inestable (`status_decay`: 1 de daño por acumulación cada 0,5 s durante 4 s, hasta 5), Dilatado (`status_slow`: ×0,5 durante 3 s) y Confinado (`status_root`: 1,5 s); Cargado y Entrelazado se apoyarán en ellos. El enemigo toma el tinte de la familia del estado activo |
| `ProjectileSpec` | Equipo, daño, velocidad, alcance, tamaño, perforación, retroceso, causa y estados de un disparo |
| `Shooter` | Dispara en 4 direcciones con las estadísticas (`attack_rate`, `attack_range`, `attack_power`), crea el `ProjectileSpec` y lanza el `Projectile` en `projectile_parent` (el nivel) heredando parte de la velocidad del tirador |
| `Projectile` (`combat/projectile.tscn`) | Un `Hitbox` de un solo golpe por objetivo que vuela recto; se detiene con un `ImpactEffect` en paredes, al gastar sus golpes o al agotar su alcance |
| `ImpactEffect` (`combat/effects/`) | Traza de cámara de burbujas dibujada en el motor: destello, anillo y dos espirales de cargas opuestas. Impactos de proyectil y muertes de enemigo |
| `HitStop` | _Hitstop_: baja `Engine.time_scale` a 0,05 durante 30 ms al dar a un enemigo, 50 ms al matarlo y 60 ms al recibir daño (los solapados se alargan, no se suman) y lo restaura siempre al salir del árbol. El `Level` lo dispara con `Events.enemy_damaged`, `Events.enemy_killed` y `Player.hurt` |
| `Enemy`, `EnemyData`, `EnemyBehavior` | Ver [09-enemigos](09-enemies.md#implementación-de-la-capa-k-fase-6) |

- Los pinchos (`Spike`) son un `Hitbox` continuo; la Decoherencia sigue siendo un `Area2D` propio porque su daño no es un golpe normal (ignora apantallamiento e invulnerabilidad y recoloca a Wilas).
- Rendimiento: con 40 enemigos y disparo continuo en la sala de combate, el coste de scripts y física sube unos 1,6 ms por fotograma (_headless_). El perfilado en hardware modesto, con el render, es de la Fase 15.

## Jugador

- Máquina de estados sencilla (`idle`, `run`, `jump`, `fall`, `dash`, `hurt`, `dead`) con estados como nodos o como enum más funciones; se evita la lógica en un único `_physics_process` gigante.
- Parámetros de movimiento (coyote, buffer, gravedad…) en un recurso `MovementConfig` exportado.

Implementado en la Fase 4 (`actors/player/`):

- `Player` (`CharacterBody2D`, colisión de 30×38 px con los pies 20 px bajo el origen; el núcleo de Wilas mide 40 px): enum `State` y una función por tarea (`_process_control`, `_try_jump`, `_start_dash`, `_knock_back`…). `_physics_process` solo lee el input y llama a `physics_step(delta, input)`, que también usan los tests y las herramientas de depuración para simular fotogramas sin teclado. Señales: `state_changed(from, to)`, `jumped(in_air)`, `landed`, `dashed`, `hurt` y `respawned`.
- `PlayerInput`: foto de los controles de un fotograma (`move_axis`, `down_held`, `jump_pressed`, `jump_held`, `dash_pressed`); `from_actions()` la lee de las acciones de input.
- `MovementConfig` (Resource, `data/movement/wilas_movement.tres`): tiempos de aceleración y frenado (suelo y aire), gravedad de subida y multiplicador de caída, velocidad terminal, recorte del salto, ratio del salto aéreo, _coyote_, _buffer_, tiempo de atravesar plataformas, Túnel (velocidad, duración, recarga y Túneles aéreos) y retroceso. Valores en [04-jugador](04-player.md#movimiento).
- Bajar de una plataforma atravesable quita del `collision_mask` la capa `one_way_platforms` durante `drop_through_time` y hasta que el jugador ya no la toca (consulta de forma con `intersect_shape`).
- Daño: su `Hurtbox` llama a `take_hit(DamageInfo)` (respeta la invulnerabilidad, retroceso alejándose de la fuente, guarda la causa); `take_damage(amount, source_position)` es un atajo con un golpe sin causa conocida, y `take_unavoidable_damage(amount, source_id)` es la Decoherencia: sin apantallamiento ni invulnerabilidad, con `RunState.take_damage(amount, false, source_id)`.
- Disparo (Fase 6): un `Shooter` hijo; `PlayerInput.shoot_direction` y `_try_shoot()` en el control normal (no en el Túnel ni en el retroceso), con el retroceso hacia abajo de `MovementConfig.shoot_down_recoil`. Señal `shot(direction)`. Está en el grupo `player` (`Player.GROUP`), que usan los enemigos para encontrarlo. `respawn_at(spot)` recoloca al jugador parado e invulnerable. `safe_spots` guarda los últimos puntos de suelo pisados.
- `PlayerVisual` (nodo `Visual`): dibuja a Wilas con sus piezas generadas y lo anima en el motor (órbita del electrón, respiración, parpadeos, expresiones por estado, _squash & stretch_, pulso del salto cuántico, estela del Túnel, destello al recibir daño). El `Player` la llama hacia abajo; nunca afecta a la jugabilidad. Su aleatoriedad (parpadeos) es cosmética y usa su propio `RandomNumberGenerator`.
- `PlayerCamera` (`Camera2D`): sigue a un `target` con suavizado exponencial, sesgo hacia arriba, _look-ahead_ vertical según la velocidad y límites laterales e inferior (`area_left`, `area_right`, `area_bottom`).

## La Decoherencia y el nivel

- `RisingThreat` (`world/rising_threat/`): su `y` es el frente. Velocidad base, goma elástica, frenado cerca del jugador y `paused`; un `Area2D` en la capa `rising_threat` detecta al jugador y `hit()` aplica el daño y busca dónde reaparecer (`find_respawn_spot`: último punto seguro válido o, si no, rayos hacia abajo por columnas). Se dibuja con `decoherence.gdshader`. Valores en [03-partida](03-run.md#la-decoherencia-amenaza-ascendente).
- `Level` reparte el trabajo: genera la capa (`layers`, hoy solo `layer_k.tres`) y su columna de tramos (a cada tramo le pasa el índice de capa, que escala a los enemigos), recibe los proyectiles en su nodo `Projectiles`, hace el _hitstop_ (`HitStop`), coloca a Wilas en el marcador `spawn` de la entrada de capa y la Decoherencia bajo el primer tramo con la velocidad base de la capa, la pausa mientras el jugador está en un tramo seguro (`ChunkData.is_safe()`: entrada de capa, descanso, tienda y jefe), instancia los tramos desde uno por debajo del jugador hasta dos por encima y libera los que quedan por debajo de la Decoherencia y de la vista. Al cruzar una salida de bifurcación apunta la rama en el `RunState` y alarga la columna. Al salir por arriba del último tramo de la capa termina la partida como completada (`SceneRouter` pasa `completed` a la pantalla final). Cada fotograma de física actualiza en el `RunState` la altura máxima (`altitude`, 11 pm por pantalla) y la distancia a la Decoherencia (`threat_distance`), ambas en pm.

## Guardado

- `SaveSystem` serializa `MetaProgress` a JSON con `schema_version`; aplica migraciones al cargar.
- Nunca se guardan referencias a rutas `res://` frágiles: se guardan **ids** de objeto.

## Calidad

- **Tests** con gdUnit4 (v6.2.1, incluido en `addons/gdUnit4/`), ejecutables en modo _headless_: semillas doradas, monotonía, estadísticas, economía y guardado. Viven en `tests/` como `*_test.gd`. `tests/smoke_test.gd` comprueba que la escena principal carga y que todos los scripts del proyecto compilan con los avisos como error.
- **CI** (GitHub Actions, `.github/workflows/ci.yml`): `gdformat --check`, `gdlint` y los tests con Godot 4.7.2 _headless_ en cada PR y en cada push a `main`; el informe de gdUnit4 se sube como artefacto. Las builds de exportación (Windows y Linux) en cada release de release-please llegan en la Fase 15.
- **Releases** con release-please (`.github/workflows/release-please.yml`, action v5) en cada push a `main`: abre o actualiza la PR de release con la versión y el `CHANGELOG.md`. Configuración en `release-please-config.json` (tipo `simple`, `bump-minor-pre-major` para que un cambio incompatible no salte a la 1.0 antes de tiempo) y versión actual en `.release-please-manifest.json`. Usa el `GITHUB_TOKEN` del workflow, así que no hay token personal que caduque; a cambio, la CI no se dispara sola en las PR de release (solo tocan versión y CHANGELOG).
- **Exportación**: `export_presets.cfg` con los presets `Windows Desktop` y `Linux` (x86_64, PCK embebido), que excluyen `tests/` y `addons/gdUnit4/`. Salida en `export/` (ignorado por git).
- **Escenas de depuración**: sala de pruebas de movimiento (`world/debug/movement_test_room.tscn`, Fase 4), sala de un tramo (`world/debug/chunk_test_room.tscn`, Fase 5) y sala de combate (`world/debug/combat_test_room.tscn`, Fase 6, ver [09-enemigos](09-enemies.md#sala-de-pruebas-de-combate)); arena de jefe y galería de objetos llegarán con sus fases.
- **Consola o menú de depuración** (solo en builds de desarrollo): dar objetos, saltar de capa, invulnerabilidad y mostrar huecos y direcciones de las tiradas.
