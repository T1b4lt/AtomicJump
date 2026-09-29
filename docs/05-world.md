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

Un **tramo** es una escena diseñada a mano de **una pantalla de alto** (el viewport de referencia es 1280×720; ver [13-dirección de arte](13-art-style.md)). Los tramos se apilan verticalmente para formar la capa.

### Reglas de diseño de un tramo

1. **Entrada y salida:** cada tramo declara por dónde se entra (abajo) y por dónde se sale (arriba) mediante marcadores (`Marker2D` llamados `entry_*` y `exit_*`), con su posición horizontal. El generador solo encadena tramos cuyas salidas y entradas sean compatibles.
2. **Alcanzabilidad:** toda salida debe poder alcanzarse con las **estadísticas base** (2 saltos, impulso 450). Nunca se exige una mejora para avanzar.
3. **Paredes laterales** continuas, salvo aberturas decorativas o secretas.
4. **Huecos de aparición (spawn slots):** marcadores con un tipo:

| Tipo de hueco    | Código              | Qué puede aparecer                            |
| ---------------- | ------------------- | --------------------------------------------- |
| Recogible        | `slot_pickup`       | Fotones, cuantos de energía, positrones       |
| Contenedor       | `slot_container`    | Pozo cuántico, electrón ligado, superposición |
| Enemigo de suelo | `slot_enemy_ground` | Enemigos que patrullan plataformas            |
| Enemigo aéreo    | `slot_enemy_air`    | Enemigos voladores u orbitales                |
| Peligro          | `slot_hazard`       | Picos, campos…                                |
| Secreto          | `slot_secret`       | Pared atravesable hacia un tramo secreto      |

5. **Metadatos** (`ChunkData`): capa(s) en las que puede aparecer, dificultad (1–5), tipo de tramo, peso de aparición, si se puede reflejar en espejo y tipos de entrada y salida.
6. Las plataformas y paredes se dibujan con **TileMapLayer**; la colisión va en el tileset. Nada de sprites sueltos con rectángulos de colisión a mano.

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
- **Plataformas opcionales:** tiles o grupos marcados como opcionales que aparecen según la semilla, siempre que no rompan la alcanzabilidad (se validan en el editor).
- **Huecos de aparición** que se rellenan o se dejan vacíos según la semilla y las probabilidades.
- **Variantes de enemigo:** el hueco define la categoría y la semilla elige el tipo concreto dentro del pool de la capa.

## Generación de una capa

1. Se lee la plantilla de la capa (`LayerData`): longitud, posiciones de bifurcaciones, tienda y descanso, y curva de dificultad.
2. Para cada posición se elige un tramo del pool que cumpla: capa, tipo, dificultad acorde a la posición y compatibilidad de entrada con la salida anterior.
3. Evitar repetición: un tramo no se repite dentro de una misma capa si hay alternativas.
4. En cada bifurcación se generan dos **ramas**. Cada rama tiene su identificador (`K/3/L`, `K/3/R`…), así que elegir la misma rama con la misma semilla produce siempre el mismo resultado.
5. Los huecos de cada tramo se rellenan **al instanciarlo** con tiradas deterministas (ver [08-semillas](08-seeds.md)).

La generación es **perezosa**: se instancian solo los tramos cercanos (el actual, dos por encima y uno por debajo), y los que quedan por debajo de la Decoherencia se liberan. La _secuencia_ completa de la capa sí se calcula al entrar, porque es barata y facilita depurar.

## Herramientas de autoría (objetivo)

- Escena plantilla `chunk_template.tscn` con los TileMapLayers, los marcadores y el script base ya preparados.
- Script `@tool` que valida en el editor: marcadores obligatorios, salidas dentro de los límites y huecos no solapados.
- Escena de depuración para cargar un tramo suelto y jugarlo sin generar una partida entera.
