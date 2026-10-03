# 05 · Mundo: capas, tramos y generación

## Capas (biomas)

Cada capa tiene identidad visual y musical propia, sus enemigos, sus peligros y su jefe. Los enemigos y jefes se detallan en [09-enemigos](09-enemies.md).

| Capa    | Código      | Orbitales | Identidad                                                               | Peligros nuevos                                                                 | Jefe                         |
| ------- | ----------- | --------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ---------------------------- |
| **K**   | `layer_k`   | 1s        | Estable, luminosa, cercana al núcleo. Capa de aprendizaje.              | Picos de potencial                                                              | Par de Pauli                 |
| **L**   | `layer_l`   | 2s 2p     | Lóbulos en forma de haltera; plataformas que giran lentamente.          | Plataformas orbitales móviles, lluvia de muones                                 | Orbital p                    |
| **M**   | `layer_m`   | 3s 3p 3d  | Campos magnéticos, geometría compleja.                                  | Campos magnéticos (desvían al jugador y los proyectiles), barreras de potencial | Cascada de Auger             |
| **N**   | `layer_n`   | 4s … 4f   | Caótica, partículas virtuales que aparecen y desaparecen.               | Plataformas virtuales (existen a intervalos), todo lo anterior combinado        | Barrera de Coulomb           |
| O, P, Q | `layer_o…q` | —         | Solo en el Modo Plasma: remezclas de las anteriores con más dificultad. | —                                                                               | Jefes anteriores potenciados |

## Tramos (chunks)

Un **tramo** es una escena diseñada a mano de **una pantalla de alto** (el viewport de referencia es 1280×720; ver [13-dirección de arte](13-art-style.md)). Los tramos se apilan verticalmente para formar la capa. Miden **40 × 22 tiles de 32 px (1280 × 704 px)**, con 3 columnas de pared a cada lado (interior de 1088 px); los jefes pueden ser más altos (`height_tiles`).

### Reglas de diseño de un tramo

1. **Entrada y salida:** cada tramo declara por dónde se entra (abajo) y por dónde se sale (arriba) mediante marcadores (`Marker2D` llamados `entry_*` y `exit_*`), con su posición horizontal. La posición cae en una de las tres **aberturas** (tercios del interior: izquierda, centro y derecha) y el generador solo encadena tramos cuya salida y entrada comparten alguna abertura. Alrededor de cada marcador quedan libres de tiles sólidos 4 columnas en las 2 filas del borde (las plataformas atravesables sí se permiten).
2. **Alcanzabilidad:** toda salida debe poder alcanzarse con las **estadísticas base** (2 saltos, impulso 450). Nunca se exige una mejora para avanzar.
3. **Paredes laterales** continuas, salvo aberturas decorativas o secretas.
4. **Huecos de aparición (spawn slots):** marcadores (`Marker2D` en `Slots/`) llamados `<tipo>_<n>` (`slot_pickup_3`); el nombre forma parte de la dirección de sus tiradas:

| Tipo de hueco    | Código              | Qué puede aparecer                            |
| ---------------- | ------------------- | --------------------------------------------- |
| Recogible        | `slot_pickup`       | Fotones, cuantos de energía, positrones       |
| Contenedor       | `slot_container`    | Pozo cuántico, electrón ligado, superposición |
| Enemigo de suelo | `slot_enemy_ground` | Enemigos que patrullan plataformas            |
| Enemigo aéreo    | `slot_enemy_air`    | Enemigos voladores u orbitales                |
| Peligro          | `slot_hazard`       | Picos, campos…                                |
| Secreto          | `slot_secret`       | Pared atravesable hacia un tramo secreto      |

5. **Metadatos** (`ChunkData`): id estable, tipo de tramo, dificultad (1–5), peso de aparición, si se puede reflejar en espejo y alto. Las capas en las que aparece son las `LayerData` que lo incluyen, y sus entradas, salidas, huecos y partes opcionales se leen de sus marcadores y nodos.
6. Las plataformas y paredes se dibujan con **TileMapLayer**; la colisión va en el tileset. Nada de sprites sueltos con rectángulos de colisión a mano.
7. **Bifurcaciones:** techo cerrado (fila 0) salvo en sus dos salidas, que miden 4 tiles.

### Tipos de tramo

| Tipo               | Código              | Descripción                                                  |
| ------------------ | ------------------- | ------------------------------------------------------------ |
| Normal             | `chunk_normal`      | Plataformeo y enemigos                                       |
| Entrada de capa    | `chunk_layer_start` | Seguro; presenta el bioma                                    |
| Bifurcación        | `chunk_fork`        | Dos salidas con icono de recompensa                          |
| Recompensa         | `chunk_reward`      | Final de rama; contiene la recompensa elegida                |
| Intercambio        | `chunk_shop`        | Tienda; seguro                                               |
| Estado fundamental | `chunk_rest`        | Elegir entre curar o +coherencia máxima; seguro              |
| Excitado           | `chunk_challenge`   | Reto con doble recompensa                                    |
| Secreto            | `chunk_secret`      | Accesible con el Túnel desde un hueco secreto; objetos raros |
| Jefe               | `chunk_boss`        | Arena de jefe                                                |

### Variación procedural sobre tramos fijos

Para que 15 tramos por capa no se sientan repetitivos:

- **Espejo horizontal** (si el tramo lo permite).
- **Plataformas opcionales:** capas de tiles (`Tiles/Optional/*`) que aparecen según la semilla. Solo pueden llevar plataformas atravesables, así que nunca bloquean el camino (lo comprueba el validador).
- **Huecos de aparición** que se rellenan o se dejan vacíos según la semilla y las probabilidades.
- **Variantes de enemigo:** el hueco define la categoría y la semilla elige el tipo concreto dentro del pool de la capa.

## Generación de una capa

1. Se lee la plantilla de la capa (`LayerData`): longitud, posiciones de bifurcaciones, tienda y descanso, y curva de dificultad.
2. Para cada posición se elige un tramo del pool que cumpla: capa, tipo, dificultad acorde a la posición y compatibilidad de entrada con la salida anterior.
3. Evitar repetición: un tramo no se repite dentro de una misma capa si hay alternativas.
4. En cada bifurcación se generan dos **ramas**. Cada rama tiene su identificador (`K/3/L`, `K/3/R`…), así que elegir la misma rama con la misma semilla produce siempre el mismo resultado.
5. Los huecos de cada tramo se rellenan **al instanciarlo** con tiradas deterministas (ver [08-semillas](08-seeds.md)).

La generación es **perezosa**: se instancian solo los tramos cercanos (el actual, dos por encima y uno por debajo), y los que quedan por debajo de la Decoherencia se liberan. La _secuencia_ completa de la capa sí se calcula al entrar, porque es barata y facilita depurar.

## Herramientas de autoría

- **Plantilla** `world/chunks/chunk_template.tscn`: se duplica (no se hereda) y se le da un `id` en su `ChunkData`. Estructura de un tramo:

```
Chunk (chunk.gd, data: ChunkData)
├── Tiles (escala 0,5: el tileset usa texturas de 64 px)
│   ├── Walls        TileMapLayer: retícula (paredes)
│   ├── Platforms    TileMapLayer: niveles de energía y virtuales
│   └── Optional/    una TileMapLayer por parte opcional (solo atravesables)
├── Markers/         entry_*, exit_*, spawn (entrada de capa), reward (recompensa)
├── Slots/           huecos de aparición: slot_pickup_1, slot_hazard_1…
└── Props/           objetos fijos (se reflejan con el tramo)
```

- **Tileset** de la Capa K: `world/tilesets/layer_k_tileset.tres` sobre el atlas generado (ver [13-dirección de arte](13-art-style.md#tiles-y-peligros)). Terrenos _match sides_ para pintar las paredes (`wall`, borde solo hacia el hueco) y los niveles de energía (`energy_level`, con sus extremos redondeados); el nivel virtual es un tile suelto.
- **Validador** (`ChunkValidator`, `@tool`): el tramo muestra sus problemas como avisos de configuración en el editor (se refrescan al guardar o con el botón _Validate chunk_ del inspector). Comprueba el `ChunkData` y su id, los marcadores obligatorios en su borde y entre las paredes, que los tiles no se salen del tramo, que las paredes laterales son continuas, que las aberturas de entrada y salida están libres, el techo de las bifurcaciones, que los huecos tienen un tipo conocido, no se solapan ni están dentro de un tile sólido (y que los de enemigo de suelo están sobre la superficie de una plataforma), y que las partes opcionales solo usan plataformas atravesables y no pisan los tiles obligatorios. Los tests exigen que todos los tramos de la capa lo pasen.
- **Sala de un tramo** (`world/debug/chunk_test_room.tscn`, F6): carga un tramo (`chunk_scene`, o `-- --chunk=res://…` en la línea de comandos) construido igual que en la partida, sobre un suelo para empezar en su entrada. **R** vuelve al inicio, **M** lo refleja, **N** cambia de semilla (otros huecos y partes opcionales) y **Re Pág / Av Pág** pasan al tramo anterior o siguiente de la capa.

## Implementación (Fase 5)

| Pieza | Qué hace |
| --- | --- |
| `Chunk` (`world/chunks/chunk.gd`, `@tool`) | Script de todos los tramos: lee sus capas, marcadores y huecos; `apply_mirror()` (refleja celdas con `TRANSFORM_FLIP_H`, marcadores, huecos y _props_), `set_optional_parts()`, `fill_slots()`, `spawn_reward()` y `setup_fork()`. Emite `branch_chosen(side)`. Desde la Fase 6, `fill_slots(plan, clave, rng, índice_capa)` da a cada enemigo la dirección de su hueco y `add_enemy()` lo conecta para soltar sus caídas y su producto de decaimiento al morir. Solo se valida cuando es la raíz de su escena (un `Chunk` dentro de otra escena, como la arena de la sala de combate, no) |
| `ChunkData` | Metadatos (ver arriba). Los tipos seguros (entrada de capa, tienda, descanso, jefe) detienen la Decoherencia |
| `ForkGate` (`fork_gate.tscn`) | Salida de una bifurcación: línea discontinua del acento de la capa, icono de la recompensa flotando y un _trigger_ justo por encima del techo. Al cruzar una, la otra **colapsa** en 250 ms: la pared se cierra desde los lados, el icono se encoge y suelta fragmentos y un bloqueador cierra el paso |
| `ChunkLibrary` / `ChunkInfo` | Instancia cada escena una vez y guarda lo que el generador necesita (aberturas, huecos, partes opcionales); busca por capa, tipo y dificultad |
| `LayerData` (`data/layers/layer_k.tres`) | Plantilla de la capa: tramos, secuencia de tipos, longitud de las ramas, rango de dificultad, recompensas de bifurcación, probabilidad de partes opcionales y de cada tipo de hueco, objetos de cada hueco y velocidad base de la Decoherencia |
| `LayerGenerator` → `LayerPlan` | Calcula la secuencia entera al entrar en la capa: el camino principal y las dos ramas de cada bifurcación con su recompensa. `LayerPlan.column(elecciones)` da la columna que se sube, hasta la primera bifurcación sin elegir |
| `SlotFiller` | Qué aparece en cada hueco (presencia monótona y objeto ponderado) |
| `Level` | Construye la columna, instancia los tramos cercanos (el actual, dos por encima y uno por debajo) y libera los que quedan bajo la Decoherencia y la vista. Al elegir rama la apunta en `RunState.path` (`K/1/L`) y alarga la columna; los tramos que aparecen en pantalla se funden en 0,25 s |

**Elección de cada tramo.** Para cada posición se tira primero si va reflejado (solo se aplica si el tramo lo permite) y luego, entre los tramos de su tipo: los que encajan con la salida anterior (y, al final de una rama, con la entrada del siguiente tramo principal, porque le sigue sea cual sea la rama elegida), con dificultad a ±1 de la de la posición, distintos del anterior y usados el menor número de veces en la capa; de ellos, uno por peso (`pick_weighted`). Si nada encaja se relajan las condiciones (con aviso; los tests comprueban que con la biblioteca actual no pasa). Tras una bifurcación, el tramo principal no tiene que encajar con ella: lo que le precede es el final de una rama.

**Capa K hoy:** `entrada · 2 normales · bifurcación · 3 normales · bifurcación · 2 normales · descanso · 2 normales · jefe`, ramas de 1–2 tramos normales más el de recompensa y dificultad de 1 a 3. La biblioteca tiene 8 tramos normales (dos son la conversión de `platform_1` y `platform_2` del prototipo y la entrada de capa sustituye a `initial`), una bifurcación, dos de recompensa, uno de descanso y un **jefe provisional** (`k_boss_placeholder`, seguro, con techo cerrado y una salida central). Al salir por arriba del último tramo la partida termina como **capa completada**, hasta que lleguen el Par de Pauli y las demás capas. Recompensas de rama disponibles: fotones (`reward_coins`, un anillo de 8) y positrón (`reward_key`); el resto llegan con sus sistemas. El descanso de momento solo es seguro (la elección de la Fase 7 aún no existe). Los huecos rellenan fotones o positrones (40 %), picos de potencial (50 %) y, desde la Fase 6, enemigos: los de suelo (55 %) con un neutrón libre o una partícula alfa y los aéreos (50 %) con un electrón orbital ([09-enemigos](09-enemies.md#implementación-de-la-capa-k-fase-6)). Los 8 tramos normales y la bifurcación tienen de 1 a 3 huecos de enemigo; la entrada de capa, el descanso, los de recompensa y el jefe no tienen. Los de contenedores se quedan vacíos hasta la Fase 7.
