# 08 · Semillas y reproducibilidad

## Qué promete una semilla

> **Dos jugadores con la misma semilla y la misma versión del juego se encuentran el mismo mundo.**

"El mismo mundo" significa:

- la misma secuencia de tramos en cada capa y en cada rama de cada bifurcación,
- las mismas recompensas en cada bifurcación,
- las mismas tiradas en cada hueco de aparición (lo que aparece, y dónde),
- el mismo inventario base en cada tienda,
- los mismos tipos de enemigo en cada hueco.

Lo que **puede diferir** entre dos jugadores con la misma semilla:

- **Las mejoras permanentes, el personaje y la Entropía** modifican probabilidades y estadísticas _sobre_ ese mismo mundo (ver "Modificadores y monotonía").
- **Las decisiones del jugador:** qué rama elige, qué compra, qué abre.
- **El combate en tiempo real:** movimiento de enemigos reactivo al jugador, efectos aleatorios de combate (por ejemplo, la "Incertidumbre").

La semilla **no depende** de las mejoras. Es la regla de oro: las mejoras nunca cambian _qué_ hay en el mundo, solo la probabilidad de que un hueco se active o la calidad de lo que cae.

## Formato de la semilla

- **Código de 8 caracteres** en base32 Crockford (sin I, L, O ni U, para que no haya confusiones), mostrado como `K7QX-2MPA`.
- Al generarse aleatoriamente se usan 40 bits de entropía.
- El jugador puede escribir **cualquier texto** ("MIPERRO", "hola mundo"): se normaliza (mayúsculas, sin espacios) y se convierte a un entero de 64 bits con un hash estable. Así las semillas con nombre son posibles y divertidas de compartir.
- La tarjeta final muestra `semilla · versión de generación`, por ejemplo `K7QX-2MPA · g1`.

## Versión de generación

Cualquier cambio en el contenido (tramos nuevos, cambios en tablas de aparición, objetos nuevos en pools) puede alterar lo que produce una semilla. Por eso:

- Existe una constante `GENERATION_VERSION` que se incrementa cuando un cambio rompe la reproducibilidad.
- Se muestra junto a la semilla. Dos jugadores con distinta versión de generación no tienen garantía de igualdad.
- Los tests de "semillas doradas" (ver más abajo) avisan de cambios involuntarios.

## Arquitectura: tiradas por hash, no por secuencia

### El problema de un único generador secuencial

Con `seed(x)` y `randi()` en secuencia (como en el prototipo), **cualquier** llamada aleatoria extra (una partícula, un enemigo que elige dirección, un objeto que cae) desplaza todas las tiradas siguientes. El mundo cambiaría según lo que haga el jugador. Además, el `seed()` global es compartido por todo el motor.

### La solución: tiradas direccionadas

Cada decisión aleatoria del mundo tiene una **dirección** única y estable, y su resultado es una función pura:

```
roll(semilla, dominio, ...clave) -> float en [0, 1)
```

Ejemplos de dirección:

- `("layout", "K", "3/L", 2)`: qué tramo va en la posición 2 de la rama izquierda de la bifurcación 3 de la capa K.
- `("slot", "K", "3/L", 2, "slot_pickup_4")`: si el hueco 4 del tramo tiene algo.
- `("slot_kind", "K", "3/L", 2, "slot_pickup_4")`: qué es lo que hay.
- `("fork_reward", "K", 3, "L")`: la recompensa de esa rama.
- `("shop", "K", "3/L", 1)`: el inventario de esa tienda.
- `("loot", "chest", "K", "3/L", 2, "slot_container_1")`: lo que contiene ese pozo cuántico.

Consecuencias:

- El orden en que se hacen las tiradas **da igual**.
- Lo que haga el jugador **no desplaza** nada.
- Elegir la rama izquierda y luego repetir la partida eligiendo la derecha da el mundo de la derecha, siempre el mismo.

### Hash estable

- **No** se usa `hash()` de Godot para esto: su resultado no está garantizado entre versiones del motor ni entre plataformas.
- Se implementa un hash propio en GDScript con operaciones de enteros de 64 bits (por ejemplo, SplitMix64 aplicado sobre FNV-1a de los bytes UTF-8 de la dirección).
- Cuando hace falta una **secuencia** local (por ejemplo, elegir 3 interacciones de un pool sin repetir), se crea un `RandomNumberGenerator` con `seed = roll_int(dirección)`. PCG32 es estable, y el generador es local y desechable.

### Dominios

| Dominio       | Qué decide                                           | ¿Afectado por mejoras?                                                      |
| ------------- | ---------------------------------------------------- | --------------------------------------------------------------------------- |
| `layout`      | Secuencia de tramos, espejos, plataformas opcionales | **Nunca**                                                                   |
| `fork_reward` | Tipo de recompensa de cada rama                      | **Nunca** en el tipo base (algunas mejoras pueden _mejorar_ la rareza)      |
| `slot`        | Si un hueco se activa                                | Sí, de forma monótona                                                       |
| `slot_kind`   | Qué aparece en un hueco activo                       | Sí (calidad)                                                                |
| `enemy`       | Tipo de enemigo en cada hueco                        | Entropía                                                                    |
| `loot`        | Contenido de contenedores y recompensas              | Sí (rareza y pool desbloqueado)                                             |
| `shop`        | Inventario de la tienda                              | Sí (pool desbloqueado)                                                      |
| `combat`      | Críticos, efectos aleatorios en combate              | — (secuencia local, no garantizada)                                         |
| `ai`          | Decisiones de enemigos                               | — (por enemigo, `RandomNumberGenerator` sembrado con su dirección de hueco) |

## Modificadores y monotonía

Aquí está la clave de la decisión de diseño: _"si alguien tiene una mejora de +10 % de pozos cuánticos, con la misma semilla encuentra los mismos pozos que otro jugador **más** algunos extra; y cuando el otro consiga la mejora, encontrará esos mismos extra"_.

### Presencia (¿aparece algo en este hueco?)

```
r = roll(semilla, "slot", dirección_del_hueco)
aparece = r < p_base × multiplicador_jugador
```

Como `r` es fija para ese hueco, aumentar la probabilidad **solo añade** huecos activos, nunca quita ni mueve los que ya había. Es un **superconjunto** garantizado.

### Calidad (¿qué rareza?)

```
r = roll(semilla, "rarity", dirección)
umbrales acumulados según Amplitud: [común | raro | épico | legendario]
```

Más Amplitud desplaza los umbrales, así que la misma `r` cae en una rareza igual o mejor. La calidad **solo mejora**.

### Elección dentro de un pool

Elegir _qué_ objeto concreto aparece depende del pool desbloqueado. Para minimizar cambios:

- El pool se ordena por identificador estable (no por orden de carga).
- La selección usa _rendezvous hashing_: cada objeto candidato recibe una puntuación `roll(dirección, id_objeto) ^ (1/peso)` y gana la mayor. Añadir un objeto nuevo al pool solo cambia la elección en los huecos donde el nuevo gana; el resto sigue igual.
- Consecuencia aceptada: dos jugadores con distinto pool desbloqueado pueden ver objetos distintos en algunos contenedores. Es coherente con la filosofía "la progresión forma parte de tu resultado".

## Tests de reproducibilidad

- **Semillas doradas:** para 5–10 semillas fijas se guarda en un fichero la secuencia de tramos, las recompensas de rama y el contenido de los huecos de la Capa K. Un test compara la generación actual con ese fichero. Si difiere y el cambio era intencionado, se incrementa `GENERATION_VERSION` y se regenera el fichero.
- **Test de monotonía:** con la misma semilla, subir la probabilidad de un tipo de hueco produce un superconjunto de huecos activos.
- **Test de independencia del orden:** generar los tramos en orden distinto da el mismo resultado.

## Implementación

Implantado en la Fase 3, en `core/rng/`:

### `SeedCode` (formato)

- `generate()`: 40 bits aleatorios codificados en 8 caracteres del alfabeto `0123456789ABCDEFGHJKMNPQRSTVWXYZ`, con guion en medio (`K7QX-2MPA`).
- `normalize(texto)`: mayúsculas, sin espacios en blanco ni guiones y como mucho 32 caracteres (`MAX_TEXT_LENGTH`). Si quedan 8 caracteres del alfabeto (o de sus alias de Crockford I y L → 1, O → 0) es un **código** y se sustituyen los alias. Un texto vacío no es una semilla válida.
- `from_text(texto)`: forma que ve el jugador; los códigos llevan el guion (`k7qx2mpa` → `K7QX-2MPA`) y el texto libre queda normalizado (`hola mundo` → `HOLAMUNDO`).
- `to_int(texto)`: `SeedHash.hash_string(normalize(texto))`. Códigos y texto libre se tratan igual: el entero es el hash del texto normalizado (el código aleatorio no se decodifica). Escribir la misma semilla con otras mayúsculas, espacios, guiones o alias da el mismo entero.

### `SeedHash` (hash estable)

- FNV-1a de 64 bits sobre los bytes UTF-8, seguido del finalizador de SplitMix64 (`mix`). Los enteros de GDScript son de 64 bits con signo y desbordan envolviendo, así que los hashes pueden ser negativos y las constantes sin signo se escriben con su valor con signo. El desplazamiento a la derecha sin signo se hace con `shift_right` (el `>>` de GDScript conserva el signo).
- Una dirección es una lista de partes (textos, `StringName` o enteros, **nunca** `float`) unidas con `|` (`hash_parts`).
- `tests/seed_hash_test.gd` comprueba valores conocidos calculados fuera de Godot.

### `WorldRng` (tiradas)

`RunState` crea uno por partida (`run.world_rng`) a partir del entero de la semilla. La clave es un `Array`:

| Método | Resultado |
| --- | --- |
| `roll_int(dominio, clave)` | Hash de 64 bits de la dirección: `mix(mix(semilla) ^ hash_parts([dominio] + clave))`. |
| `roll(dominio, clave)` | `float` en [0, 1) con los 53 bits altos del hash. |
| `roll_range(desde, hasta, dominio, clave)` | Entero en [desde, hasta]. |
| `chance(p, dominio, clave)` | `roll < p`: presencia monótona. |
| `pick_weighted({id: peso}, dominio, clave)` | _Rendezvous hashing_: gana el mayor `log(1 − roll(clave + [id])) / peso` (mismo orden que `roll^(1/peso)` sin problemas de precisión). Los pesos ≤ 0 nunca ganan; el empate se resuelve por id, y el orden del diccionario no importa. |
| `local_rng(dominio, clave)` | `RandomNumberGenerator` sembrado con `roll_int`. |
| `shuffled(lista, dominio, clave)` | Copia barajada (Fisher-Yates) con el `local_rng` de la dirección. `Array.shuffle()` usa el generador global y no se debe usar para generar. |

`WorldRng.GENERATION_VERSION` (hoy **2**: la Fase 5 cambió la generación entera) y `version_label()` (`g2`). `RunState.get_seed_label()` da `K7QX-2MPA · g2`.

### Generación de capas (Fase 5)

`LayerGenerator` y `SlotFiller` ([05-mundo](05-world.md#implementación-fase-5)) sustituyen al generador del prototipo. La clave de un tramo es `[capa, rama, índice]`: la rama es `main` para el camino principal o `<bifurcación>/<lado>` (`1/L`, `2/R`) para las ramas, con las bifurcaciones numeradas desde 1 y el índice contando desde 0 dentro de cada rama. Direcciones:

| Dirección | Qué decide |
| --- | --- |
| `("layout", "K", rama, i, "mirror")` | Si la posición va reflejada (`chance` 0,5; se tira antes de elegir el tramo) |
| `("layout", "K", rama, i)` | Qué tramo va en la posición (`pick_weighted` entre los candidatos válidos) |
| `("layout", "K", rama, "length")` | Cuántos tramos normales tiene una rama |
| `("layout", "K", rama, i, "optional", parte)` | Si aparece una parte opcional |
| `("fork_reward", "K", bifurcación, lado)` | La recompensa de cada rama; la derecha se elige sin la de la izquierda, así que nunca coinciden |
| `("slot", "K", rama, i, hueco)` | Si el hueco se rellena (`chance` con la probabilidad del tipo de hueco por un multiplicador: presencia monótona) |
| `("slot_kind", "K", rama, i, hueco)` | Qué lo rellena (`pick_weighted` entre los objetos de ese tipo de hueco) |

La secuencia se calcula en un orden fijo (camino principal y después las ramas de cada bifurcación, izquierda y luego derecha), porque "no repetir tramos" depende de lo que ya se ha usado; las tiradas de huecos y partes opcionales son independientes del orden. Los dominios provisionales del prototipo (`slot_order`, `slot_count`) ya no existen.

### Tests

- `tests/generation_test.gd`: semillas doradas, misma capa con la misma semilla, independencia de otras tiradas y del orden de los huecos, independencia del generador global, monotonía (subir la probabilidad de los huecos solo añade objetos, sin cambiar los que ya había; añadir un candidato a `pick_weighted` solo cambia los huecos que gana el nuevo) y, para 150 semillas, que el camino principal sigue la plantilla, que cada bifurcación tiene dos ramas de la longitud correcta acabadas en su tramo de recompensa y con recompensas distintas, que **todas** las columnas posibles encajan entrada con salida y no repiten tramo seguido, que la dificultad sigue la curva y que solo se reflejan los tramos que lo permiten.
- **Semillas doradas:** `tests/golden/generation_g<versión>.json` guarda, para 6 semillas fijas (`GoldenSeeds.SEEDS`), su entero, el camino principal y las ramas de la Capa K (una línea por tramo: id, `~m` si va reflejado, un carácter por hueco —`c` fotón, `k` positrón, `s` pico, `.` vacío— y las partes opcionales que aparecen) y las recompensas de cada rama. Si un cambio de generación es intencionado, se sube `GENERATION_VERSION` y se regenera ejecutando el test con la variable de entorno `UPDATE_GOLDEN_SEEDS=1` (`UPDATE_GOLDEN_SEEDS=1 addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode -a res://tests/generation_test.gd`). El cambio del fichero se revisa en la PR.

## Ideas a futuro

La **semilla diaria** (misma semilla para todos cada día, derivada de la fecha) encaja con este sistema sin necesidad de servidor. Está recogida en [99-ideas a futuro](99-future-ideas.md).
